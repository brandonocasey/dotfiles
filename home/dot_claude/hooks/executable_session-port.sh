#!/bin/sh
# SessionStart hook: reserves each session a block of 10 dev-server ports in
# 40000-48999, below the macOS ephemeral range, and exports them as PORT and
# PORT_1 .. PORT_9 to the session's Bash commands. The statusline reads the
# same file to show "<lan-ip>:<port>" and touches it while the session is open.
# It also records the session's prompt-cache expiry in port-<sid>.until, so a
# block is released only once its file is untouched for an hour and that
# expiry, if recorded, has passed. An open session whose file was released
# gets it back from the statusline while no other session holds the block.
# A new block is one no other session holds and nothing listens in. The search
# always starts at the same point for a session, so a resumed session usually
# gets its old block back. When the statusline saw an outside process on the
# session's port, it leaves a .conflict file and resuming picks a new block.
# Compaction keeps the block: the session's exported PORT MUST NOT change
# mid-session.
input=$(cat)
sid=$(printf '%s' "$input" | jq -j '.session_id // empty' 2>/dev/null | tr -c 'A-Za-z0-9._-' '_')
source=$(printf '%s' "$input" | jq -r '.source // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
mkdir -p "$dir" || exit 0
file="$dir/port-$sid"
lock="$dir/port.lock"

# Sessions starting together MUST NOT read the free blocks at the same time;
# the statusline takes the same lock to restore a released block. A run holds
# the lock well under a second, so a lock 2 s or older belongs to a killed
# run. Only the run holding $lock.takeover may remove it, after checking its
# age again, so two waiters never both take it over.
lock_age() {
  m=$(stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null)
  case $m in '' | *[!0-9]*) echo 0 ;; *) echo $(($(date +%s) - m)) ;; esac
}
tries=0
until mkdir "$lock" 2>/dev/null; do
  tries=$((tries + 1))
  [ "$tries" -le 30 ] || exit 0
  if [ "$(lock_age "$lock")" -ge 2 ]; then
    if mkdir "$lock.takeover" 2>/dev/null; then
      [ "$(lock_age "$lock")" -ge 2 ] && rmdir "$lock" 2>/dev/null
      rmdir "$lock.takeover" 2>/dev/null
      continue
    fi
    # A takeover lock this old belongs to a killed run.
    [ "$(lock_age "$lock.takeover")" -ge 5 ] && rmdir "$lock.takeover" 2>/dev/null
  fi
  sleep 0.1
done
trap 'rmdir "$lock" 2>/dev/null' EXIT

now=$(date +%s)
find "$dir" -type f -name 'port-*' ! -name '*.conflict' ! -name '*.until' -mmin +60 2>/dev/null |
  while IFS= read -r f; do
    until_at=$(cat "$f.until" 2>/dev/null)
    case $until_at in '' | *[!0-9]*) until_at=0 ;; esac
    [ "$until_at" -gt "$now" ] || rm -f "$f" "$f.conflict" "$f.until"
  done
for f in "$dir"/port-*.conflict "$dir"/port-*.until; do
  [ -e "$f" ] && [ ! -e "${f%.*}" ] && rm -f "$f"
done
port=$(cat "$file" 2>/dev/null)
case $port in *[!0-9]*) port="" ;; esac
# Blocks from an older layout, or one an outside process took, are replaced.
if [ -n "$port" ] && { [ "$port" -lt 40000 ] || [ "$port" -gt 48990 ] ||
  [ $(((port - 40000) % 10)) -ne 0 ] ||
  { [ "$source" != compact ] && [ -f "$file.conflict" ]; }; }; then
  port=""
  rm -f "$file.conflict"
fi
if [ -z "$port" ]; then
  # Block indexes held by other sessions or holding any listener.
  taken=$({
    for f in "$dir"/port-*; do
      case $f in ("$file" | *.conflict | *.until) continue ;; esac
      cat "$f" 2>/dev/null
    done
    lsof -nP -iTCP -sTCP:LISTEN -Fn 2>/dev/null | sed -n 's/^n.*:\([0-9][0-9]*\)$/\1/p'
  } | awk '$1 >= 40000 && $1 <= 48999 { print int(($1 - 40000) / 10) }' | sort -u)
  start=$(printf '%s' "$sid" | cksum | cut -d ' ' -f 1)
  i=0
  while [ "$i" -lt 900 ]; do
    b=$(((start + i) % 900))
    if ! printf '%s\n' "$taken" | grep -qx "$b"; then
      port=$((40000 + b * 10))
      break
    fi
    i=$((i + 1))
  done
  [ -n "$port" ] || exit 0
fi
printf '%s\n' "$port" > "$file"

if [ -n "$CLAUDE_ENV_FILE" ]; then
  {
    printf 'export PORT=%s\n' "$port"
    n=1
    while [ "$n" -le 9 ]; do
      printf 'export PORT_%s=%s\n' "$n" $((port + n))
      n=$((n + 1))
    done
  } >> "$CLAUDE_ENV_FILE"
fi
exit 0
