#!/bin/sh
# SessionStart and Stop hook for Claude Code and Codex. Renames the tmux session
# that holds the agent to the agent's session title. Usage: claude | codex, with
# the hook JSON on stdin. POSIX sh so it runs on machines without fish.
# Inside tmux it renames the session directly. Over ssh from a local tmux (the
# remote TERM is tmux* or screen*), it sends a marked window-name escape to
# $SSH_TTY; the window-renamed hook in the local tmux.conf turns that into a
# session rename. The marker MUST match tmux.conf. Other terminals can print the
# escape as text, so they get nothing.
# It exits 0 on every path, so a missing tool or title never blocks the agent.

agent=${1:-}
marker='agent-session:'

command -v jq >/dev/null 2>&1 || exit 0

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
    echo "agent-tmux-session: unknown agent '$agent'; use claude or codex" >&2
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

rename() {
  if [ "$target" = tmux ]; then
    tmux_session_id=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null)
    # rename-session expands formats in the name, so a literal '#' MUST be '##'.
    tmux_title=$(printf '%s' "$1" | sed 's/#/##/g')
    [ -n "$tmux_session_id" ] && tmux rename-session -t "$tmux_session_id" "$tmux_title" 2>/dev/null
    return 0
  fi
  # Control characters would end the escape sequence early.
  safe_title=$(printf '%s' "$1" | tr -d '\000-\037\177')
  printf '\033k%s%s\033\134' "$marker" "$safe_title" >"$SSH_TTY" 2>/dev/null
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
