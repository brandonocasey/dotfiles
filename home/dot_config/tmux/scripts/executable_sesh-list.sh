#!/bin/sh
# Feeds the sesh picker (prefix + T in tmux.conf). Adds each tmux session's
# agent state after its name, colored like the window list: a yellow ●
# when any pane waits for input, else a green ● when any pane works.
# It reads the state from the colors in tmux.conf's @agent_status; keep them in
# sync. The state follows a tab, so the picker passes only the part before it on.
# Usage: sesh-list.sh list [sesh list flags]
#        sesh-list.sh kill <picker line>
case ${1:-} in
kill)
  name=$(printf '%s\n' "$2" | cut -f1)
  name=${name#* }
  tmux kill-session -t "=$name"
  ;;
list)
  shift
  states=$(tmux list-panes -a -F '#{session_name}	#{E:@agent_status}' 2>/dev/null)
  sesh list "$@" | while IFS= read -r line; do
    name=$(printf '%s\n' "$line" | sed 's/\x1b\[[0-9;]*m//g')
    name=${name#* }
    mine=$(printf '%s\n' "$states" | awk -F '\t' -v n="$name" '$1 == n { print $2 }')
    case $mine in
    *D7AF00*) printf '%s\t\033[38;5;178m●\033[0m\n' "$line" ;;
    *5FD700*) printf '%s\t\033[38;5;76m●\033[0m\n' "$line" ;;
    *) printf '%s\n' "$line" ;;
    esac
  done
  ;;
*) exit 2 ;;
esac
