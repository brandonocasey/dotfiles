#!/bin/bash
# SessionStart hook. Removes agent scratch and copy files, and harness scratchpad
# sessions, that nothing touched for DAYS days. Backups under
# $XDG_STATE_HOME/agents/backups are never touched. Absolute find path: the
# user's shell aliases `find` to bfs, which rejects BSD find flags.
# Run by hand with DAYS=0 to clear everything, after closing other agent sessions.
set -u
DAYS="${DAYS:-30}"
FIND=/usr/bin/find
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/agents"

for dir in "$CACHE/scratch" "$CACHE/copy"; do
  [ -d "$dir" ] || continue
  "$FIND" "$dir" -mindepth 1 -type f -mtime +"$DAYS" -delete
  "$FIND" "$dir" -mindepth 1 -type d -empty -delete
done

# Harness layout: /tmp/claude-<uid>/<cwd-slug>/<session-id>/{scratchpad,tasks}.
# A session dir stays while any entry in it changed within DAYS.
ROOT="/tmp/claude-$(id -u)"
[ -d "$ROOT" ] || exit 0
for session in "$ROOT"/*/*/; do
  [ -d "$session" ] || continue
  if [ -z "$("$FIND" "$session" -mtime -"$DAYS" -print -quit)" ]; then
    rm -rf "$session"
  fi
done
"$FIND" "$ROOT" -mindepth 1 -maxdepth 1 -type d -empty -delete
[ -d "$ROOT/bash-edit-diff" ] && "$FIND" "$ROOT/bash-edit-diff" -mindepth 1 -maxdepth 1 -mtime +"$DAYS" -exec rm -rf {} +
exit 0
