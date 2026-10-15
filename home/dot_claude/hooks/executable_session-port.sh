#!/bin/sh
# SessionStart hook: reserves each session a block of 10 dev-server ports in
# 40000-48999, below the macOS ephemeral range, and exports them as PORT and
# PORT_1 .. PORT_9 to the session's Bash commands. The statusline reads the
# same file to show "<lan-ip>:<port>" and touches it while the session is open,
# so only open sessions hold a block: a file untouched for an hour is released.
# A new block is one no open session holds and nothing listens in. The search
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

# Sessions starting together MUST NOT read the free blocks at the same time.
# A run holds the lock well under a second, so one still held after 2 s
# belongs to a killed run and is taken over.
tries=0
until mkdir "$lock" 2>/dev/null; do
  tries=$((tries + 1))
  if [ "$tries" -ge 20 ]; then
    rmdir "$lock" 2>/dev/null
    mkdir "$lock" 2>/dev/null && break
    exit 0
  fi
  sleep 0.1
done
trap 'rmdir "$lock" 2>/dev/null' EXIT

find "$dir" -type f -name 'port-*' -mmin +60 -delete 2>/dev/null
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
      case $f in ("$file" | *.conflict) continue ;; esac
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
