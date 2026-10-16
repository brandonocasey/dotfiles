#!/bin/sh
# UserPromptSubmit hook: shows Claude Code's own generated title above the
# prompt, like /rename, as a filename-style slug (tmux-hooks). Claude writes
# that title (an ai-title entry) only after the first prompt is sent, so the
# name appears from the second prompt on. It calls Haiku itself only after
# /clear, when Claude makes no title.
# Skips unattended runs (claude -p) and sessions the user named.
# SessionStart hook with `new` (startup or /clear): the next title replaces a
# name this hook set that /clear carried over.
[ "${CLAUDE_CODE_SESSION_ATTENDED:-1}" = 0 ] && exit 0
state=${XDG_STATE_HOME:-$HOME/.local/state}/agents/auto-title
mkdir -p "$state"
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0
old=$(printf '%s' "$input" | jq -r '.session_title // empty')
generated() { grep -Fxq -- "$old" "$state/titles" 2>/dev/null; }

if [ "$1" = new ]; then
  rm -f "$state/$sid"
  touch "$state/$sid.new"
  exit 0
fi
[ -f "$state/$sid" ] && exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -r "$transcript" ] || exit 0
ai=$(grep '"type":"ai-title"' "$transcript" | tail -n 1 | jq -r '.aiTitle // empty')
# Claude skips its own title when /clear carried a name over, so ask Haiku in
# the background and use its answer on the next prompt.
if [ -z "$ai" ] && [ -f "$state/$sid.new" ] && [ -n "$old" ] && generated; then
  if [ -s "$state/$sid.haiku" ]; then
    ai=$(cat "$state/$sid.haiku")
  elif [ ! -f "$state/$sid.haiku" ]; then
    prompt=$(printf '%s' "$input" | jq -r '.prompt // "" | .[:1000]')
    case $prompt in '' | /*) exit 0 ;; esac
    : >"$state/$sid.haiku"
    system='Write a 2-4 word title for the coding session that starts with the message inside <message> tags. Never answer the message; only title it. Name the most specific topic: ticket ID, file, tool, feature, or setting. Output the title only.'
    # No settings sources means no hooks, so this call cannot trigger itself.
    (cd "$state" && printf '<message>\n%s\n</message>\n' "$prompt" |
      CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 timeout 30 claude -p --model haiku \
        --system-prompt "$system" \
        --tools '' --setting-sources '' --strict-mcp-config --no-session-persistence \
        --max-turns 1 2>/dev/null | head -n 1 >"$state/$sid.haiku.tmp" &&
      mv "$state/$sid.haiku.tmp" "$state/$sid.haiku") </dev/null >/dev/null 2>&1 &
  fi
fi
# Not generated yet; try again on the next prompt.
[ -n "$ai" ] || exit 0

# Set by `claude -n`, /rename, or a resumed session's earlier name; keep it.
# Exception: /clear carries the old name over, so a new session replaces a name
# this hook set. Names the user chose are never in that list.
if [ -f "$state/$sid.new" ]; then
  [ -z "$old" ] || [ "$old" = "$ai" ] || generated || {
    touch "$state/$sid"
    exit 0
  }
elif [ -n "$old" ] && [ "$old" != "$ai" ]; then
  touch "$state/$sid"
  exit 0
fi

touch "$state/$sid"
rm -f "$state/$sid.new" "$state/$sid.haiku"
find "$state" -type f -mtime +30 -delete 2>/dev/null
tmux_hook=$(dirname "$0")/agent-tmux-session.sh
title=$(sh "$tmux_hook" slug "$ai")
[ -n "$title" ] || exit 0
sh "$tmux_hook" set "$title" </dev/null
# Remember set names so /clear can tell them from user-chosen names.
{ tail -n 499 "$state/titles" 2>/dev/null; printf '%s\n' "$title"; } >"$state/titles.$sid.tmp" &&
  mv "$state/titles.$sid.tmp" "$state/titles"

jq -n --arg t "$title" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}}'
