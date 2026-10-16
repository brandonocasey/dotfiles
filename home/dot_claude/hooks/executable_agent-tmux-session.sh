#!/bin/sh
# Renames the tmux session that holds an agent to the agent's session title, as
# a filename-style slug (fix-stop-hook-loop). Usage:
#   agent-tmux-session.sh claude|codex   SessionStart or Stop hook, JSON on stdin
#   agent-tmux-session.sh set <title>    from auto-title.sh, right after Haiku
#   agent-tmux-session.sh slug <title>   print the slug only
# Inside tmux it renames directly. Over ssh from a local tmux (the remote TERM is
# tmux* or screen*), it sends a marked window-name escape to $SSH_TTY; the
# window-renamed hook in the local tmux.conf turns that into a session rename.
# The marker MUST match tmux.conf. Other terminals can print the escape as text,
# so they get nothing.
# It exits 0 on every path, so a missing tool or title never blocks the agent.

agent=${1:-}
marker='agent-session:'

# Lowercase words joined by '-', at most 40 characters, cut at a word break.
# It also keeps out the '.', ':', and '#' that tmux treats specially in names.
slug() {
  printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]' |
    LC_ALL=C sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-//' -e 's/-$//' |
    awk '{ if (length($0) > 40) { s = substr($0, 1, 41); sub(/-[^-]*$/, "", s); $0 = substr(s, 1, 40) } print }'
}

if [ "$agent" = slug ]; then
  slug "${2:-}"
  exit 0
fi

if [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  target=tmux
elif [ -n "${SSH_TTY:-}" ] && [ -w "$SSH_TTY" ]; then
  case ${TERM:-} in
  tmux* | screen*) target=ssh ;;
  *) exit 0 ;;
  esac
else
  exit 0
fi

rename() {
  name=$(slug "$1")
  [ -n "$name" ] || return 0
  if [ "$target" = ssh ]; then
    printf '\033k%s%s\033\134' "$marker" "$name" >"$SSH_TTY" 2>/dev/null
    return 0
  fi
  session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null) || return 0
  current=$(tmux display-message -p -t "$session" '#{session_name}' 2>/dev/null)
  # Another session may already use the name; rename-session would fail.
  base=$name
  n=2
  while [ "$name" != "$current" ] && tmux has-session -t "=$name" 2>/dev/null; do
    name=$base-$n
    n=$((n + 1))
  done
  [ "$name" = "$current" ] || tmux rename-session -t "$session" "$name" 2>/dev/null
  return 0
}

if [ "$agent" = set ]; then
  rename "${2:-}"
  exit 0
fi

command -v jq >/dev/null 2>&1 || exit 0
hook_input=$(cat)

case $agent in
claude)
  transcript=$(printf '%s' "$hook_input" | jq -r '.transcript_path // empty' 2>/dev/null)
  [ -n "$transcript" ] || exit 0
  ;;
codex)
  session_id=$(printf '%s' "$hook_input" | jq -r '.session_id // empty' 2>/dev/null)
  [ -n "$session_id" ] || exit 0
  index_file="${CODEX_HOME:-$HOME/.codex}/session_index.jsonl"
  ;;
*)
  echo "agent-tmux-session: unknown agent '$agent'; use claude, codex, or set" >&2
  exit 0
  ;;
esac

# Claude: /rename writes custom-title; it wins over the generated ai-title.
session_title() {
  if [ "$agent" = claude ]; then
    [ -r "$transcript" ] || return 0
    jq -rn '
      reduce (inputs | select(.type == "custom-title" or .type == "ai-title")) as $e
        ({}; .[$e.type] = ($e.customTitle // $e.aiTitle)) |
      .["custom-title"] // .["ai-title"] // empty
    ' "$transcript" 2>/dev/null
    return 0
  fi
  [ -r "$index_file" ] || return 0
  jq -sr --arg id "$session_id" '
    map(select(.id == $id)) |
    if length > 0 then .[-1].thread_name // empty else empty end
  ' "$index_file" 2>/dev/null
}

# The title entry can land just after the hook fires, so retry briefly.
attempt=0
while [ "$attempt" -lt 10 ]; do
  title=$(session_title)
  if [ -n "$title" ]; then
    rename "$title"
    exit 0
  fi
  attempt=$((attempt + 1))
  sleep 0.1
done
exit 0
