#!/bin/sh
# Keeps an idle main session's 1-hour prompt cache warm for up to 3 idle hours.
#   prompt: UserPromptSubmit hook; records the last prompt time.
#   idle:   Notification idle_prompt hook with asyncRewake; sleeps, then exits 2
#           to wake Claude for a one-word reply that reads the cache.
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

case $mode in
prompt)
  case $(printf '%s' "$input" | jq -r '.prompt // ""') in
  *cache-keepalive*) exit 0 ;;
  esac
  date +%s >"$state/$sid.last_prompt"
  ;;
idle)
  sleep_s=${CACHE_KEEPALIVE_SLEEP:-2880}
  max_idle=${CACHE_KEEPALIVE_MAX_IDLE:-10800}
  transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
  [ -f "$transcript" ] || exit 0
  find "$state" -type f -mtime +2 -delete 2>/dev/null

  # Skip when the latest cache write used the 5-minute TTL; a ping would only rewrite it.
  ttl_1h=$(tail -n 300 "$transcript" | jq -R -r 'fromjson?
    | select(.type == "assistant") | .message.usage
    | select((.cache_creation_input_tokens // 0) > 0)
    | .cache_creation.ephemeral_1h_input_tokens // 0' 2>/dev/null | tail -n 1)
  [ "${ttl_1h:-0}" -gt 0 ] || exit 0

  before=$(last_entry "$transcript")
  [ -f "$state/$sid.last_prompt" ] || date +%s >"$state/$sid.last_prompt"
  printf '%s\n' "$$" >"$state/$sid.sleeper"
  sleep "$sleep_s"

  # A newer sleeper or any session activity means this wait is stale.
  [ "$(cat "$state/$sid.sleeper" 2>/dev/null)" = "$$" ] || exit 0
  [ "$(last_entry "$transcript")" = "$before" ] || exit 0
  last=$(cat "$state/$sid.last_prompt")
  [ $(($(date +%s) - last)) -lt "$max_idle" ] || exit 0

  echo 'cache-keepalive: the session is idle. Reply with only "ok" and call no tools.' >&2
  exit 2
  ;;
esac
exit 0
