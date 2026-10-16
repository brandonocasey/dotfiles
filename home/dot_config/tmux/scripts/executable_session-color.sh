#!/bin/sh
# Gives each tmux session that has no @session_color the least-used color in
# the palette, so open sessions look distinct. A session keeps its color when
# renamed. tmux.conf runs this on session-created and on load; the status line
# colors the session name with it.
palette='#5FD700 #00AFFF #D787FF #FF8700 #5FD7D7 #FF5F87 #AFD75F #87AFFF'
used=$(tmux list-sessions -F '#{@session_color}' 2>/dev/null) || exit 0
tmux list-sessions -F '#{session_id} #{@session_color}' | while read -r id color; do
  [ -z "$color" ] || continue
  best=
  min=
  for c in $palette; do
    n=$(printf '%s\n' "$used" | grep -cFx -- "$c")
    if [ -z "$min" ] || [ "$n" -lt "$min" ]; then
      best=$c
      min=$n
    fi
  done
  tmux set-option -t "$id" @session_color "$best"
  used=$(printf '%s\n%s' "$used" "$best")
done
exit 0
