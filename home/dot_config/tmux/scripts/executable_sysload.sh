#!/bin/sh
# tmux status: CPU busy percent over one second (all cores, 0-100), percent of memory in use, and
# free disk space in GB, on macOS and Linux.
case $(uname) in
Darwin)
  # the first top sample averages since boot, so take the second, one second later
  cpu=$(top -l 2 -n 0 -s 1 | awk '/CPU usage/ {v = $7} END {sub("%", "", v); printf "%d", 100 - v}')
  mem=$(memory_pressure -Q | awk '/free percentage/ {sub("%", "", $NF); print 100 - $NF}')
  # user files live on the Data volume; the read-only system volume at / reports misleading usage
  vol=/System/Volumes/Data
  ;;
*)
  cpu_sample() { awk '/^cpu / {t = 0; for (i = 2; i <= NF; i++) t += $i; print t, $5 + $6}' /proc/stat; }
  a=$(cpu_sample)
  sleep 1
  b=$(cpu_sample)
  cpu=$(echo "$a $b" | awk '{dt = $3 - $1; di = $4 - $2; printf "%d", (dt > 0 ? (dt - di) * 100 / dt : 0)}')
  mem=$(awk '/^MemTotal/ {t = $2} /^MemAvailable/ {a = $2} END {printf "%d", (t - a) * 100 / t}' /proc/meminfo)
  vol=/
  ;;
esac
# prints free space in GB, then free percent
set -- $(df -Pk "$vol" | awk 'NR == 2 {printf "%d %d", $4 / 1048576, $4 * 100 / $2}')
disk=$1
disk_free_pct=$2

# red (Tide's failure color) at 90% memory used or under 10% disk free;
# #8787AF restores the segment color set in tmux.conf
red='#[fg=#D70000]'
base='#[fg=#8787AF]'
mem_color=$base
[ "$mem" -ge 90 ] && mem_color=$red
disk_color=$base
[ "$disk_free_pct" -lt 10 ] && disk_color=$red
printf 'c%s%% %sm%s%%%s %s%sG%s' "$cpu" "$mem_color" "$mem" "$base" "$disk_color" "$disk" "$base"
