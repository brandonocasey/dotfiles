#!/bin/sh
# UserPromptSubmit hook: names a session from its first prompt, like /rename,
# as plain words (Fix stop-hook loop). Haiku writes the title in the
# background, so the prompt never waits. The tmux session takes the name as
# soon as Haiku answers; Claude shows it above the prompt from the next prompt.
# Skips unattended runs (claude -p), sessions the user named, slash commands,
# and prompts under 4 words.
# SessionStart hook with `new` (startup or /clear): /clear carries the old
# name over, so it records that name, and the next prompt names the session
# "<old name> Part N" (agent-tmux-session.sh part).
# PostToolUse (Bash) and CwdChanged hook with `branch`: the branch the session
# moves to, from `agt worktree create` output or a cwd in a linked worktree,
# names the session at the next prompt, over any earlier name; tmux takes it
# at once. A session that starts in a linked worktree takes its branch too.
# SessionEnd hook with `end` (/clear): a branch not yet taken carries over to
# the session /clear starts in the same Claude process.
# Every name, the user's too, keeps the session's port in front (see
# agent-tmux-session.sh ported); titles are compared without it.
[ "${CLAUDE_CODE_SESSION_ATTENDED:-1}" = 0 ] && exit 0
state=${XDG_STATE_HOME:-$HOME/.local/state}/agents/auto-title
mkdir -p "$state"
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0
old=$(printf '%s' "$input" | jq -r '.session_title // empty')
tmux_hook=$(cd "$(dirname "$0")" && pwd)/agent-tmux-session.sh
base=$(sh "$tmux_hook" bare "$old")
# Sets the name when it differs from the current one, then ends the hook.
finish() {
  [ -n "$1" ] && [ "$1" != "$old" ] &&
    jq -n --arg t "$1" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}}'
  exit 0
}

# The branch checked out at <dir> when <dir> is in a linked worktree.
worktree_branch() {
  [ -n "$1" ] || return 0
  dirs=$(git -C "$1" rev-parse --path-format=absolute --git-dir --git-common-dir 2>/dev/null) || return 0
  [ "$(printf '%s\n' "$dirs" | sed -n 1p)" != "$(printf '%s\n' "$dirs" | sed -n 2p)" ] || return 0
  git -C "$1" symbolic-ref --short -q HEAD
}

# Claude's PID stays the same across /clear; the session ID does not.
handoff=
case ${CLAUDE_PID:-} in '' | *[!0-9]*) ;; *) handoff=$state/pid-$CLAUDE_PID.branch ;; esac

if [ "$1" = end ]; then
  [ -n "$handoff" ] && [ -s "$state/$sid.branch" ] && mv -f "$state/$sid.branch" "$handoff"
  exit 0
fi

if [ "$1" = branch ]; then
  case $input in *'"CwdChanged"'* | *reused*) ;; *) exit 0 ;; esac
  if [ "$(printf '%s' "$input" | jq -r '.hook_event_name // empty')" = CwdChanged ]; then
    branch=$(worktree_branch "$(printf '%s' "$input" | jq -r '.new_cwd // empty')")
  else
    # `agt worktree create` prints one JSON line with path, branch, and reused.
    created=$(printf '%s' "$input" | jq -c '.tool_response.stdout // "" | strings | split("\n")[] |
      fromjson? | objects | select((.path | type) == "string" and (.branch | type) == "string" and
      (.reused | type) == "boolean")' 2>/dev/null | tail -n 1)
    [ -n "$created" ] || exit 0
    branch=$(printf '%s' "$created" | jq -r .branch)
    [ "$(worktree_branch "$(printf '%s' "$created" | jq -r .path)")" = "$branch" ] || exit 0
  fi
  [ -n "$branch" ] || exit 0
  printf '%s\n' "$branch" >"$state/$sid.branch"
  sh "$tmux_hook" set "$branch" "$sid"
  exit 0
fi

if [ "$1" = new ]; then
  rm -f "$state/$sid" "$state/$sid.haiku" "$state/$sid.branch"
  if [ "$(printf '%s' "$input" | jq -r '.source // empty')" = clear ]; then
    [ -n "$old" ] && printf '%s\n' "$old" >"$state/$sid.cleared"
    mv -f "$handoff" "$state/$sid.branch" 2>/dev/null
    exit 0
  fi
  [ -n "$handoff" ] && rm -f "$handoff"
  # A name from `claude -n` wins over the branch.
  [ -z "$base" ] || exit 0
  branch=$(worktree_branch "$(printf '%s' "$input" | jq -r '.cwd // empty')")
  [ -n "$branch" ] && printf '%s\n' "$branch" >"$state/$sid.branch"
  exit 0
fi

if [ -s "$state/$sid.branch" ]; then
  title=$(cat "$state/$sid.branch")
  rm -f "$state/$sid.branch" "$state/$sid.cleared"
  touch "$state/$sid"
  finish "$(sh "$tmux_hook" ported "$title" "$sid")"
fi
if [ -f "$state/$sid.cleared" ] && [ "$old" = "$(cat "$state/$sid.cleared")" ]; then
  title=$(sh "$tmux_hook" part "$old")
  if [ -n "$title" ]; then
    touch "$state/$sid"
    finish "$(sh "$tmux_hook" ported "$title" "$sid")"
  fi
  base=
  current=$(sh "$tmux_hook" ported '' "$sid")
else
  rm -f "$state/$sid.cleared"
  current=$(sh "$tmux_hook" ported "$old" "$sid")
fi
[ -f "$state/$sid" ] && finish "$current"

# Set by `claude -n`, /rename, or a resumed session's earlier name; keep it.
# Claude's own generated title and this hook's Haiku title may be replaced.
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
native=
[ -r "$transcript" ] && native=$(grep '"type":"ai-title"' "$transcript" | tail -n 1 | jq -r '.aiTitle // empty')
user_named() {
  [ -n "$base" ] || return 1
  [ "$base" = "$native" ] && return 1
  [ "$base" = "$(cat "$state/$sid.haiku" 2>/dev/null)" ] && return 1
  return 0
}
if user_named; then
  touch "$state/$sid"
  finish "$current"
fi

if ! [ -f "$state/$sid.haiku" ]; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // "" | .[:1000]')
  # A hand-back from another session, or Claude's own nudge after a usage
  # limit resets, is not the topic; wait for a real prompt.
  case $prompt in
  '' | /* | 'Another Claude session sent a message'* | 'Your claude.ai usage limit has reset'*) finish "$current" ;;
  esac
  # Greetings and pings make filler titles; leave the session for the next prompt.
  [ "$(printf '%s' "$prompt" | wc -w)" -ge 4 ] || finish "$current"
  : >"$state/$sid.haiku"
  # Tags and the never-answer rule stop Haiku replying to questions instead.
  system='Write a title for the coding session that starts with the message inside <message> tags. Never answer or reply to the message; only title it.
Rules: 3-7 words and under 50 characters, so the title is never cut off. Use sentence case. Start with a verb (Fix, Add, Review, Explain, Check, Speed up). Keep specific names: ticket IDs, files, tools, repos, settings. Never use filler words like request, question, session, inquiry, help, initiated. Output the title only.
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
    title=$(sh "$tmux_hook" tidy "$title")
    if [ -z "$title" ]; then
      rm -f "$state/$sid.haiku"
      exit 0
    fi
    printf '%s\n' "$title" >"$state/$sid.haiku"
    # A branch or name that arrived meanwhile keeps tmux.
    [ -f "$state/$sid" ] || [ -f "$state/$sid.branch" ] || sh "$tmux_hook" set "$title" "$sid"
  ) </dev/null >/dev/null 2>&1 &
  finish "$current"
fi

# Haiku has not answered yet; try again on the next prompt.
title=$(cat "$state/$sid.haiku")
[ -n "$title" ] || finish "$current"
[ "$base" = "$title" ] && {
  touch "$state/$sid"
  finish "$current"
}

touch "$state/$sid"
find "$state" -type f -mtime +30 -delete 2>/dev/null

finish "$(sh "$tmux_hook" ported "$title" "$sid")"
