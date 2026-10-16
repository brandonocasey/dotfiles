#!/bin/sh
# agent-reap: clean up leftovers that agent sessions leave behind.
# Usage: agent-reap.sh MODE [--apply] [options]
#   session  after a session ends (hook; returns at once): stop processes whose
#            Claude session is gone, then refresh the candidates list
#   report   write the list-only candidates file and print counts
# Dry-run unless --apply. Deletes no files; candidates are for the user to act on.
# Options: --min-age SECS (process age, default 86400), --pid PID (limit the
# process sweep to one pid, for tests), --count (report: print one line from
# the saved candidates file and exit).
# Absolute find path: the user's shell aliases `find` to bfs.
set -u
FIND=/usr/bin/find
HOME_DIR="${HOME:?}"
STATE="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/agents"
REPORT="$STATE/reports/cleanup-candidates.md"
SESSIONS="$HOME_DIR/.claude/sessions"
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
UID_NUM="$(id -u)"
TICKS="$(getconf CLK_TCK 2>/dev/null || echo 100)"
GRACE="${AGENT_REAP_GRACE:-10}"

APPLY=0 MIN_AGE=86400 ONLY_PID="" COUNT=0 MODE="${1:-}"
[ $# -gt 0 ] && shift
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --min-age) MIN_AGE="$2"; shift ;;
    --pid) ONLY_PID="$2"; shift ;;
    --count) COUNT=1 ;;
    --session-id) shift ;;
    --detached) DETACHED=1 ;;
    *) echo "agent-reap: unknown option $1" >&2; exit 2 ;;
  esac
  shift
done
if [ -n "$ONLY_PID" ] && [ "$MODE" != session ]; then
  echo "agent-reap: --pid works only with session mode" >&2; exit 2
fi

say() { printf '%s\n' "$*"; }

# ---- helpers ---------------------------------------------------------------

owned() { [ "$(stat -c %u "$1" 2>/dev/null)" = "$UID_NUM" ]; }

# Start time (clock ticks since boot) of a pid, empty if it is gone.
pid_start() {
  [ -r "/proc/$1/stat" ] || return 1
  sed 's/^.*) //' "/proc/$1/stat" 2>/dev/null | awk '{print $20}'
}

pid_age() {
  st="$(pid_start "$1")" || return 1
  [ -n "$st" ] || return 1
  awk -v st="$st" -v t="$TICKS" '{printf "%d", $1 - st / t}' /proc/uptime
}

# ---- processes ---------------------------------------------------------------

# Value of one variable from a pid's environment (own processes only).
env_of() { # $1 pid, $2 name
  { tr '\0' '\n' < "/proc/$1/environ" | sed -n "s/^$2=//p" | head -n 1; } 2>/dev/null
}

# True when Claude pid $1 is a live session. The sessions registry records the
# start time, so a reused pid does not look alive.
claude_alive() {
  f="$SESSIONS/$1.json"
  # Registry files go away with the session; a gone pid with no file is dead.
  if [ ! -f "$f" ]; then
    [ -e "/proc/$1" ] && return 2
    return 1
  fi
  want="$(sed -n 's/.*"procStart":"\([0-9]*\)".*/\1/p' "$f" | head -n 1)"
  [ -n "$want" ] || return 2
  [ "$(pid_start "$1" 2>/dev/null)" = "$want" ]
}

do_procs() {
  # Skip ourselves and our ancestors.
  skip=" $$ "
  p=$$
  while [ "$p" -gt 1 ] 2>/dev/null; do
    p="$(sed 's/^.*) //' "/proc/$p/stat" 2>/dev/null | awk '{print $2}')"
    [ -n "$p" ] && skip="$skip$p "
  done
  n=0
  for proc in /proc/[0-9]*; do
    pid="${proc#/proc/}"
    owned "$proc" || continue
    [ -z "$ONLY_PID" ] || [ "$pid" = "$ONLY_PID" ] || continue
    case "$skip" in *" $pid "*) continue ;; esac
    cpid="$(env_of "$pid" CLAUDE_PID)"
    [ -n "$cpid" ] || continue
    [ "$cpid" = "$pid" ] && continue
    comm="$(cat "$proc/comm" 2>/dev/null)"
    # Versioned Claude installs run as their version number, e.g. 2.1.302.
    case "$comm" in claude|codex|node-claude|[0-9]*.[0-9]*.[0-9]*) continue ;; esac
    claude_alive "$cpid"
    case $? in 0) continue ;; 2) continue ;; esac   # alive, or no record: leave it
    age="$(pid_age "$pid")" || continue
    [ "$age" -ge "$MIN_AGE" ] || continue
    start="$(pid_start "$pid")"
    cmd="$(tr '\0\n' '  ' < "$proc/cmdline" 2>/dev/null | cut -c1-80)"
    n=$((n + 1))
    if [ "$APPLY" = 1 ]; then
      say "TERM $pid (start $start, age ${age}s) $cmd"
      [ "$(pid_start "$pid")" = "$start" ] && kill -TERM "$pid" 2>/dev/null
      echo "$pid $start" >> "$WORK/killed"
    else
      say "would TERM $pid (start $start, age ${age}s) $cmd"
    fi
  done
  if [ "$APPLY" = 1 ] && [ -s "$WORK/killed" ]; then
    i=0
    while [ "$i" -lt "$GRACE" ]; do
      alive=0
      while read -r pid start; do
        [ "$(pid_start "$pid" 2>/dev/null)" = "$start" ] && alive=1
      done < "$WORK/killed"
      [ "$alive" = 0 ] && break
      sleep 1; i=$((i + 1))
    done
    while read -r pid start; do
      if [ "$(pid_start "$pid" 2>/dev/null)" = "$start" ]; then
        say "KILL $pid"
        kill -KILL "$pid" 2>/dev/null
      fi
    done < "$WORK/killed"
  fi
  say "procs: $n orphans older than ${MIN_AGE}s $( [ "$APPLY" = 1 ] && echo signalled || echo 'would signal' )"
}

# ---- list-only candidates -----------------------------------------------------

candidates() {
  out="$WORK/candidates.md"
  total=0
  {
    say "## Merged, clean worktrees older than 3 days"
    say "Remove with the command shown. Never rm."
    for repo in "$HOME_DIR"/projects/*/*/; do
      repo="${repo%/}"
      [ -d "$repo/.git" ] || continue
      base="$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"
      [ -n "$base" ] || base="origin/main"
      git -C "$repo" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | while read -r wt; do
        [ "$wt" = "$repo" ] && continue
        case "$wt" in "$repo"/.worktrees/*) ;; *) continue ;; esac
        [ -e "$wt/.git" ] || continue
        git -C "$wt" merge-base --is-ancestor HEAD "$base" 2>/dev/null || continue
        [ -z "$(git -C "$wt" status --porcelain 2>/dev/null)" ] || continue
        gd="$(git -C "$wt" rev-parse --absolute-git-dir 2>/dev/null)"
        newest="$(git -C "$wt" log -1 --format=%ct 2>/dev/null)"
        for t in "$gd/HEAD" "$gd/index"; do
          m="$(stat -c %Y "$t" 2>/dev/null)"
          [ -n "$m" ] && [ "$m" -gt "${newest:-0}" ] && newest="$m"
        done
        [ $(( $(date +%s) - ${newest:-0} )) -ge $((3 * 86400)) ] || continue
        say "- git -C $repo worktree remove $wt"
      done
    done
    say ""
    say "## Merged local branches"
    say "Delete with the command shown."
    for repo in "$HOME_DIR"/projects/*/*/; do
      repo="${repo%/}"
      [ -d "$repo/.git" ] || continue
      base="$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"
      [ -n "$base" ] || base="origin/main"
      checked="$(git -C "$repo" worktree list --porcelain 2>/dev/null | sed -n 's|^branch refs/heads/||p')"
      git -C "$repo" branch --merged "$base" --format='%(refname:short)' 2>/dev/null | while read -r b; do
        case "$b" in main|master|develop) continue ;; esac
        printf '%s\n' "$checked" | grep -qx -- "$b" && continue
        say "- git -C $repo branch -d $b"
      done
    done
    say ""
    say "## Backups"
    say "Never deleted automatically."
    if [ -d "$STATE/backups" ]; then
      "$FIND" "$STATE/backups" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | xargs -0 -r du -sk 2>/dev/null \
        | sort -rn | awk '{k=$1; $1=""; printf "- %.1f MiB%s\n", k/1024, $0}'
    fi
    say ""
    say "## Old Codex releases"
    say "Keep current and the previous one."
    rel="$HOME_DIR/.codex/packages/standalone/releases"
    cur="$(readlink "$HOME_DIR/.codex/packages/standalone/current" 2>/dev/null)"
    if [ -d "$rel" ]; then
      "$FIND" "$rel" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort -V | while read -r r; do
        printf '%s\n' "$rel/$r"
      done > "$WORK/rel"
      keep_prev="$(grep -n -x -- "$cur" "$WORK/rel" | cut -d: -f1)"
      keep_prev=$(( ${keep_prev:-0} - 1 ))
      awk -v cur="$cur" -v prev="$keep_prev" 'NR!=prev && $0!=cur {print "- " $0}' "$WORK/rel"
    fi
    say ""
    say "## Superseded ms-playwright builds"
    pw="${PLAYWRIGHT_BROWSERS_PATH:-$HOME_DIR/.cache/ms-playwright}"
    if [ -d "$pw" ]; then
      "$FIND" "$pw" -mindepth 1 -maxdepth 1 -printf '%f\n' | sed -n 's/^\(.*[a-z_]\)-\([0-9][0-9]*\)$/\1 \2/p' | sort -k1,1 -k2,2n | awk '
        {name[NR]=$1; ver[NR]=$2}
        END{for(i=1;i<=NR;i++){ if (i<NR && name[i]==name[i+1]) print "- " name[i] "-" ver[i] }}' \
        | sed "s|^- |- $pw/|"
    fi
  } > "$out"
  total="$(grep -c '^- ' "$out")"
  mkdir -p "$(dirname "$REPORT")"
  {
    say "# Cleanup candidates"
    say ""
    say "<!-- count: $total -->"
    say "Generated $(date '+%Y-%m-%d %H:%M'). List only; nothing here is deleted automatically."
    say ""
    cat "$out"
  } > "$REPORT.$$.tmp" && mv "$REPORT.$$.tmp" "$REPORT"   # per-run temp: sessions may end together
  say "candidates: $total entries in $REPORT"
  for h in "Merged, clean worktrees" "Merged local branches" "Backups" "Old Codex releases" "Superseded ms-playwright"; do
    c="$(awk -v h="$h" 'index($0,"## " h)==1{on=1;next} /^## /{on=0} on&&/^- /{c++} END{print c+0}' "$out")"
    say "  $h: $c"
  done
}

# ---- modes -------------------------------------------------------------------

WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent-reap.XXXXXX")" || exit 1
trap '"$FIND" "$WORK" -delete 2>/dev/null' EXIT

case "$MODE" in
  session)
    # Hook mode: detach and return at once. Once the session's Claude process
    # has exited, stop its orphans and refresh the candidates list.
    if [ -z "${DETACHED:-}" ]; then
      args="session --detached"
      [ "$APPLY" = 1 ] && args="$args --apply"
      # shellcheck disable=SC2086
      nohup setsid sh "$SELF" $args --min-age "$MIN_AGE" ${ONLY_PID:+--pid "$ONLY_PID"} \
        >> "$STATE/agent-reap.log" 2>&1 < /dev/null &
      exit 0
    fi
    sleep "${AGENT_REAP_SETTLE:-5}"
    do_procs
    [ -z "$ONLY_PID" ] && candidates
    ;;
  report)
    if [ "$COUNT" = 1 ]; then
      c="$(sed -n 's/^<!-- count: \([0-9]*\) -->$/\1/p' "$REPORT" 2>/dev/null | head -n 1)"
      [ -n "$c" ] && [ "$c" -gt 0 ] && say "agent-reap: $c cleanup candidates in $REPORT"
      exit 0
    fi
    do_procs
    candidates
    ;;
  *) echo "usage: agent-reap.sh session|report [--apply]" >&2; exit 2 ;;
esac
exit 0
