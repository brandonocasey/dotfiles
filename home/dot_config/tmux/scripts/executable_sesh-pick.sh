#!/bin/sh
# Opens the sesh picker (prefix + s or T in tmux.conf); tmux sessions show
# their agent state, from sesh-list.sh.
# fzf --tmux, not fzf-tmux -p: tmux starts the latter's popup through
# default-shell (fish), and loading its config delays the picker.
list=~/.config/tmux/scripts/sesh-list.sh
# The popup gets keys before tmux does, so fzf binds tmux.conf's prefix + C
# itself. ctrl-b turns C on until the search text changes.
new_session=:new-session
picked=$(sh "$list" list -t --icons | fzf --tmux center,80%,70% --print-query \
  --no-sort --ansi --border-label ' sesh ' --prompt '🪟  ' \
  --header '  ^a all  ^t tmux  ^g configs  ^x zoxide  ^f find  ^d kill' \
  --bind 'tab:down,btab:up' \
  --bind "ctrl-a:change-prompt(⚡  )+reload(sh $list list --icons)" \
  --bind "ctrl-t:change-prompt(🪟  )+reload(sh $list list -t --icons)" \
  --bind "ctrl-g:change-prompt(⚙️  )+reload(sh $list list -c --icons)" \
  --bind "ctrl-x:change-prompt(📁  )+reload(sh $list list -z --icons)" \
  --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
  --bind "ctrl-d:execute(sh $list kill {})+change-prompt(🪟  )+reload(sh $list list -t --icons)" \
  --bind 'start:unbind(C)' --bind 'change:unbind(C)' --bind 'ctrl-b:rebind(C)' \
  --bind "C:become(echo $new_session)")
# --print-query puts the search text on line 1 and the picked row on line 2.
# The C key prints $new_session as line 1 instead.
query=$(printf '%s\n' "$picked" | sed -n 1p)
if [ "$query" = "$new_session" ]; then
  session=$(tmux new-session -d -P -F '#{session_id}') || exit
  tmux switch-client -t "$session"
  exit
fi
choice=$(printf '%s\n' "$picked" | sed -n 2p | cut -f1)
sesh connect "$choice"
