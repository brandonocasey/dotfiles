#!/bin/sh
# tmux status: CPU load as a percent of all cores, percent of memory in use, and
# free disk space in GB, on macOS and Linux.
case $(uname) in
Darwin)
  load=$(sysctl -n vm.loadavg | awk '{print $2}')
  mem=$(memory_pressure -Q | awk '/free percentage/ {sub("%", "", $NF); print 100 - $NF}')
  # user files live on the Data volume; the read-only system volume at / reports misleading usage
  vol=/System/Volumes/Data
  ;;
*)
  load=$(cut -d' ' -f1 /proc/loadavg)
  mem=$(awk '/^MemTotal/ {t = $2} /^MemAvailable/ {a = $2} END {printf "%d", (t - a) * 100 / t}' /proc/meminfo)
  vol=/
  ;;
esac
# 1-minute load average over core count; above 100% means work is queuing
cpu=$(awk -v l="$load" -v n="$(getconf _NPROCESSORS_ONLN)" 'BEGIN {printf "%d", l * 100 / n}')
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
