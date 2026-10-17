#!/bin/sh
# SessionStart hook. Deletes long-output working copies under
# $XDG_CACHE_HOME/agents/output that nothing touched for DAYS days. Empty dirs
# go only once old too, so a task dir made just before its first write stays.
# Absolute find path: the user's shell aliases `find` to bfs.
set -u
DAYS="${DAYS:-7}"
FIND=/usr/bin/find
DIR="${XDG_CACHE_HOME:-$HOME/.cache}/agents/output"

[ -d "$DIR" ] || exit 0
"$FIND" "$DIR" -mindepth 1 -type f -mtime +"$DAYS" -delete
"$FIND" "$DIR" -mindepth 1 -type d -empty -mtime +"$DAYS" -delete
exit 0
