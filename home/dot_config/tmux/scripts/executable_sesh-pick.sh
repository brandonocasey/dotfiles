#!/bin/sh
# Opens the sesh picker (prefix + s or T in tmux.conf); tmux sessions show
# their agent state, from sesh-list.sh.
list=~/.config/tmux/scripts/sesh-list.sh
choice=$(sh "$list" list -t --icons | fzf-tmux -p 80%,70% \
  --no-sort --ansi --border-label ' sesh ' --prompt '🪟  ' \
  --header '  ^a all  ^t tmux  ^g configs  ^x zoxide  ^f find  ^d kill' \
  --bind 'tab:down,btab:up' \
  --bind "ctrl-a:change-prompt(⚡  )+reload(sh $list list --icons)" \
  --bind "ctrl-t:change-prompt(🪟  )+reload(sh $list list -t --icons)" \
  --bind "ctrl-g:change-prompt(⚙️  )+reload(sh $list list -c --icons)" \
  --bind "ctrl-x:change-prompt(📁  )+reload(sh $list list -z --icons)" \
  --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
  --bind "ctrl-d:execute(sh $list kill {})+change-prompt(🪟  )+reload(sh $list list -t --icons)" \
  | cut -f1)
sesh connect "$choice"
