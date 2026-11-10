#!/bin/sh
# Keeps an idle main session's 1-hour prompt cache warm for about 2.5 idle hours.
#   prompt: UserPromptSubmit hook; records the last prompt time.
#   idle:   Notification idle_prompt hook with asyncRewake; sleeps, then exits 2
#           to wake Claude for a one-word reply that reads the cache.
#           Skips sessions with an active /goal (latest goal_status unmet).
#           Skips the wait while a usage limit stays used up past the ping, and
#           stops after a ping that failed. Writes <sid>.ping ("ok" or "fail")
#           for the status line; a new prompt clears it.
mode=$1
state=${XDG_STATE_HOME:-$HOME/.local/state}/agents/cache-keepalive
mkdir -p "$state"
input=$(cat)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0

# Last conversation entry; bookkeeping lines written while idle do not count.
last_entry() {
  tail -n 300 "$1" | jq -R -r 'fromjson? | select(.type == "user" or .type == "assistant") | .uuid' | tail -n 1
}

# Latest reset among the account's used-up usage limits, or nothing. Reads the
# cache the status line keeps, under the same account key.
blocked_until() {
  cfg=$HOME/.claude.json
  [ -n "$CLAUDE_CONFIG_DIR" ] && cfg=$CLAUDE_CONFIG_DIR/.claude.json
  acct=$(grep -oE '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$cfg" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/')
  key=$(printf '%s' "${acct:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}" | tr -c 'A-Za-z0-9._@-' '_')
  jq -r --argjson now "$(date +%s)" '[.[]? | select(type == "object"
    and (.used_percentage // 0) >= 100 and (.resets_at // 0) > $now) | .resets_at] | max // empty' \
    "${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/rate-limits-$key.json" 2>/dev/null
}

# "ok" or "fail" for the keepalive ping that ended the transcript's last turn
# (a failed ping answers with an API error), else nothing.
ping_result() {
  tail -n 300 "$1" | jq -R -r 'fromjson? | select(.type == "user" or .type == "assistant")
    | if .type == "user" then (if (.message.content | tostring | contains("cache-keepalive: the session is idle")) then "P" else "U" end)
      elif .isApiErrorMessage == true then "E" else "A" end' |
    awk '$1 == "P" { p = 1; r = "" } $1 == "U" { p = 0; r = "" }
      p && $1 == "E" { r = "fail"; p = 0 } p && $1 == "A" { r = "ok"; p = 0 } END { print r }'
}

# True when the latest /goal state in the transcript is an active, unmet goal.
# The Stop-hook loop already keeps such a session busy; a ping only feeds it.
goal_active() {
  last=$(grep -a -E '"type":"goal_status"|<local-command-stdout>Goal cleared' "$1" | tail -n 1)
  case $last in
  *'"type":"goal_status"'*) case $last in *'"met":true'* | *'"failed":true'*) return 1 ;; esac; return 0 ;;
  esac
  return 1
}

case $mode in
prompt)
  case $(printf '%s' "$input" | jq -r '.prompt // ""') in
  *cache-keepalive*) exit 0 ;;
  esac
  date +%s >"$state/$sid.last_prompt"
  rm -f "$state/$sid.ping"
  ;;
idle)
  sleep_s=${CACHE_KEEPALIVE_SLEEP:-2700}
  max_idle=${CACHE_KEEPALIVE_MAX_IDLE:-7200}
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
  [ -f "$transcript" ] || exit 0
  find "$state" -type f -mtime +2 -delete 2>/dev/null
  goal_active "$transcript" && exit 0

  # Skip when the latest cache write used the 5-minute TTL; a ping would only rewrite it.
  ttl_1h=$(tail -n 300 "$transcript" | jq -R -r 'fromjson?
    | select(.type == "assistant") | .message.usage
    | select((.cache_creation_input_tokens // 0) > 0)
    | .cache_creation.ephemeral_1h_input_tokens // 0' 2>/dev/null | tail -n 1)
  [ "${ttl_1h:-0}" -gt 0 ] || exit 0

  # A failed ping ends the chain; so does a limit that stays used up past the next ping.
  result=$(ping_result "$transcript")
  [ -z "$result" ] || printf '%s\n' "$result" >"$state/$sid.ping"
  if [ "$result" = fail ]; then rm -f "$state/$sid.sleeper"; exit 0; fi
  blocked=$(blocked_until)
  if [ -n "$blocked" ] && [ $(($(date +%s) + sleep_s)) -lt "${blocked%.*}" ]; then
    rm -f "$state/$sid.sleeper"
    exit 0
  fi

  before=$(last_entry "$transcript")
  [ -f "$state/$sid.last_prompt" ] || date +%s >"$state/$sid.last_prompt"
  printf '%s\n' "$$" >"$state/$sid.sleeper"
  sleep "$sleep_s"

  # A newer sleeper or any session activity means this wait is stale.
  [ "$(cat "$state/$sid.sleeper" 2>/dev/null)" = "$$" ] || exit 0
  [ "$(last_entry "$transcript")" = "$before" ] || exit 0
  last=$(cat "$state/$sid.last_prompt")
  [ $(($(date +%s) - last)) -lt "$max_idle" ] || exit 0
  # A limit used up since the wait began would fail the ping.
  [ -z "$(blocked_until)" ] || exit 0

  echo 'cache-keepalive: the session is idle. Reply with only "ok" and call no tools.' >&2
  exit 2
  ;;
esac
exit 0
