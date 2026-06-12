#!/usr/bin/env bash
# Claude Code status line script

input=$(cat 2>/dev/null || echo '{}')

# --- Account (local part of the configured email) ---
acct_cfg="$HOME/.claude.json"
[ -n "$CLAUDE_CONFIG_DIR" ] && acct_cfg="$CLAUDE_CONFIG_DIR/.claude.json"
account=$(grep -oE '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$acct_cfg" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/')
account_name="${account%%@*}"

# --- PORT (optional, only when set in the environment) ---
port_display=""
[ -n "$PORT" ] && port_display="PORT=$PORT"

# --- Time ---
time_str=$(date '+%I:%M %p')

# --- Git branch ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd="$PWD"
git_info=""
if cd "$cwd" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch="detached"
  git_info="$branch"
fi

# --- Model name (shorten to S/O/H + version) ---
model_raw=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
model_id=$(echo "$input" | jq -r '.model.id // empty' 2>/dev/null)
[ -z "$model_raw" ] || [ "$model_raw" = "null" ] && model_raw="Claude"

# Extract version number from display name or model id
# Display name examples: "Claude Sonnet 4.6", "Claude Opus 4.8", "Claude Haiku 3.5"
# Model id examples: "claude-sonnet-4-6", "claude-opus-4", "claude-haiku-3-5"
model=""
case "$model_raw" in
  *[Ss]onnet*)
    ver=$(echo "$model_raw" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_id" | grep -oE '[0-9]+-[0-9]+' | head -1 | tr '-' '.')
    [ -z "$ver" ] && ver=$(echo "$model_id" | grep -oE '[0-9]+' | head -1)
    model="S${ver}"
    ;;
  *[Oo]pus*)
    ver=$(echo "$model_raw" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_raw" | grep -oE '[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_id" | grep -oE '[0-9]+-[0-9]+' | head -1 | tr '-' '.')
    [ -z "$ver" ] && ver=$(echo "$model_id" | grep -oE '[0-9]+' | head -1)
    model="O${ver}"
    ;;
  *[Hh]aiku*)
    ver=$(echo "$model_raw" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_raw" | grep -oE '[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_id" | grep -oE '[0-9]+-[0-9]+' | head -1 | tr '-' '.')
    [ -z "$ver" ] && ver=$(echo "$model_id" | grep -oE '[0-9]+' | head -1)
    model="H${ver}"
    ;;
  *[Ff]able*)
    ver=$(echo "$model_raw" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_raw" | grep -oE '[0-9]+' | head -1)
    [ -z "$ver" ] && ver=$(echo "$model_id" | grep -oE '[0-9]+' | head -1)
    model="F${ver}"
    ;;
  *)
    # Fallback: strip "Claude " prefix, collapse whitespace
    model=$(echo "$model_raw" | sed -E 's/^Claude[[:space:]]+//' | sed -E 's/[[:space:]]+/ /g')
    ;;
esac

# Append 1M suffix if applicable
case "$model_raw$model_id" in
  *1m*|*1M*) model="${model}·1M" ;;
esac

# --- Effort level (shortened to single letter) ---
effort_raw=$(echo "$input" | jq -r '.effort.level // empty' 2>/dev/null)
effort=""
case "$effort_raw" in
  low|LOW|Low)       effort="lo" ;;
  medium|MEDIUM|Medium|med) effort="md" ;;
  high|HIGH|High)    effort="hi" ;;
  xhigh|XHIGH|xHigh|XHigh|extreme) effort="xh" ;;
  max|MAX|Max)       effort="mx" ;;
  "")                effort="" ;;
  *)                 effort=$(echo "$effort_raw" | cut -c1-2 | tr '[:upper:]' '[:lower:]') ;;
esac

# --- Context window ---
ctx_remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)
ctx_total=$(echo "$input" | jq -r '
  (.context_window.total_tokens // .context_window.total // .context_window.size // .context_window.max_tokens // .context_window.window_tokens // empty)
' 2>/dev/null)

# --- Rate limits (each window: countdown to reset, then usage %) ---
five_hr=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)
seven_day_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)

# --- Extra / overage usage (probe several likely field names) ---
extra_pct=$(echo "$input" | jq -r '
  (.rate_limits.extra.used_percentage
   // .rate_limits.overage.used_percentage
   // .rate_limits.extra_usage.used_percentage
   // .extra_usage.used_percentage
   // .overage.used_percentage
   // empty)
' 2>/dev/null)
extra_dollars=$(echo "$input" | jq -r '
  (.rate_limits.extra.used_dollars
   // .rate_limits.extra.used_usd
   // .rate_limits.overage.used_dollars
   // .extra_usage.used_dollars
   // .extra_usage.used_usd
   // .billing.extra_used_dollars
   // empty)
' 2>/dev/null)
extra_limit_dollars=$(echo "$input" | jq -r '
  (.rate_limits.extra.limit_dollars
   // .rate_limits.extra.cap_dollars
   // .extra_usage.limit_dollars
   // .extra_usage.cap_dollars
   // .billing.extra_limit_dollars
   // empty)
' 2>/dev/null)

# --- Color picker for a used% value ---
# green <60, yellow 60-79, red >=80
color_for_pct() {
  local used=$1
  if [ "$used" -ge 80 ]; then printf '31'
  elif [ "$used" -ge 60 ]; then printf '33'
  else printf '32'
  fi
}

# --- Format a reset timestamp as a "d/h/m" countdown from now ---
# Digits are cyan, unit letters (d/h/m) dim grey, so numbers stand out.
# Drops leading zero units: "6d12h41m", "12h30m", "45m", "0m"
countdown_str() {
  awk -v r="$1" -v n="$(date +%s)" 'BEGIN{
    d = r - n
    if (d < 0) d = 0
    days  = int(d / 86400)
    hours = int((d % 86400) / 3600)
    mins  = int((d % 3600) / 60)
    out = ""
    if (days  > 0) out = out days "d "
    if (hours > 0 || days > 0) out = out hours "h "
    out = out mins "m"
    printf "%s", out
  }'
}

# --- Build an unlabeled "<countdown>·<pct>%" rate-limit segment ---
# $1 = reset epoch (may be empty), $2 = used percentage (may be empty)
# Countdown self-colors (digits cyan, units grey); pct number is colored by
# usage with a dim-grey "%" so the digits stand out.
rate_seg() {
  local reset=$1 pct=$2 seg="" p c
  if [ -n "$reset" ] && [ "$reset" != "null" ]; then
    seg=$(printf '\033[36m%s\033[0m' "$(countdown_str "$reset")")
  fi
  if [ -n "$pct" ]; then
    p=$(printf '%.0f' "$pct")
    c=$(color_for_pct "$p")
    if [ -n "$seg" ]; then
      seg=$(printf '%s \033[38;5;245m·\033[0m \033[%sm%d%%\033[0m' "$seg" "$c" "$p")
    else
      seg=$(printf '\033[%sm%d%%\033[0m' "$c" "$p")
    fi
  fi
  printf '%s' "$seg"
}

ctx_used_pct=""
if [ -n "$ctx_remaining" ]; then
  ctx_used_pct=$(awk -v r="$ctx_remaining" 'BEGIN{printf "%d", 100 - r + 0.5}')
fi

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
    *1m*|*1M*|*\[1m\]*|*[Ff]able*) is_1m=1 ;;
  esac
fi

# --- Context window label: window size instead of generic "ctx" ---
# 1M models -> "1M"; otherwise derive "<n>k" from the known total, else "200k".
if [ $is_1m -eq 1 ]; then
  ctx_label="1M"
elif [ -n "$ctx_total" ] && [ "$ctx_total" != "null" ]; then
  ctx_label=$(awk -v t="$ctx_total" 'BEGIN{
    if (t+0 >= 1000000) printf "%gM", t/1000000; else printf "%dk", int(t/1000 + 0.5)
  }')
else
  ctx_label="200k"
fi

# --- Build output ---
# Account name (default/white), leads the line when known
parts=""
[ -n "$account_name" ] && parts=$(printf '\033[0m%s\033[0m' "$account_name")

# Model + effort (blue · magenta), combined into one segment
if [ -n "$effort" ]; then
  model_seg=$(printf '\033[34m%s\033[0m\033[38;5;245m·\033[0m\033[35m%s\033[0m' "$model" "$effort")
else
  model_seg=$(printf '\033[34m%s\033[0m' "$model")
fi
if [ -n "$parts" ]; then
  parts=$(printf '%s | %s' "$parts" "$model_seg")
else
  parts="$model_seg"
fi

# Context window usage (labeled with the window size: 1M / 200k / …)
if [ -n "$ctx_used_pct" ]; then
  c=$(color_for_pct "$ctx_used_pct")
  parts=$(printf '%s | %s \033[%sm%d%%\033[0m' "$parts" "$ctx_label" "$c" "$ctx_used_pct")
fi

# 5-hour and 7-day windows: "<countdown> · <usage%>" each, no labels
fh_seg=$(rate_seg "$five_hour_reset" "$five_hr")
[ -n "$fh_seg" ] && parts=$(printf '%s | %s' "$parts" "$fh_seg")
sd_seg=$(rate_seg "$seven_day_reset" "$seven_day")
[ -n "$sd_seg" ] && parts=$(printf '%s | %s' "$parts" "$sd_seg")

# Extra / overage usage
if [ -n "$extra_pct" ]; then
  ex_int=$(printf '%.0f' "$extra_pct")
  c=$(color_for_pct "$ex_int")
  parts=$(printf '%s | extra \033[%sm%d%%\033[0m' "$parts" "$c" "$ex_int")
elif [ -n "$extra_dollars" ]; then
  # Fallback: dollars used (and limit if known)
  if [ -n "$extra_limit_dollars" ] && awk -v l="$extra_limit_dollars" 'BEGIN{exit !(l+0 > 0)}'; then
    pct=$(awk -v u="$extra_dollars" -v l="$extra_limit_dollars" 'BEGIN{printf "%d", (u/l)*100 + 0.5}')
    c=$(color_for_pct "$pct")
    parts=$(printf '%s | extra \033[%sm$%.2f/$%.2f\033[0m' "$parts" "$c" "$extra_dollars" "$extra_limit_dollars")
  else
    parts=$(printf '%s | extra \033[38;5;245m$%.2f\033[0m' "$parts" "$extra_dollars")
  fi
fi

# PORT (magenta, only when set)
if [ -n "$port_display" ]; then
  parts=$(printf '%s | \033[35m%s\033[0m' "$parts" "$port_display")
fi

# Git branch (yellow)
if [ -n "$git_info" ]; then
  parts=$(printf '%s | \033[33m%s\033[0m' "$parts" "$git_info")
fi

# Time (cyan)
parts=$(printf '%s | \033[96m%s\033[0m' "$parts" "$time_str")

printf '%b' "$parts"