#!/bin/sh
# UserPromptSubmit hook: names a session from its first prompt, like /rename.
# Asks Haiku for a short title through a minimal headless call (~620 tokens).
# Skips unattended runs (claude -p), sessions that already have a title, and slash commands.
[ "${CLAUDE_CODE_SESSION_ATTENDED:-1}" = 0 ] && exit 0
state=${XDG_STATE_HOME:-$HOME/.local/state}/agents/auto-title
mkdir -p "$state"
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0
[ -f "$state/$sid" ] && exit 0

prompt=$(printf '%s' "$input" | jq -r '.prompt // "" | .[:1000]')
case $prompt in
'' | /*) exit 0 ;;
esac

touch "$state/$sid"
find "$state" -type f -mtime +30 -delete 2>/dev/null
# Set by `claude -n`, /rename, or a resumed session's earlier title.
[ -n "$(printf '%s' "$input" | jq -r '.session_title // empty')" ] && exit 0

# No settings sources means no hooks, so this call cannot trigger itself.
title=$(cd "$state" && printf '%s' "$prompt" |
  CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 timeout 15 claude -p --model haiku \
    --system-prompt 'Reply with a 3-6 word title for this coding session request. Title only, no quotes or punctuation at the end.' \
    --tools '' --setting-sources '' --strict-mcp-config --no-session-persistence \
    --max-turns 1 2>/dev/null | head -n 1 | tr -d '"`' | cut -c1-60)
[ -n "$title" ] || exit 0

jq -n --arg t "$title" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}}'
