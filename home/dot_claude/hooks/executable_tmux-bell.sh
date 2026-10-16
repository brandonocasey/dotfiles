#!/bin/sh
# Marks this tmux pane's agent state for the status line (see tmux.conf).
# Usage: tmux-bell.sh [input|working|clear] [codex]
#   input    Stop and permission prompts; also rings the bell so tmux flags the window
#   working  prompt submitted or a tool finished
#   clear    agent exited
# Skips unattended runs (claude -p), codex started by Claude (it shares Claude's
# pane), and sessions outside tmux. Prints nothing: hook output costs tokens.
state=${1:-input}
[ "${CLAUDE_CODE_SESSION_ATTENDED:-1}" = 0 ] && exit 0
[ "${2:-}" = codex ] && [ -n "${CLAUDECODE:-}" ] && exit 0
[ -n "$TMUX_PANE" ] || exit 0
case $state in
clear) tmux set-option -p -u -t "$TMUX_PANE" @agent_state 2>/dev/null ;;
*) tmux set-option -p -t "$TMUX_PANE" @agent_state "$state" 2>/dev/null ;;
esac
if [ "$state" = input ]; then
  tty=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null) || exit 0
  [ -w "$tty" ] && printf '\a' >"$tty"
fi
exit 0
