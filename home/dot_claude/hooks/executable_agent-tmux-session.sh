#!/bin/sh
# Renames the tmux session that holds an agent to the agent's session title, in
# plain words (Fix stop-hook loop). Usage:
#   agent-tmux-session.sh claude|codex   SessionStart or Stop hook, JSON on stdin
#   agent-tmux-session.sh set <title>    from auto-title.sh, right after Haiku
#   agent-tmux-session.sh restore        SessionEnd hook, JSON on stdin
#   agent-tmux-session.sh sync <title>   from the Claude status line after /rename;
#                                        renames only when the title changed
#   agent-tmux-session.sh tidy <title>   print the cleaned title only
# The first rename saves the session's old name; restore puts it back when the
# agent exits, unless the user renamed the session since or another agent pane
# still uses it. /clear keeps the name. Over ssh it never restores.
# Inside tmux it renames directly. Over ssh from a local tmux (the remote TERM is
# tmux* or screen*), it sends a marked window-name escape to $SSH_TTY; the
# window-renamed hook in the local tmux.conf turns that into a session rename.
# The marker MUST match tmux.conf. Other terminals can print the escape as text,
# so they get nothing.
# It exits 0 on every path, so a missing tool or title never blocks the agent.

agent=${1:-}
marker='agent-session:'

# The title as plain words (case kept), at most 60 characters, cut at a word
# break, without a closing period. Claude shows this form.
tidy() {
  printf '%s' "$1" | LC_ALL=C tr -d '[:cntrl:]' |
    LC_ALL=C sed -e 's/[.!?]*[[:space:]]*$//' -e 's/[[:space:]][[:space:]]*/ /g' -e 's/^ //' -e 's/ $//' |
    awk '{ if (length($0) > 60) { s = substr($0, 1, 61); sub(/ [^ ]*$/, "", s); $0 = substr(s, 1, 60) } print }'
}

# The tmux form: tmux treats ':' and '#' specially in names and turns '.' into
# '_', so 8.51.14 becomes 8_51_14 here but stays exact in Claude.
safe() {
  tidy "$1" | LC_ALL=C sed -e 's/[:#]/ /g' -e 's/\./_/g' -e 's/  */ /g' -e 's/^ //' -e 's/ $//'
}

if [ "$agent" = tidy ]; then
  tidy "${2:-}"
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
  name=$(safe "$1")
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
    name="$base ($n)"
    n=$((n + 1))
  done
  [ "$name" = "$current" ] && return 0
  [ -n "$(tmux show-options -qv -t "$session" @agent_orig_name)" ] ||
    tmux set-option -t "$session" @agent_orig_name "$current"
  tmux rename-session -t "$session" "$name" 2>/dev/null &&
    tmux set-option -t "$session" @agent_name "$name"
  return 0
}

if [ "$agent" = set ]; then
  rename "${2:-}"
  exit 0
fi

# Compares with the last name set here, not the session name, so a session the
# user renamed in tmux keeps that name until the title changes again.
if [ "$agent" = sync ]; then
  [ "$target" = tmux ] || exit 0
  session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null) || exit 0
  [ "$(safe "${2:-}")" = "$(tmux show-options -qv -t "$session" @agent_name)" ] && exit 0
  rename "${2:-}"
  exit 0
fi

command -v jq >/dev/null 2>&1 || exit 0
hook_input=$(cat)

if [ "$agent" = restore ]; then
  [ "$target" = tmux ] || exit 0
  [ "$(printf '%s' "$hook_input" | jq -r '.reason // empty' 2>/dev/null)" = clear ] && exit 0
  session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null) || exit 0
  orig=$(tmux show-options -qv -t "$session" @agent_orig_name)
  [ -n "$orig" ] || exit 0
  others=$(tmux list-panes -s -t "$session" -F '#{pane_id} #{@agent_state}' |
    awk -v p="$TMUX_PANE" '$1 != p && $2 != ""')
  [ -z "$others" ] || exit 0
  current=$(tmux display-message -p -t "$session" '#{session_name}')
  set_name=$(tmux show-options -qv -t "$session" @agent_name)
  tmux set-option -u -t "$session" @agent_orig_name
  tmux set-option -u -t "$session" @agent_name
  [ "$current" = "$set_name" ] || exit 0
  tmux has-session -t "=$orig" 2>/dev/null && exit 0
  tmux rename-session -t "$session" "$orig" 2>/dev/null
  exit 0
fi

case $agent in
claude)
  transcript=$(printf '%s' "$hook_input" | jq -r '.transcript_path // empty' 2>/dev/null)
  [ -n "$transcript" ] || exit 0
  sid=$(printf '%s' "$hook_input" | jq -r '.session_id // empty' 2>/dev/null)
  haiku_file=${XDG_STATE_HOME:-$HOME/.local/state}/agents/auto-title/$sid.haiku
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

# Claude: /rename writes custom-title; it wins over auto-title.sh's Haiku title,
# which wins over Claude's own ai-title.
session_title() {
  if [ "$agent" = claude ]; then
    [ -r "$transcript" ] || return 0
    haiku=
    [ -n "$sid" ] && [ -s "$haiku_file" ] && haiku=$(cat "$haiku_file")
    jq -rn --arg haiku "$haiku" '
      reduce (inputs | select(.type == "custom-title" or .type == "ai-title")) as $e
        ({}; .[$e.type] = ($e.customTitle // $e.aiTitle)) |
      .["custom-title"] // (if $haiku != "" then $haiku else null end) // .["ai-title"] // empty
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
