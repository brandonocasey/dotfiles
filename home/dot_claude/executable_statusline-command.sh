#!/usr/bin/env bash
# Claude Code status line script. Besides drawing the line, it keeps the
# session's port block from hooks/session-port.sh reserved: it touches the
# port file, records the prompt-cache expiry the block is kept until, and
# writes a released port file back while no other session holds the block.

input=$(cat 2>/dev/null || echo '{}')

# --- Account (local part of the configured email) ---
acct_cfg="$HOME/.claude.json"
[ -n "$CLAUDE_CONFIG_DIR" ] && acct_cfg="$CLAUDE_CONFIG_DIR/.claude.json"
account=$(grep -oE '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$acct_cfg" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/')
account_name="${account%%@*}"

now=${EPOCHSECONDS:-$(date +%s)}

# Read every input field in one jq run; each extra run costs about 4 ms.
# Missing fields come out empty; so do all of them when jq fails.
cwd="" transcript="" model_raw="" model_id="" effort_raw="" ctx_remaining=""
ctx_total="" ctx_used_tokens="" rl_sid="" rl_live="" pc_state="" pc_expires=""
pc_ttl=""
eval "$(printf '%s' "$input" | jq -r --argjson now "$now" '
  def s: if . == null then "" else tostring end | @sh;
  "cwd=\(.workspace.current_dir // .cwd | s)",
  "transcript=\(.transcript_path | s)",
  "model_raw=\(.model.display_name | s)",
  "model_id=\(.model.id | s)",
  "effort_raw=\(.effort.level | s)",
  "ctx_remaining=\(.context_window.remaining_percentage | s)",
  "ctx_total=\(.context_window.context_window_size // .context_window.total_tokens // .context_window.total
    // .context_window.size // .context_window.max_tokens // .context_window.window_tokens | s)",
  # Tokens in context from the last API call (same input-only formula as used_percentage).
  "ctx_used_tokens=\(.context_window.current_usage
    | if . then (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0) else null end | s)",
  "rl_sid=\(.session_id | s)",
  "rl_live=\(.rate_limits // {} | tojson | @sh)",
  # Prompt cache: "warm" or "cold", empty until caching was observed.
  "pc_state=\(.prompt_cache // null | select(.caching_observed == true)
    | if .warm == true and .expires_at != null then "warm" else "cold" end | s)",
  "pc_expires=\(.prompt_cache.expires_at | s)",
  "pc_ttl=\(.prompt_cache.ttl | s)"
' 2>/dev/null)"
rl_sid=${rl_sid//[!A-Za-z0-9._-]/_}

# /rename fires no hook, so pass its title to the tmux session from here.
if [ -n "$TMUX_PANE" ] && [ -f "$transcript" ]; then
  custom_title=$(rg -F '"type":"custom-title"' "$transcript" 2>/dev/null | tail -n 1 | jq -r '.customTitle // empty' 2>/dev/null)
  [ -n "$custom_title" ] && sh ~/.claude/hooks/agent-tmux-session.sh sync "$custom_title" </dev/null >/dev/null 2>&1 &
fi

# --- Git branch ---
[ -z "$cwd" ] && cwd="$PWD"
git_info=""
git_root_name=""
git_top=""
repo_url=""
# Absolute git-dir and common dir in one call. --git-common-dir points at the
# main repo's .git even from a linked worktree or a submodule whose gitdir
# lives elsewhere; the two match only in the main checkout.
if cd "$cwd" 2>/dev/null &&
  git_dirs=$(git --no-optional-locks rev-parse --path-format=absolute --git-dir --git-common-dir 2>/dev/null); then
  git_dir=${git_dirs%%$'\n'*}
  common_dir=${git_dirs#*$'\n'}
  git_top=$(git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  branch=$(git --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch="detached"
  git_info="$branch"

  # Name the repository, not the checkout, so worktrees report the parent repo
  # instead of ".worktrees/<x>".
  if [ -n "$common_dir" ]; then
    if [ "$(basename "$common_dir")" = ".git" ]; then
      git_root_name=$(basename "$(cd "$common_dir/.." 2>/dev/null && pwd -P)")
    else
      # Bare repo: the gitdir itself is the project (e.g. "web-player.git").
      git_root_name=$(basename "$common_dir" .git)
    fi
  fi

  # Web page of the origin remote, else the first remote. Raw config skips
  # insteadOf rewrites, which often turn https into ssh. SSH and git URLs map to
  # https without their port; credentials are dropped; local paths give none.
  repo_url=$(git --no-optional-locks config --get-regexp '^remote\..*\.url$' 2>/dev/null |
    awk '$1 == "remote.origin.url" { u = $2; exit } !u { u = $2 } END { print u }' |
    sed -E -e 's#^(git\+)?ssh://([^@/]*@)?([^:/]+)(:[0-9]*)?/#https://\3/#' \
      -e 's#^git://([^/]+)/#https://\1/#' \
      -e '\#://#!s#^([^/:@]+@)?([^/:]+):/?#https://\2/#' \
      -e 's#^(https?://)[^@/]*@#\1#' \
      -e 's#(\.git)?/*$##' \
      -e '\#^https?://[^/]+/.#!d')

  # Claude often works in a linked worktree by absolute path while the session
  # stays in the main checkout. From the main checkout, show the branch of the
  # worktree its tool calls named most recently instead.
  if [ -f "$transcript" ] && [ "$git_dir" = "$common_dir" ]; then
    wt_list=$(git --no-optional-locks worktree list --porcelain 2>/dev/null | awk '
      /^worktree / { if (n++) path = substr($0, 10); else path = "" }
      /^branch / && path != "" { sub("refs/heads/", "", $2); print path "\t" $2 }
      /^detached/ && path != "" { print path "\tdetached" }
    ')
    if [ -n "$wt_list" ]; then
      wt_hit=$(tail -n 2000 "$transcript" | rg -F '"tool_use"' | jq -rR '
        fromjson? | select(.type == "assistant") | .message.content[]?
        | select(.type == "tool_use") | .input | tostring | gsub("[\t\n]"; " ")
      ' 2>/dev/null | WT_LIST="$wt_list" awk -F '\t' '
        BEGIN { n = split(ENVIRON["WT_LIST"], rows, "\n"); for (i = 1; i <= n; i++) { split(rows[i], f, "\t"); p[i] = f[1]; b[i] = f[2] } }
        {
          # Longest path wins, so ".worktrees/a" never matches inside ".worktrees/ab".
          # Every occurrence is checked: ".worktrees/ab-old" may come before ".worktrees/a/".
          best = 0
          for (i = 1; i <= n; i++) {
            if (best && length(p[i]) <= length(p[best])) continue
            s = $0
            while ((j = index(s, p[i])) > 0) {
              if (substr(s, j + length(p[i]), 1) !~ /[A-Za-z0-9._-]/) { best = i; break }
              s = substr(s, j + 1)
            }
          }
          if (best) last = p[best] "\t" b[best]
        }
        END { if (last != "") print last }
      ')
      if [ -n "$wt_hit" ]; then
        git_top=${wt_hit%%$'\t'*}
        git_info=${wt_hit#*$'\t'}
      fi
    fi
  fi

  # Hide the default branch; a bare project name means "on the default branch".
  # Without a remote HEAD, fall back to the common default names.
  default_branch=$(git --no-optional-locks symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
  default_branch="${default_branch#origin/}"
  if [ -n "$default_branch" ]; then
    [ "$git_info" = "$default_branch" ] && git_info=""
  else
    case "$git_info" in master | main | develop | dev) git_info="" ;; esac
  fi
fi

# --- Model name (shorten to S/O/H + version) ---
[ -z "$model_raw" ] || [ "$model_raw" = "null" ] && model_raw="Claude"

# Extract version number from display name or model id
# Display name examples: "Claude Sonnet 4.6", "Claude Opus 4.8", "Claude Haiku 3.5"
# Model id examples: "claude-sonnet-4-6", "claude-opus-4", "claude-haiku-3-5"
# The [1m] flag and a date suffix ("claude-sonnet-4-20250514") are dropped
# first, so the date never reads as a minor version.
ver_id=${model_id%\[*\]}
[[ $ver_id =~ ^(.*)-[0-9]{8}$ ]] && ver_id=${BASH_REMATCH[1]}
model=""
case "$model_raw" in
  *[Ss]onnet*)
    ver=$(echo "$model_raw" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_raw" | grep -oE '[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$ver_id" | grep -oE '[0-9]+-[0-9]+' | head -1 | tr '-' '.')
    [ -z "$ver" ] && ver=$(echo "$ver_id" | grep -oE '[0-9]+' | head -1)
    model="S${ver}"
    ;;
  *[Oo]pus*)
    ver=$(echo "$model_raw" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_raw" | grep -oE '[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$ver_id" | grep -oE '[0-9]+-[0-9]+' | head -1 | tr '-' '.')
    [ -z "$ver" ] && ver=$(echo "$ver_id" | grep -oE '[0-9]+' | head -1)
    model="O${ver}"
    ;;
  *[Hh]aiku*)
    ver=$(echo "$model_raw" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_raw" | grep -oE '[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$ver_id" | grep -oE '[0-9]+-[0-9]+' | head -1 | tr '-' '.')
    [ -z "$ver" ] && ver=$(echo "$ver_id" | grep -oE '[0-9]+' | head -1)
    model="H${ver}"
    ;;
  *[Ff]able*)
    ver=$(echo "$model_raw" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_raw" | grep -oE '[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$ver_id" | grep -oE '[0-9]+' | head -1)
    model="F${ver}"
    ;;
  *)
    # Fallback: strip "Claude " prefix, collapse whitespace
    model=$(echo "$model_raw" | sed -E 's/^Claude[[:space:]]+//' | sed -E 's/[[:space:]]+/ /g')
    ;;
esac

# --- Effort level (single letter; capital X for max, beside x for xhigh) ---
effort=""
case "$effort_raw" in
  low|LOW|Low)       effort="l" ;;
  medium|MEDIUM|Medium|med) effort="m" ;;
  high|HIGH|High)    effort="h" ;;
  xhigh|XHIGH|xHigh|XHigh|extreme) effort="x" ;;
  max|MAX|Max)       effort="X" ;;
  "")                effort="" ;;
  *)                 effort=$(echo "$effort_raw" | cut -c1 | tr '[:upper:]' '[:lower:]') ;;
esac

# --- Rate limits (each window: countdown to reset, then usage %) ---
# Claude Code sends rate_limits only after a session's first API response, and
# an idle session keeps resending its last copy. Limits are per account, so all
# sessions share a cache of the newest value per window. Within one window usage
# only grows, so the higher value is newer and a late or repeated copy can't
# replace it. The exception is a real drop (e.g. a plan upgrade): a session
# that sees its own value fall, per its file of what it last saw, overrides the
# cache, and sessions resending an unchanged copy don't restore the old value.
rl_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
rl_key=$(printf '%s' "${account:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}" | tr -c 'A-Za-z0-9._@-' '_')
rl_cache="$rl_dir/rate-limits-$rl_key.json"
rl_lock="$rl_dir/rate-limits-$rl_key.lock"
rl_prev_file=""
[ -n "$rl_sid" ] && rl_prev_file="$rl_dir/session-$rl_sid.json"
rl_locked=""
rl_takeover=""
port_lock=""
rl_tmp=""
# Claude Code cancels a running script when a new update fires; don't leave
# temp files or a held lock behind.
trap 'rm -f "$rl_tmp"; [ -n "$rl_locked" ] && rmdir "$rl_lock" 2>/dev/null
  [ -n "$rl_takeover" ] && rmdir "$rl_lock.takeover" 2>/dev/null
  [ -n "$port_lock" ] && rmdir "$port_lock" 2>/dev/null' EXIT
trap 'exit 1' HUP INT TERM

# Atomic write so concurrent readers never see a partial file.
rl_write() {
  rl_tmp=$(mktemp "$1.XXXXXX" 2>/dev/null) || return 1
  printf '%s\n' "$2" > "$rl_tmp" && mv -f "$rl_tmp" "$1" || return 1
  rl_tmp=""
}

# Hold the lock across read, merge and write so sessions don't drop each
# other's updates. Without it, display the merge, write nothing, and retry on
# the next run.
mkdir -p "$rl_dir" 2>/dev/null
if mkdir "$rl_lock" 2>/dev/null; then
  rl_locked=1
else
  rl_lock_mtime=$(stat -c %Y "$rl_lock" 2>/dev/null || stat -f %m "$rl_lock" 2>/dev/null)
  case $rl_lock_mtime in
    '' | *[!0-9]*) ;;
    *)
      # A lock older than 10 s belongs to a killed run. Only the run holding
      # the .takeover lock MAY remove it, after checking its age again, so two
      # runs that both saw it stale never each remove one and both hold it.
      if [ $(($(date +%s) - rl_lock_mtime)) -gt 10 ]; then
        if mkdir "$rl_lock.takeover" 2>/dev/null; then
          rl_takeover=1
          rl_lock_mtime=$(stat -c %Y "$rl_lock" 2>/dev/null || stat -f %m "$rl_lock" 2>/dev/null)
          case $rl_lock_mtime in '' | *[!0-9]*) rl_lock_mtime=0 ;; esac
          if [ $(($(date +%s) - rl_lock_mtime)) -gt 10 ]; then
            rmdir "$rl_lock" 2>/dev/null
            mkdir "$rl_lock" 2>/dev/null && rl_locked=1
          fi
          rmdir "$rl_lock.takeover" 2>/dev/null
          rl_takeover=""
        else
          # A .takeover lock this old belongs to a killed run; the next run
          # retries the takeover.
          rl_to_mtime=$(stat -c %Y "$rl_lock.takeover" 2>/dev/null || stat -f %m "$rl_lock.takeover" 2>/dev/null)
          case $rl_to_mtime in
            '' | *[!0-9]*) ;;
            *) [ $(($(date +%s) - rl_to_mtime)) -gt 10 ] && rmdir "$rl_lock.takeover" 2>/dev/null ;;
          esac
        fi
      fi
      ;;
  esac
fi

rl_cached=$(jq -cs '.[0] // null' "$rl_cache" 2>/dev/null)
rl_prev=""
[ -n "$rl_prev_file" ] && rl_prev=$(jq -cs '.[0] // null' "$rl_prev_file" 2>/dev/null)
# Values this session has no live copy of come from the cache and are dimmed.
rl_cache_json="" rl_live_json="" five_hr="" five_hour_reset="" five_hour_dim=""
seven_day="" seven_day_reset="" seven_day_dim="" spend_pct="" spend_reset=""
spend_used="" spend_cap="" spend_dim=""
eval "$(jq -nrS --argjson now "$now" --argjson live "${rl_live:-null}" \
  --argjson cache "${rl_cached:-null}" --argjson prev "${rl_prev:-null}" '
  def fresh: type == "object" and (.resets_at | type) == "number" and .resets_at > $now;
  def clean: if type == "object" then with_entries(select(.value | fresh)) else {} end;
  # resets_at can jitter between responses for the same window.
  def same(x; y): ((x.resets_at - y.resets_at) | if . < 0 then -. else . end) < 600;
  def newer(x; y):
    if y == null then x
    elif same(x; y) then (if x.used_percentage >= y.used_percentage then x else y end)
    elif x.resets_at > y.resets_at then x
    else y end;
  ($live | clean) as $l
  | ($prev | clean) as $p
  | ($cache | clean) as $c
  | reduce (($l | keys) + ($c | keys) | unique)[] as $k ({};
      $l[$k] as $mine | $p[$k] as $old | $c[$k] as $cached
      | .[$k] =
        if $mine == null then $cached
        # spend_limit reports the fullest limit, whose period can change, so a
        # live value always wins over a cached one that resets later.
        elif $k == "spend_limit" then $mine
        elif $mine == $old then ($cached // $mine)
        elif $old != null and same($mine; $old) and $mine.used_percentage < $old.used_percentage then $mine
        else newer($mine; $cached) end)
  | def s: if . == null then "" else tostring end | @sh;
  "rl_cache_json=\(if . != $cache then tojson else null end | s)",
  "rl_live_json=\(if $l != $prev then $l | tojson else null end | s)",
  "five_hr=\(.five_hour.used_percentage | s)",
  "five_hour_reset=\(.five_hour.resets_at | s)",
  "five_hour_dim=\(if $l.five_hour then "" else "2;" end | s)",
  "seven_day=\(.seven_day.used_percentage | s)",
  "seven_day_reset=\(.seven_day.resets_at | s)",
  "seven_day_dim=\(if $l.seven_day then "" else "2;" end | s)",
  "spend_pct=\(.spend_limit.used_percentage | s)",
  "spend_reset=\(.spend_limit.resets_at | s)",
  "spend_used=\(.spend_limit.used_usd | s)",
  "spend_cap=\(.spend_limit.limit_usd | s)",
  "spend_dim=\(if $l.spend_limit then "" else "2;" end | s)"
' 2>/dev/null)"

if [ -n "$rl_locked" ]; then
  if [ -z "$rl_cache_json" ] || rl_write "$rl_cache" "$rl_cache_json"; then
    # Record what this session saw only once the cache holds it.
    if [ -n "$rl_prev_file" ] && [ -n "$rl_live_json" ]; then
      rl_write "$rl_prev_file" "$rl_live_json"
    fi
  fi
  # Session files last past every window they hold (7 days at most); temp
  # files are left only by runs killed outright.
  find "$rl_dir" -type f \( -name 'session-*.json' -mtime +8 -o -name 'session-*.port' -mtime +8 \
    -o -name '*.json.*' -mmin +60 -o -name 'servers-*' -mmin +60 \) -delete 2>/dev/null
  rmdir "$rl_lock" 2>/dev/null
  rl_locked=""
fi

# --- Color picker for a used% value ---
# green <65, yellow 65-79, red >=80
color_for_pct() {
  local used=$1
  if [ "$used" -ge 80 ]; then printf '31'
  elif [ "$used" -ge 65 ]; then printf '33'
  else printf '32'
  fi
}

# --- Format a reset timestamp as a short countdown from now ---
# Shows only the largest unit, rounded down to one decimal so it never
# overstates the time left: "6.5d", "4.2h", "45m". Under 10 minutes it shows
# seconds too: "5m27s", "0m05s". The unit sets the hue (days violet, hours
# teal, minutes blue).
countdown_str() {
  awk -v r="$1" -v n="$(date +%s)" -v dim="$rl_dim" '
  function part(v, u, c) {
    v = sprintf("%.1f", int(v * 10) / 10)
    sub(/\.0$/, "", v)
    return c v u "\033[0m"
  }
  BEGIN{
    DAYS = "\033[" dim "38;5;141m"; HOURS = "\033[" dim "38;5;43m"; MINS = "\033[" dim "38;5;111m"
    d = r - n
    if (d < 0) d = 0
    if (d >= 86400)     out = part(d / 86400, "d", DAYS)
    else if (d >= 3600) out = part(d / 3600, "h", HOURS)
    else if (d >= 600)  out = MINS int(d / 60) "m\033[0m"
    else                out = MINS sprintf("%dm%02ds", int(d / 60), d % 60) "\033[0m"
    printf "%s", out
  }'
}

# --- Draw a usage gauge: "▕<bar>▏ <pct>% <gap>[→<time>|+<time>]" ---
# $1 = used percentage, $2 = reset epoch, $3 = window length and $4 = budget
# step, in seconds, $5 = pace colour from rate_seg. The bar has 56 cells, two
# per 7-day budget step; fill is drawn in eighths of a cell. The bar marks the
# same zones rate_seg colours by: up to one step's share past the budget is
# fine, the next step's share is yellow, and beyond that is red. Fill takes the
# colour of the zone holding most of its cell's fill; a full bar is all red.
# Unfilled cells show "▒" up to where an even pace would put usage now (budget
# still free at this pace), then "░" tinted by zone, so the track shows how far
# ahead turns yellow or red right now. Each unfilled cell takes the zone of its
# middle. The gap is usage minus pace in points: "↑12" in the pace colour when
# ahead, "↓8" grey when behind, "↕0" grey on pace. Once the pace colour is
# yellow or red and the bar is not full, "→<time>" estimates when usage reaches
# 100% at the window's average rate so far; running ahead of pace always gets
# there before the reset. Behind pace, "+<time>" is the spare time: how long
# usage could stay flat before pace catches up.
pace_gauge() {
  awk -v p="$1" -v r="$2" -v n="$now" -v w="$3" -v t="$4" -v c="$5" -v dim="$rl_dim" '
  # Seconds as the largest unit, rounded down to one decimal: "1.4d", "15h", "9m".
  function dur(s) {
    if (s >= 86400) return int(s / 8640) / 10 "d"
    if (s >= 3600)  return int(s / 360) / 10 "h"
    return int(s / 60) "m"
  }
  # Zone colour at x percent of the limit: 0 within budget, else yellow or red.
  function zone(x) { return x > red ? 31 : x > yellow ? 33 : 0 }
  BEGIN {
    split("▏ ▎ ▍ ▌ ▋ ▊ ▉ █", g, " ")
    N = 56; cw = 100 / N
    pre = "\033[" dim
    e = w - (r - n)
    if (e < 0) e = 0
    if (e > w) e = w
    pace = 100 * e / w
    # Same budget as rate_seg: counted to the start of the current step.
    s = 100 * t / w
    b = int((e >= w ? w - 1 : e) / t) * s
    yellow = b + s; red = b + 2 * s
    u = int(p * N * 8 / 100 + 0.5)
    # Full once the shown percentage reads 100.
    if (u > N * 8 || p >= 99.5) u = N * 8
    full = u == N * 8
    if (full) c = 31
    out = pre "38;5;245m▕"
    for (i = 0; i < N; i++) {
      q = u - 8 * i
      if (q > 8) q = 8
      if (q > 0) {
        z = full ? 31 : zone(cw * i + cw * q / 16)
        out = out pre (z ? z : 32) "m" g[q]
        continue
      }
      x = cw * (i + 0.5)
      if (x < pace) { out = out pre "38;5;245m▒"; continue }
      z = zone(x)
      out = out pre (z == 31 ? "38;5;124" : z == 33 ? "38;5;136" : "38;5;240") "m░"
    }
    out = out pre "38;5;245m▏\033[0m"
    d = p - pace
    d = d < 0 ? -int(-d + 0.5) : int(d + 0.5)
    # Percentage and gap are right-aligned ("  5%", " ↓9") so stacked gauges
    # line up their numbers and the times after them.
    ad = d < 0 ? -d : d
    gap = (ad < 10 ? " " : "") (d > 0 ? pre c "m↑" d : pre "38;5;245m" (d < 0 ? "↓" ad : "↕0"))
    if (c != 32 && p > 0 && !full && e > 0) gap = gap "→" dur((100 - p) * e / p)
    if (d < 0) gap = gap "+" dur((pace - p) * w / 100)
    printf "%s %s%sm%3d%%\033[0m %s\033[0m", out, pre, c, int(p + 0.5), gap
  }'
}

# --- Build an unlabeled rate-limit segment ---
# $1 = reset epoch (may be empty), $2 = used percentage (may be empty),
# $3 = window length and $4 = budget step, in seconds (may be empty)
# With a window, step, and reset it reads "<countdown> <gauge>" (see pace_gauge);
# otherwise "<countdown>:<pct>%". The countdown colours itself per unit. With a
# window, step, and reset, the percentage is coloured by an even budget across
# the window (1/7 a day for 7 days, 1/5 an hour for 5 hours), counted to the
# start of the current step:
# yellow once usage runs more than one step's share ahead of it, red once more
# than two, or at 100%. Otherwise color_for_pct colours it. Elsewhere yellow
# and red mark only usage warnings and an expiring prompt cache.
rate_seg() {
  local reset=$1 pct=$2 window=$3 step=$4 seg="" p c vis
  if [ -n "$reset" ] && [ "$reset" != "null" ]; then
    seg=$(countdown_str "$reset")
  fi
  if [ -n "$pct" ]; then
    p=$(printf '%.0f' "$pct")
    if [ -n "$window" ] && [ -n "$step" ] && [ -n "$seg" ]; then
      c=$(awk -v p="$pct" -v r="$reset" -v n="$now" -v w="$window" -v t="$step" 'BEGIN {
        e = w - (r - n)
        if (e < 0) e = 0
        if (e >= w) e = w - 1
        s = 100 * t / w
        b = int(e / t) * s
        print (p >= 100 || p > b + 2 * s ? 31 : p > b + s ? 33 : 32)
      }')
      # Right-align the countdown to its widest form ("23.9h") so stacked bars
      # line up.
      vis=$(printf '%s' "$seg" | sed $'s/\033\\[[0-9;]*m//g')
      seg="$(printf '%*s' $((5 - ${#vis})) '')$seg $(pace_gauge "$pct" "$reset" "$window" "$step" "$c")"
    elif [ -n "$seg" ]; then
      c=$(color_for_pct "$p")
      seg=$(printf '%s\033[%s38;5;245m:\033[0m\033[%s%sm%d%%\033[0m' "$seg" "$rl_dim" "$rl_dim" "$c" "$p")
    else
      c=$(color_for_pct "$p")
      seg=$(printf '\033[%s%sm%d%%\033[0m' "$rl_dim" "$c" "$p")
    fi
  fi
  printf '%s' "$seg"
}

case $ctx_used_tokens in *[!0-9]*) ctx_used_tokens="" ;; esac

# Auto-compact window from user settings.json: modelSettings.<model>
# .autoCompactWindow replaces the top-level value. Model ids and settings keys
# both drop the [1m] flag and any date suffix before matching, as Claude Code
# does. Project settings are not read; "auto" means no fixed window. Output is
# "<effective window>\t<top-level window>"; the second is the usual one.
settings_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
compact_windows=$(jq -r --arg m "$model_id" '
  def canon: sub("\\[[^]]*\\]$"; "") | sub("-[0-9]{8}$"; "");
  def fixed: if . == "auto" or . == null then "" else tostring end;
  ($m | canon) as $k
  # An exactly canonical key wins over a [1m] or dated spelling of it.
  | ([(.modelSettings // {}) | to_entries | sort_by((.key | canon) != .key)[]
      | select((.key | canon) == $k)
      | .value.autoCompactWindow | select(. != null)] | first) as $model
  | "\($model // .autoCompactWindow | fixed)\t\(.autoCompactWindow | fixed)"
' "$settings_dir/settings.json" 2>/dev/null)
compact_window=${compact_windows%%$'\t'*}
usual_window=${compact_windows#*$'\t'}
# Claude Code accepts 100k to 1M; anything else is ignored here too.
case $compact_window in *[!0-9]* | '') compact_window="" ;; esac
if [ -n "$compact_window" ] && { [ "$compact_window" -lt 100000 ] || [ "$compact_window" -gt 1000000 ]; }; then
  compact_window=""
fi
if [ -n "$compact_window" ] && [ -n "$ctx_total" ] && [ "$ctx_total" != "null" ] &&
  [ "$ctx_total" -lt "$compact_window" ] 2>/dev/null; then
  compact_window=$ctx_total
fi

# Claude Code compacts 33k below the window: it reserves 20k for output, then
# keeps a 13k buffer.
compact_at=""
[ -n "$compact_window" ] && compact_at=$((compact_window - 33000))
# A window of 33k or less leaves no compaction point; measure against the
# context window instead.
if [ -n "$compact_at" ] && [ "$compact_at" -le 0 ]; then
  compact_at=""
  compact_window=""
fi

# Usage is measured against the compaction point when a window is set, since
# that is the real ceiling; otherwise against the model's context window.
ctx_used_pct=""
if [ -n "$compact_at" ] && [ -n "$ctx_used_tokens" ]; then
  ctx_used_pct=$(awk -v u="$ctx_used_tokens" -v w="$compact_at" 'BEGIN{printf "%d", u * 100 / w + 0.5}')
elif [ -n "$ctx_remaining" ]; then
  ctx_used_pct=$(awk -v r="$ctx_remaining" 'BEGIN{printf "%d", 100 - r + 0.5}')
fi

# Short token count: "312k", "1.2M".
fmt_tokens() {
  awk -v t="$1" 'BEGIN{
    if (t >= 1000000) { v = sprintf("%.1f", t / 1000000); sub(/\.0$/, "", v); printf "%sM", v }
    else printf "%dk", int(t / 1000 + 0.5)
  }'
}

# 1M detection: explicit total >250k, OR model id/name contains 1m / 1M
is_1m=0
if [ -n "$ctx_total" ] && [ "$ctx_total" != "null" ]; then
  if awk -v t="$ctx_total" 'BEGIN{exit !(t+0 > 250000)}'; then
    is_1m=1
  fi
fi
if [ $is_1m -eq 0 ]; then
  case "$model_id$model_raw" in
    # Opus/Sonnet carry an explicit [1m] beta flag; Fable is natively 1M.
    *1m*|*1M*|*[Ff]able*) is_1m=1 ;;
  esac
fi

# --- Context window label: window size instead of generic "ctx" ---
# Prefer reported capacity; model-based defaults apply only when capacity is absent.
if [ -n "$compact_at" ] && [ -n "$ctx_used_tokens" ]; then
  # The usual compaction point (the top-level setting) goes unlabelled; only a
  # session that differs shows its size.
  ctx_label=""
  [ "$compact_window" = "$usual_window" ] || ctx_label=$(fmt_tokens "$compact_at")
elif [ -n "$ctx_total" ] && [ "$ctx_total" != "null" ]; then
  ctx_label=$(awk -v t="$ctx_total" 'BEGIN{
    if (t+0 >= 1000000) printf "%gM", t/1000000; else printf "%dk", int(t/1000 + 0.5)
  }')
elif [ $is_1m -eq 1 ]; then
  ctx_label="1M"
else
  ctx_label="200k"
fi

# --- Build output ---
# Segments are joined by an unpadded dim bar; colour, not whitespace, keeps the
# fields apart, which keeps the line short on narrow terminals.
sep=$(printf '\033[38;5;245m|\033[0m')

# Dev servers (magenta): TCP listeners this session started. Claude Code starts
# this script with its own environment, so $PORT never carries them. A
# listener belongs to the session when its environment holds this session's
# CLAUDE_CODE_SESSION_ID, it descends from the session's Claude process, or it
# runs in the session's scratch space. Servers that retitle themselves
# (http-server does) hide their environment from ps; such a server also counts
# when it runs in the checkout this line shows (not $HOME). The segment always
# shows the machine's LAN IPv4 address, joined by the session's port when it
# has one ("192.168.73.7:43750").
# Detection takes ~250 ms, so each session reuses its result for 5 s.
# The segment holds the markers "@IP@" and "@.IP@" for the address; the last
# step fills them with the full address, or only its last octet when the line
# would not fit the terminal.
lan_ip() {
  local iface host=""
  iface=$(route -n get default 2>/dev/null | awk '/interface:/ { print $2 }')
  [ -n "$iface" ] && host=$(ipconfig getifaddr "$iface" 2>/dev/null)
  # A VPN's utun default route often has no IPv4 address; use the first
  # Ethernet or Wi-Fi interface that has one.
  if [ -z "$host" ]; then
    for iface in $(ifconfig -l 2>/dev/null); do
      case $iface in en*) host=$(ipconfig getifaddr "$iface" 2>/dev/null) && [ -n "$host" ] && break ;; esac
    done
  fi
  [ -z "$host" ] && host=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{ for (i = 1; i < NF; i++) if ($i == "src") { print $(i + 1); exit } }')
  printf '%s' "$host"
}
srv_detect() {
  local listen pids cwds titles procs rows ports host assigned shown row
  host=$(lan_ip)
  # The first output line is the address; the segment follows.
  printf '%s\n' "$host"
  listen=$(lsof -nP -iTCP -sTCP:LISTEN -Fpn 2>/dev/null | awk '
    /^p/ { p = substr($0, 2) } /^n/ { print p "\t" substr($0, 2) }
  ')
  [ -n "$listen" ] || ports=""
  [ -n "$listen" ] && {
  pids=$(printf '%s\n' "$listen" | cut -f1 | sort -u | paste -sd, -)
  cwds=$(lsof -a -d cwd -p "$pids" -Fpn 2>/dev/null | awk '
    /^p/ { p = substr($0, 2) } /^n/ { print p "\t" substr($0, 2) }
  ')
  # "<pid>\t<title>\t<1 if its environment holds this session's id>\t<1 if ps
  # shows any environment>". Node daemons retitle themselves, so lsof reports
  # "node"; ps shows the title.
  titles=$({ ps -E -ww -o pid=,command= -p "$pids" 2>/dev/null ||
    ps e -ww -o pid=,command= -p "$pids" 2>/dev/null; } |
    awk -v s="CLAUDE_CODE_SESSION_ID=$rl_sid" '{
      n = split($2, a, "/"); i = index($0, s)
      print $1 "\t" a[n] "\t" (i && substr($0, i + length(s), 1) !~ /[^ ]/) "\t" (index($0, " PATH=") > 0)
    }')
  procs=$(ps -A -o pid=,ppid=,comm= 2>/dev/null)
  # Rows: "<port>\t<1 if reachable from the LAN>\t<cwd to confirm>". The cwd
  # is set only for a hidden-environment server matched by folder; it counts
  # only when its own checkout is this one, not a worktree nested inside it.
  # A hidden-environment server on a port in the session's reserved block
  # counts as the session's wherever it runs.
  assigned=$srv_port
  rows=$(printf '%s\n' "$listen" | SRV_CWDS="$cwds" SRV_TITLES="$titles" SRV_TOP="$git_top" \
    SRV_BLOCK="$assigned" SRV_PROCS="$procs" SRV_SELF="$$" SRV_SID="$rl_sid" awk -F '\t' '
    BEGIN {
      n = split(ENVIRON["SRV_CWDS"], rows, "\n")
      for (i = 1; i <= n; i++) { split(rows[i], f, "\t"); dir[f[1]] = f[2] }
      n = split(ENVIRON["SRV_TITLES"], rows, "\n")
      for (i = 1; i <= n; i++) { split(rows[i], f, "\t"); title[f[1]] = f[2]; mine[f[1]] = f[3]; env[f[1]] = f[4] }
      top = ENVIRON["SRV_TOP"]
      if (top == ENVIRON["HOME"]) top = ""
      n = split(ENVIRON["SRV_PROCS"], rows, "\n")
      for (i = 1; i <= n; i++) {
        split(rows[i], f, " "); parent[f[1]] = f[2]
        c = rows[i]; sub(/^ *[0-9]+ +[0-9]+ +/, "", c); sub(/.*\//, "", c); comm[f[1]] = c
      }
      # The nearest "claude" ancestor of this script is the session process.
      for (p = ENVIRON["SRV_SELF"]; p > 1 && comm[p] != "claude"; p = parent[p]) ;
      claude = (p > 1) ? p : ""
      sid = ENVIRON["SRV_SID"]
      block = ENVIRON["SRV_BLOCK"]
    }
    # Editor daemons may start from a session but are not servers.
    title[$1] ~ /^(eslint_d|prettierd|biome)$/ { next }
    {
      addr = $2; port = addr; sub(/.*:/, "", port); host = substr(addr, 1, length(addr) - length(port) - 1)
      hit = mine[$1] == 1 || index(dir[$1], "/" sid "/")
      if (!hit && claude != "") for (p = parent[$1]; p > 1; p = parent[p]) if (p == claude) { hit = 1; break }
      if (!hit && env[$1] != 1 && block != "" && port + 0 >= block + 0 && port + 0 <= block + 9) hit = 1
      check = ""
      d = dir[$1]
      if (!hit && env[$1] != 1 && top != "" && (d == top || index(d, top "/") == 1)) check = d
      if (!hit && check == "") next
      print port "\t" (host !~ /^(127\.|\[::1\]|localhost)/) "\t" check
    }
  ')
  # Output: "<port>\t<1 if reachable from the LAN>", LAN servers first, then by port.
  ports=$(printf '%s\n' "$rows" | while IFS=$'\t' read -r port lan check; do
    [ -n "$port" ] || continue
    [ -z "$check" ] || [ "$(git -C "$check" rev-parse --show-toplevel 2>/dev/null)" = "$git_top" ] || continue
    printf '%s\t%s\n' "$port" "$lan"
  done | awk -F '\t' '
    { if (!($1 in seen) || $2) seen[$1] = $2 }
    END { for (p in seen) print p "\t" seen[p] }
  ' | sort -t $'\t' -k2,2nr -k1,1n)
  }
  # The shown port is the one the session-port hook assigned, else the first
  # server found. It is dim while nothing listens on it.
  shown=$assigned
  row=""
  if [ -n "$assigned" ]; then
    row=$(printf '%s\n' "$ports" | awk -F '\t' -v p="$assigned" '$1 == p')
  elif [ -n "$ports" ]; then
    row=${ports%%$'\n'*}
    shown=${row%%$'\t'*}
  fi
  if [ -z "$shown" ]; then
    [ -n "$host" ] && printf '\033[35m@.IP@\033[0m'
    return 0
  fi
  # A process outside the session on the assigned port (one whose visible
  # environment lacks this session's id) is a conflict: the port shows red,
  # and the .conflict file makes session-port.sh pick a new block on resume.
  # The file goes once the port is the session's again or free.
  if [ -n "$row" ]; then
    srv_link "$shown" "${row##*$'\t'}" "35" "@IP@:$shown"
    rm -f "$rl_dir/port-$rl_sid.conflict"
  elif [ -n "$assigned" ] && printf '%s\n' "$listen" | awk -F '\t' -v p="$assigned" '
    { sub(/.*:/, "", $2) } $2 == p { found = 1 } END { exit !found }'; then
    printf '\033[31m@IP@:%s\033[0m' "$shown"
    : > "$rl_dir/port-$rl_sid.conflict"
  else
    printf '\033[2;35m@IP@:%s\033[0m' "$shown"
    rm -f "$rl_dir/port-$rl_sid.conflict"
  fi
  return 0
}
# OSC 8 link: $1 = port, $2 = 1 if reachable from the LAN, $3 = SGR colour,
# $4 = text. BEL ends each escape because the final printf '%b' would read a
# "\" terminator as the start of an escape.
srv_link() {
  local url_host=localhost
  [ "$2" = 1 ] && [ -n "$host" ] && url_host=$host
  printf '\033]8;;http://%s:%s\a\033[%sm%s\033[0m\033]8;;\a' "$url_host" "$1" "$3" "$4"
}
srv_seg=""
srv_ip=""
if [ -z "$rl_sid" ]; then
  srv_ip=$(lan_ip)
  [ -n "$srv_ip" ] && srv_seg=$(printf '\033[35m@.IP@\033[0m')
else
  srv_cache="$rl_dir/servers-ip-$rl_sid"
  srv_mtime=$(stat -c %Y "$srv_cache" 2>/dev/null || stat -f %m "$srv_cache" 2>/dev/null)
  case $srv_mtime in '' | *[!0-9]*) srv_mtime=0 ;; esac
  if [ $((now - srv_mtime)) -lt 5 ]; then
    srv_out=$(cat "$srv_cache" 2>/dev/null)
  else
    # session-port.sh releases a block whose port file is untouched for an
    # hour once the recorded cache expiry has passed, and this script's
    # environment lacks $PORT. So the session's port is also kept in
    # session-<sid>.port, and a released port file is written back from it
    # while no other session's file holds the block; the session's exported
    # PORT never changes.
    srv_port_file="$rl_dir/port-$rl_sid"
    srv_known_file="$rl_dir/session-$rl_sid.port"
    srv_port=""
    srv_known=""
    { read -r srv_port < "$srv_port_file"; } 2>/dev/null
    { read -r srv_known < "$srv_known_file"; } 2>/dev/null
    case $srv_port in *[!0-9]*) srv_port="" ;; esac
    case $srv_known in *[!0-9]* | '') srv_known=0 ;; esac
    if [ -n "$srv_port" ]; then
      [ "$srv_port" = "$srv_known" ] || printf '%s\n' "$srv_port" > "$srv_known_file"
    elif [ "$srv_known" -ge 40000 ] && [ "$srv_known" -le 48990 ] && [ $(((srv_known - 40000) % 10)) -eq 0 ] &&
      mkdir "$rl_dir/port.lock" 2>/dev/null; then
      port_lock="$rl_dir/port.lock"
      srv_held=""
      for srv_f in "$rl_dir"/port-*; do
        case $srv_f in "$srv_port_file" | *.conflict | *.until) continue ;; esac
        srv_p=""
        { read -r srv_p < "$srv_f"; } 2>/dev/null
        case $srv_p in '' | *[!0-9]*) continue ;; esac
        [ "$srv_p" -ge 40000 ] && [ "$srv_p" -le 48999 ] &&
          [ $(((srv_p - 40000) / 10)) -eq $(((srv_known - 40000) / 10)) ] && srv_held=1 && break
      done
      if [ -z "$srv_held" ]; then
        printf '%s\n' "$srv_known" > "$srv_port_file" && srv_port=$srv_known
      fi
      rmdir "$port_lock" 2>/dev/null
      port_lock=""
    fi
    srv_out=$(srv_detect)
    rl_write "$srv_cache" "$srv_out"
    touch -c "$srv_port_file" "$srv_known_file"
  fi
  srv_ip=${srv_out%%$'\n'*}
  [ "$srv_out" = "$srv_ip" ] || srv_seg=${srv_out#*$'\n'}
fi

# The account (grey) leads the first line and links to claude.ai.
who_seg=""
[ -n "$account_name" ] && who_seg=$(printf '\033]8;;https://claude.ai\a\033[38;5;247m%s\033[0m\033]8;;\a' "$account_name")

# Model + effort (blue then magenta, no joiner — the colour change separates
# them): "O5.5m".
if [ -n "$effort" ]; then
  model_seg=$(printf '\033[34m%s\033[0m\033[35m%s\033[0m' "$model" "$effort")
else
  model_seg=$(printf '\033[34m%s\033[0m' "$model")
fi
parts="$model_seg"
[ -n "$srv_seg" ] && parts="$srv_seg$sep$parts"
[ -n "$who_seg" ] && parts="$who_seg$sep$parts"

# Prompt cache: the time until it expires, or "cold".
pc_val=""
case $pc_state in
  cold) pc_val=$'\033[36mcold\033[0m' ;;
  warm)
    case $pc_expires in *[!0-9.]* | '') pc_expires=$now ;; esac
    pc_end=${pc_expires%.*}
    # While hooks/cache-keepalive.sh sleeps for this session, it pings the 1-hour
    # cache every CACHE_KEEPALIVE_SLEEP seconds after the last cache write until
    # the session has been idle CACHE_KEEPALIVE_MAX_IDLE seconds since its last
    # prompt; the cache then lasts one more hour. Its defaults are mirrored here.
    # It never pings a 5-minute cache, though a sleeper from an earlier 1-hour
    # write can still be alive, so only a 1-hour cache is extended.
    ka_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/cache-keepalive"
    ka_pid=""
    [ "$pc_ttl" = 1h ] && ka_pid=$(cat "$ka_dir/$rl_sid.sleeper" 2>/dev/null)
    if [ -n "$rl_sid" ] && [ -n "$ka_pid" ] && kill -0 "$ka_pid" 2>/dev/null; then
      ka_last=$(cat "$ka_dir/$rl_sid.last_prompt" 2>/dev/null)
      case $ka_last in *[!0-9]* | '') ka_last=$now ;; esac
      ka_ping=$((pc_end - 3600))
      while [ $((ka_ping + 2700 - ka_last)) -lt 7200 ]; do
        ka_ping=$((ka_ping + 2700))
        pc_end=$((ka_ping + 3600))
      done
    fi
    # session-port.sh keeps the session's port block until this expiry.
    if [ -n "$rl_sid" ] && [ -e "$rl_dir/port-$rl_sid" ]; then
      pc_until=""
      { read -r pc_until < "$rl_dir/port-$rl_sid.until"; } 2>/dev/null
      [ "$pc_until" = "$pc_end" ] || printf '%s\n' "$pc_end" > "$rl_dir/port-$rl_sid.until"
    fi
    # Minutes left ("25m"), shown only from 30 left; they turn yellow from 15
    # left and red from 5.
    pc_left=$(((pc_end - now) / 60))
    [ "$pc_left" -lt 0 ] && pc_left=0
    if [ "$pc_left" -le 5 ]; then
      pc_val=$(printf '\033[31m%sm\033[0m' "$pc_left")
    elif [ "$pc_left" -le 15 ]; then
      pc_val=$(printf '\033[33m%sm\033[0m' "$pc_left")
    elif [ "$pc_left" -le 30 ]; then
      pc_val=$(rl_dim="" countdown_str "$pc_end")
    fi
    ;;
esac

# Context window usage, led by the window only when unusual ("40%",
# "200k:40%"), then the prompt cache's time to live in the same segment once
# 30 minutes or less remain ("40%:25m", "40%:cold").
ctx_seg=""
if [ -n "$ctx_used_pct" ]; then
  c=$(color_for_pct "$ctx_used_pct")
  ctx_seg=$(printf '\033[%sm%d%%\033[0m' "$c" "$ctx_used_pct")
  [ -n "$ctx_label" ] && ctx_seg=$(printf '%s\033[38;5;245m:\033[0m%s' "$ctx_label" "$ctx_seg")
fi
if [ -n "$pc_val" ]; then
  if [ -n "$ctx_seg" ]; then ctx_seg=$(printf '%s\033[38;5;245m:\033[0m%s' "$ctx_seg" "$pc_val"); else ctx_seg=$pc_val; fi
fi
[ -n "$ctx_seg" ] && parts="$parts$sep$ctx_seg"

# Project and branch as "project#branch": the project (green) is the git
# repository root, falling back to the cwd; the branch is bright white because
# yellow and red are reserved for usage warnings. Each part is an OSC 8 link:
# the project to its repository's web page, else to the shown checkout's
# absolute path; the branch to that path, so terminals can open or copy it.
dir_base="$git_root_name"
if [ -z "$dir_base" ]; then
  if [ "$cwd" = "$HOME" ]; then dir_base=HOME; else dir_base=$(basename "$cwd" 2>/dev/null); fi
fi
loc_path=${git_top:-$cwd}
loc_path=${loc_path//%/%25}
loc_link="file://${loc_path// /%20}"
loc_seg=""
[ -n "$dir_base" ] && loc_seg=$(printf '\033]8;;%s\a\033[32m%s\033[0m\033]8;;\a' "${repo_url:-$loc_link}" "$dir_base")
if [ -n "$git_info" ]; then
  loc_seg=$(printf '%s\033[38;5;245m#\033[0m\033]8;;%s\a\033[97m%s\033[0m\033]8;;\a' "$loc_seg" "$loc_link" "$git_info")
fi

# 5-hour and 7-day windows: "<countdown> <gauge>" each, no labels, one line
# each so their bars line up. Each links to the claude.ai usage page.
usage_link() { printf '\033]8;;https://claude.ai/new#settings/usage\a%s\033]8;;\a' "$1"; }
gauges=""
rl_dim=$five_hour_dim
fh_seg=$(rate_seg "$five_hour_reset" "$five_hr" 18000 900)
[ -n "$fh_seg" ] && gauges="\n$(usage_link "$fh_seg")"
rl_dim=$seven_day_dim
sd_seg=$(rate_seg "$seven_day_reset" "$seven_day" 604800 21600)
[ -n "$sd_seg" ] && gauges="$gauges\n$(usage_link "$sd_seg")"

# Claude gateway spend limit (rate_limits.spend_limit): "spend <countdown>:
# <usage%>", then the dollars spent of the limit when the gateway reports them.
rl_dim=$spend_dim
sp_seg=$(rate_seg "$spend_reset" "$spend_pct")
if [ -n "$sp_seg" ]; then
  if [ -n "$spend_used" ] && [ -n "$spend_cap" ]; then
    sp_seg=$(printf '%s \033[%s38;5;245m$%.2f/$%.2f\033[0m' "$sp_seg" "$rl_dim" "$spend_used" "$spend_cap")
  fi
  parts=$(printf '%s%s\033[38;5;245mspend\033[0m %s' "$parts" "$sep" "$sp_seg")
fi

# The first line is "<account>|<IP>:<port>|", the model, context, and any
# spend limit, then "<project>#<branch>", which ends the line since a long
# branch name runs longest. The gauge lines follow.
[ -n "$loc_seg" ] && parts="$parts$sep$loc_seg"

# Show the full IP address while the first line fits the terminal's $COLUMNS,
# else only its last octet: "7:48990", or ".7" without a port. Links keep the
# full address. Without $COLUMNS the line stays short.
srv_full=${parts//@.IP@/$srv_ip}
srv_full=${srv_full//@IP@/$srv_ip}
srv_vis=$(printf '%s' "$srv_full" | sed -E $'s/\033\\[[0-9;]*m//g; s/\033\\]8;;[^\a]*\a//g')
case $COLUMNS in
  '' | *[!0-9]*) srv_fits="" ;;
  *) [ "${#srv_vis}" -le "$COLUMNS" ] && srv_fits=1 || srv_fits="" ;;
esac
if [ -n "$srv_fits" ]; then
  parts=$srv_full
else
  parts=${parts//@.IP@/.${srv_ip##*.}}
  parts=${parts//@IP@/${srv_ip##*.}}
fi

printf '%b' "$parts$gauges"
