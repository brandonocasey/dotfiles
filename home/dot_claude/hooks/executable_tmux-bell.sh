#!/bin/sh
# Marks this tmux pane's agent state for the status line (see tmux.conf).
# Usage: tmux-bell.sh [input|working|clear] [codex]
#   input    Stop and permission prompts; also rings the bell so tmux flags the window
#   working  prompt submitted or a tool finished
#   clear    agent exited
# Skips unattended runs (claude -p), codex started by Claude (it shares Claude's
# pane), and sessions outside tmux. Prints nothing: hook output costs tokens.
# Also sets @agent_kind, so tmux.conf's @agent_tool still knows the agent while
# another program (an editor, a ! command) holds the pane's terminal.
state=${1:-input}
[ "${CLAUDE_CODE_SESSION_ATTENDED:-1}" = 0 ] && exit 0
[ "${2:-}" = codex ] && [ -n "${CLAUDECODE:-}" ] && exit 0
[ -n "$TMUX_PANE" ] || exit 0
tmux_command=$(sh "$HOME/.config/tmux/scripts/tmux-client.sh" 2>/dev/null) || exit 0
case $state in
clear) "$tmux_command" set-option -p -u -t "$TMUX_PANE" @agent_state \; set-option -p -u -t "$TMUX_PANE" @agent_kind 2>/dev/null ;;
*) "$tmux_command" set-option -p -t "$TMUX_PANE" @agent_state "$state" \; set-option -p -t "$TMUX_PANE" @agent_kind "${2:-claude}" 2>/dev/null ;;
esac
if [ "$state" = input ]; then
  tty=$("$tmux_command" display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null) || exit 0
  [ -w "$tty" ] && printf '\a' >"$tty"
fi
exit 0
