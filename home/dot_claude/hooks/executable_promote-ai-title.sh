#!/bin/sh
# Stop hook. Copies the generated ai-title into a custom-title entry, once,
# so the session keeps a stable name. It skips any transcript that already
# has a custom-title: that covers a manual /rename and a previous run of this
# hook. Appends the same line format that /rename writes. Exits 0 on all paths.

command -v jq >/dev/null 2>&1 || exit 0

transcript=$(jq -r '.transcript_path // empty' 2>/dev/null)
[ -f "$transcript" ] || exit 0

grep -q '"type":"custom-title"' "$transcript" && exit 0

line=$(grep '"type":"ai-title"' "$transcript" | tail -n 1)
[ -n "$line" ] || exit 0

entry=$(printf '%s' "$line" | jq -c \
  '{type: "custom-title", customTitle: .aiTitle, sessionId: .sessionId}' 2>/dev/null)
[ -n "$entry" ] || exit 0
case $entry in *'"customTitle":null'* | *'"customTitle":""'*) exit 0 ;; esac

printf '%s\n' "$entry" >> "$transcript"
