#!/bin/sh
# UserPromptSubmit hook: names a session from its first prompt, like /rename,
# as a filename-style slug (tmux-hooks). Haiku writes the title in the
# background, so the prompt never waits. The tmux session takes the name as
# soon as Haiku answers; Claude shows it above the prompt from the next prompt.
# Skips unattended runs (claude -p), sessions the user named, slash commands,
# and prompts under 4 words.
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
tmux_hook=$(cd "$(dirname "$0")" && pwd)/agent-tmux-session.sh

if [ "$1" = new ]; then
  rm -f "$state/$sid" "$state/$sid.haiku"
  touch "$state/$sid.new"
  exit 0
fi
[ -f "$state/$sid" ] && exit 0

# Set by `claude -n`, /rename, or a resumed session's earlier name; keep it.
# Claude's own generated title and this hook's Haiku title may be replaced.
# /clear carries the old name over, so a new session also replaces a name this
# hook set. Names the user chose are never in that list.
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
native=
[ -r "$transcript" ] && native=$(grep '"type":"ai-title"' "$transcript" | tail -n 1 | jq -r '.aiTitle // empty')
user_named() {
  [ -n "$old" ] || return 1
  [ "$old" = "$native" ] && return 1
  [ "$old" = "$(cat "$state/$sid.haiku" 2>/dev/null)" ] && return 1
  [ -f "$state/$sid.new" ] && generated && return 1
  return 0
}
if user_named; then
  touch "$state/$sid"
  exit 0
fi

if ! [ -f "$state/$sid.haiku" ]; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // "" | .[:1000]')
  case $prompt in '' | /*) exit 0 ;; esac
  # Greetings and pings make filler titles; leave the session for the next prompt.
  [ "$(printf '%s' "$prompt" | wc -w)" -ge 4 ] || exit 0
  : >"$state/$sid.haiku"
  # Tags and the never-answer rule stop Haiku replying to questions instead.
  system='Write a title for the coding session that starts with the message inside <message> tags. Never answer or reply to the message; only title it.
Rules: 3-7 words. Start with a verb (Fix, Add, Review, Explain, Check, Speed up). Keep specific names: ticket IDs, files, tools, repos, settings. Never use filler words like request, question, session, inquiry, help, initiated. Output the title only.
Examples:
can you see why PROJ-123 is still open in web-player -> Check why PROJ-123 is open in web-player
is there any way we can have haiku auto title give better titles -> Improve Haiku auto-title prompt
the stop hook keeps blocking me over and over -> Fix repeated stop-hook blocks'
  # No settings sources means no hooks, so this call cannot trigger itself.
  (
    cd "$state" || exit 0
    # A failed call (usage limit, auth, timeout) prints its error as the
    # answer, so drop output from a non-zero exit or a limit message.
    title=$(printf '<message>\n%s\n</message>\n' "$prompt" |
      CLAUDE_CODE_DISABLE_CLAUDE_MDS=1 timeout 30 claude -p --model haiku \
        --system-prompt "$system" \
        --tools '' --setting-sources '' --strict-mcp-config --no-session-persistence \
        --max-turns 1 2>/dev/null) || title=
    title=$(printf '%s\n' "$title" | head -n 1)
    case $title in *[Hh]it\ your*limit* | *[Ll]imit\ reached* | *[Uu]sage\ limit*) title= ;; esac
    title=$(sh "$tmux_hook" slug "$title")
    if [ -z "$title" ]; then
      rm -f "$state/$sid.haiku"
      exit 0
    fi
    printf '%s\n' "$title" >"$state/$sid.haiku"
    sh "$tmux_hook" set "$title"
  ) </dev/null >/dev/null 2>&1 &
  exit 0
fi

# Haiku has not answered yet; try again on the next prompt.
title=$(cat "$state/$sid.haiku")
[ -n "$title" ] || exit 0
[ "$old" = "$title" ] && {
  touch "$state/$sid"
  exit 0
}

touch "$state/$sid"
rm -f "$state/$sid.new"
find "$state" -type f -mtime +30 -delete 2>/dev/null
# Remember set names so /clear can tell them from user-chosen names.
{ tail -n 499 "$state/titles" 2>/dev/null; printf '%s\n' "$title"; } >"$state/titles.$sid.tmp" &&
  mv "$state/titles.$sid.tmp" "$state/titles"

jq -n --arg t "$title" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}}'
