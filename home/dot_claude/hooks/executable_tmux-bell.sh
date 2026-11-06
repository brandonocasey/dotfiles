#!/bin/sh
# Marks this tmux pane's agent state for the status line (see tmux.conf).
# Usage: tmux-bell.sh [input|working|clear] [codex]
#   input    Stop and permission prompts; also rings the bell so tmux flags the window.
#            On Stop (hook JSON on stdin) it marks background instead while the
#            agent's background work runs, without the bell.
#   working  prompt submitted, or a tool starts or finishes
#   clear    agent exited
# Skips unattended runs (claude -p), codex started by Claude (it shares Claude's
# pane), and sessions outside tmux. Prints nothing: hook output costs tokens.
# Also sets @agent_kind, so tmux.conf's @agent_tool still knows the agent while
# another program (an editor, a ! command) holds the pane's terminal.
state=${1:-input}
kind=${2:-claude}
[ "${CLAUDE_CODE_SESSION_ATTENDED:-1}" = 0 ] && exit 0
[ "$kind" = codex ] && [ -n "${CLAUDECODE:-}" ] && exit 0
[ -n "$TMUX_PANE" ] || exit 0
tmux_command=$(sh "$HOME/.config/tmux/scripts/tmux-client.sh" 2>/dev/null) || exit 0

# Codex runs each command in a new session, without the pane's terminal; its MCP
# servers keep that terminal. Prints the PIDs of commands of Codex process $1
# still running (not zombies), apart from hooks and process $2.
codex_terminals() {
  pane_tty=$("$tmux_command" display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null) || return 0
  ps -A -o pid=,ppid=,stat=,tty=,args= 2>/dev/null |
    awk -v codex="$1" -v skip="${2:-}" -v tty="${pane_tty#/dev/}" \
      '$2 == codex && $1 != skip && $3 !~ /^Z/ && $4 != tty && $0 !~ /\.claude\/hooks\// { print $1 }'
}

ring() {
  tty=$("$tmux_command" display-message -p -t "$TMUX_PANE" '#{pane_tty}' 2>/dev/null) || return 0
  [ -w "$tty" ] && printf '\a' >"$tty"
}

# Codex starts no turn when its background terminals end, so a watcher started
# on Stop marks input once they are gone. It MUST stop when the pane leaves the
# background state or a later Stop starts a newer watcher.
if [ "$state" = watch-codex ]; then
  codex=$2 token=$3
  while sleep 3; do
    [ "$("$tmux_command" display-message -p -t "$TMUX_PANE" '#{@agent_state} #{@agent_watch}' 2>/dev/null)" = "background $token" ] || exit 0
    kill -0 "$codex" 2>/dev/null || exit 0
    [ -z "$(codex_terminals "$codex")" ] || continue
    "$tmux_command" set-option -p -t "$TMUX_PANE" @agent_state input 2>/dev/null
    ring
    exit 0
  done
  exit 0
fi

if [ "$state" = input ] && [ ! -t 0 ]; then
  background_tasks=$(jq -r 'select(.hook_event_name == "Stop") | (.background_tasks // []) | length' 2>/dev/null)
  if [ "${background_tasks:-0}" -gt 0 ] 2>/dev/null; then
    state=background
  elif [ -n "$background_tasks" ] && [ "$kind" = codex ]; then
    hook=$$
    parent=$PPID
    while [ "$parent" -gt 1 ] 2>/dev/null; do
      case $(ps -p "$parent" -o comm= 2>/dev/null) in
      codex | */codex) break ;;
      esac
      hook=$parent
      parent=$(ps -p "$parent" -o ppid= 2>/dev/null | tr -d ' ')
    done
    if [ "$parent" -gt 1 ] 2>/dev/null && [ -n "$(codex_terminals "$parent" "$hook")" ]; then
      state=background
      "$tmux_command" set-option -p -t "$TMUX_PANE" @agent_watch "$$" 2>/dev/null
      nohup sh "$0" watch-codex "$parent" "$$" </dev/null >/dev/null 2>&1 &
    fi
  fi
fi

case $state in
clear) "$tmux_command" set-option -p -u -t "$TMUX_PANE" @agent_state \; set-option -p -u -t "$TMUX_PANE" @agent_kind 2>/dev/null ;;
*) "$tmux_command" set-option -p -t "$TMUX_PANE" @agent_state "$state" \; set-option -p -t "$TMUX_PANE" @agent_kind "$kind" 2>/dev/null ;;
esac
[ "$state" = input ] && ring
exit 0
