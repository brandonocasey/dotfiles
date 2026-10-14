#!/usr/bin/env bash
# Claude Code status line script

input=$(cat 2>/dev/null || echo '{}')

# --- Account (local part of the configured email) ---
acct_cfg="$HOME/.claude.json"
[ -n "$CLAUDE_CONFIG_DIR" ] && acct_cfg="$CLAUDE_CONFIG_DIR/.claude.json"
account=$(grep -oE '"emailAddress"[[:space:]]*:[[:space:]]*"[^"]*"' "$acct_cfg" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)".*/\1/')
account_name="${account%%@*}"
account_name="${account_name:0:3}"

# --- PORT (optional, only when set in the environment) ---
port_display=""
[ -n "$PORT" ] && port_display=":$PORT"

# --- Git branch ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd="$PWD"
git_info=""
git_root_name=""
if cd "$cwd" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch="detached"
  git_info="$branch"

  # Name the repository, not the checkout: --git-common-dir points at the main
  # repo's .git even from a linked worktree or a submodule whose gitdir lives
  # elsewhere, so worktrees report the parent repo instead of ".worktrees/<x>".
  common_dir=$(git --no-optional-locks rev-parse --git-common-dir 2>/dev/null)
  case "$common_dir" in
    "") ;;
    /*) ;;
    *) common_dir="$cwd/$common_dir" ;;
  esac
  if [ -n "$common_dir" ]; then
    if [ "$(basename "$common_dir")" = ".git" ]; then
      git_root_name=$(basename "$(cd "$common_dir/.." 2>/dev/null && pwd -P)")
    else
      # Bare repo: the gitdir itself is the project (e.g. "web-player.git").
      git_root_name=$(basename "$common_dir" .git)
    fi
  fi

  # Claude often works in a linked worktree by absolute path while the session
  # stays in the main checkout. From the main checkout, show the branch of the
  # worktree its tool calls named most recently instead.
  transcript=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
  if [ -f "$transcript" ] &&
    [ "$(git --no-optional-locks rev-parse --git-dir 2>/dev/null)" = "$(git --no-optional-locks rev-parse --git-common-dir 2>/dev/null)" ]; then
    wt_list=$(git --no-optional-locks worktree list --porcelain 2>/dev/null | awk '
      /^worktree / { if (n++) path = substr($0, 10); else path = "" }
      /^branch / && path != "" { sub("refs/heads/", "", $2); print path "\t" $2 }
      /^detached/ && path != "" { print path "\tdetached" }
    ')
    if [ -n "$wt_list" ]; then
      wt_branch=$(tail -n 2000 "$transcript" | rg -F '"tool_use"' | jq -rR '
        fromjson? | select(.type == "assistant") | .message.content[]?
        | select(.type == "tool_use") | .input | tostring | gsub("[\t\n]"; " ")
      ' 2>/dev/null | WT_LIST="$wt_list" awk -F '\t' '
        BEGIN { n = split(ENVIRON["WT_LIST"], rows, "\n"); for (i = 1; i <= n; i++) { split(rows[i], f, "\t"); p[i] = f[1]; b[i] = f[2] } }
        {
          # Longest path wins, so ".worktrees/a" never matches inside ".worktrees/ab".
          best = 0
          for (i = 1; i <= n; i++) {
            j = index($0, p[i])
            if (j && substr($0, j + length(p[i]), 1) !~ /[A-Za-z0-9._-]/ && (!best || length(p[i]) > length(p[best]))) best = i
          }
          if (best) last = b[best]
        }
        END { if (last != "") print last }
      ')
      [ -n "$wt_branch" ] && git_info="$wt_branch"
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
  (.context_window.context_window_size // .context_window.total_tokens // .context_window.total // .context_window.size // .context_window.max_tokens // .context_window.window_tokens // empty)
' 2>/dev/null)

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
rl_sid=$(echo "$input" | jq -j '.session_id // empty' 2>/dev/null | tr -c 'A-Za-z0-9._-' '_')
rl_prev_file=""
[ -n "$rl_sid" ] && rl_prev_file="$rl_dir/session-$rl_sid.json"
rl_locked=""
rl_tmp=""
# Claude Code cancels a running script when a new update fires; don't leave
# temp files or a held lock behind.
trap 'rm -f "$rl_tmp"; [ -n "$rl_locked" ] && rmdir "$rl_lock" 2>/dev/null' EXIT
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
      # A lock older than 10 s belongs to a killed run.
      if [ $(($(date +%s) - rl_lock_mtime)) -gt 10 ]; then
        rmdir "$rl_lock" 2>/dev/null
        mkdir "$rl_lock" 2>/dev/null && rl_locked=1
      fi
      ;;
  esac
fi

rl_live=$(echo "$input" | jq -c '.rate_limits // {}' 2>/dev/null)
rl_cached=$(jq -cs '.[0] // null' "$rl_cache" 2>/dev/null)
rl_prev=""
[ -n "$rl_prev_file" ] && rl_prev=$(jq -cs '.[0] // null' "$rl_prev_file" 2>/dev/null)
rl_state=$(jq -ncS --argjson now "$(date +%s)" --argjson live "${rl_live:-null}" \
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
        elif $mine == $old then ($cached // $mine)
        elif $old != null and same($mine; $old) and $mine.used_percentage < $old.used_percentage then $mine
        else newer($mine; $cached) end)
  | {live: $l, cache: ., cache_changed: (. != $cache), prev_changed: ($l != $prev)}
' 2>/dev/null)
[ -z "$rl_state" ] && rl_state='{"live":{},"cache":{}}'

if [ -n "$rl_locked" ]; then
  if [ "$(echo "$rl_state" | jq -r '.cache_changed')" != true ] ||
    rl_write "$rl_cache" "$(echo "$rl_state" | jq -cS '.cache')"; then
    # Record what this session saw only once the cache holds it.
    if [ -n "$rl_prev_file" ] && [ "$(echo "$rl_state" | jq -r '.prev_changed')" = true ]; then
      rl_write "$rl_prev_file" "$(echo "$rl_state" | jq -cS '.live')"
    fi
  fi
  # Session files last past every window they hold (7 days at most); temp
  # files are left only by runs killed outright.
  find "$rl_dir" -type f \( -name 'session-*.json' -mtime +8 -o -name '*.json.*' -mmin +60 \) \
    -delete 2>/dev/null
  rmdir "$rl_lock" 2>/dev/null
  rl_locked=""
fi

# Values this session has no live copy of come from the cache and are dimmed.
five_hr=$(echo "$rl_state" | jq -r '.cache.five_hour.used_percentage // empty' 2>/dev/null)
five_hour_reset=$(echo "$rl_state" | jq -r '.cache.five_hour.resets_at // empty' 2>/dev/null)
five_hour_dim=$(echo "$rl_state" | jq -r 'if .live.five_hour then "" else "2;" end' 2>/dev/null)
seven_day=$(echo "$rl_state" | jq -r '.cache.seven_day.used_percentage // empty' 2>/dev/null)
seven_day_reset=$(echo "$rl_state" | jq -r '.cache.seven_day.resets_at // empty' 2>/dev/null)
seven_day_dim=$(echo "$rl_state" | jq -r 'if .live.seven_day then "" else "2;" end' 2>/dev/null)

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

# --- Format a reset timestamp as a short countdown from now ---
# Shows only the largest unit, rounded down to one decimal so it never
# overstates the time left: "6.5d", "4.2h", "45m", "0m". The unit sets the
# hue (days violet, hours teal, minutes blue).
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
    else                out = MINS int(d / 60) "m\033[0m"
    printf "%s", out
  }'
}

# --- Build an unlabeled "<countdown>:<pct>%" rate-limit segment ---
# $1 = reset epoch (may be empty), $2 = used percentage (may be empty)
# The countdown colours itself per unit; the percentage is colored by usage
# (green / yellow / red), which is why no other field uses yellow or red.
rate_seg() {
  local reset=$1 pct=$2 seg="" p c
  if [ -n "$reset" ] && [ "$reset" != "null" ]; then
    seg=$(countdown_str "$reset")
  fi
  if [ -n "$pct" ]; then
    p=$(printf '%.0f' "$pct")
    c=$(color_for_pct "$p")
    if [ -n "$seg" ]; then
      seg=$(printf '%s\033[%s38;5;245m:\033[0m\033[%s%sm%d%%\033[0m' "$seg" "$rl_dim" "$rl_dim" "$c" "$p")
    else
      seg=$(printf '\033[%s%sm%d%%\033[0m' "$rl_dim" "$c" "$p")
    fi
  fi
  printf '%s' "$seg"
}

# Tokens in context from the last API call (same input-only formula as
# used_percentage). Past the warn threshold the segment shows a yellow ⚠, and
# past the hint threshold a red ⚠, suggesting /compact because every later
# turn re-reads the whole context.
ctx_used_tokens=$(echo "$input" | jq -r '
  .context_window.current_usage
  | if . then ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)) else empty end
' 2>/dev/null)
case $ctx_used_tokens in *[!0-9]*) ctx_used_tokens="" ;; esac

# Auto-compact window from user settings.json: modelSettings.<model>
# .autoCompactWindow replaces the top-level value. Model ids and settings keys
# both drop the [1m] flag and any date suffix before matching, as Claude Code
# does. Project settings are not read; "auto" means no fixed window.
settings_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
compact_window=$(jq -r --arg m "$model_id" '
  def canon: sub("\\[[^]]*\\]$"; "") | sub("-[0-9]{8}$"; "");
  ($m | canon) as $k
  # An exactly canonical key wins over a [1m] or dated spelling of it.
  | ([(.modelSettings // {}) | to_entries | sort_by((.key | canon) != .key)[]
      | select((.key | canon) == $k)
      | .value.autoCompactWindow | select(. != null)] | first) as $model
  | ($model // .autoCompactWindow)
  | if . == "auto" then empty else (. // empty) end
' "$settings_dir/settings.json" 2>/dev/null)
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
# keeps a 13k buffer. The hint marks that point and the warn sits 20k before
# it, as in Claude Code's own warning.
compact_at=""
[ -n "$compact_window" ] && compact_at=$((compact_window - 33000))
if [ -n "$compact_at" ]; then
  default_hint=$compact_at
  default_warn=$((compact_at - 20000))
else
  default_hint=500000
  default_warn=300000
fi
compact_warn_tokens=${CLAUDE_COMPACT_WARN_TOKENS:-$default_warn}
case $compact_warn_tokens in *[!0-9]*) compact_warn_tokens=$default_warn ;; esac
compact_hint_tokens=${CLAUDE_COMPACT_HINT_TOKENS:-$default_hint}
case $compact_hint_tokens in *[!0-9]*) compact_hint_tokens=$default_hint ;; esac

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
    *1m*|*1M*|*\[1m\]*|*[Ff]able*) is_1m=1 ;;
  esac
fi

# --- Context window label: window size instead of generic "ctx" ---
# Prefer reported capacity; model-based defaults apply only when capacity is absent.
if [ -n "$compact_at" ] && [ -n "$ctx_used_tokens" ]; then
  ctx_label=$(fmt_tokens "$compact_at")
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

# Account name (grey) leads the line
parts=""
[ -n "$account_name" ] && parts=$(printf '\033[38;5;247m%s\033[0m' "$account_name")

# Prompt cache: minutes until the main cache expires, or a cyan "cold" once it
# has. Shown only after caching was observed, so a fresh session stays quiet.
# Cyan, because yellow and red are reserved for usage warnings. When cold, the
# next turn re-writes the whole context to the cache, so that token count
# follows ("cold:312k").
cold_tokens=""
[ -n "$ctx_used_tokens" ] && cold_tokens=$(fmt_tokens "$ctx_used_tokens")
pc_seg=$(echo "$input" | jq -r --argjson now "$(date +%s)" --arg cold "$cold_tokens" '
  .prompt_cache // empty | select(.caching_observed == true)
  | if .warm == true and .expires_at != null
    then "\u001b[38;5;245mc:\u001b[0m\(((.expires_at - $now) / 60) | if . < 0 then 0 else floor end)m"
    elif $cold != "" then "\u001b[36mcold\u001b[0m\u001b[38;5;245m:\u001b[0m\u001b[36m\($cold)\u001b[0m"
    else "\u001b[36mcold\u001b[0m" end
' 2>/dev/null)
if [ -n "$pc_seg" ]; then
  if [ -n "$parts" ]; then
    parts=$(printf '%s%s%s' "$parts" "$sep" "$pc_seg")
  else
    parts="$pc_seg"
  fi
fi

# Model + effort (blue then magenta, no joiner — the colour change separates
# them). The context-window size is not repeated here; the context segment
# already labels it (1M, 200k).
if [ -n "$effort" ]; then
  model_seg=$(printf '\033[34m%s\033[0m\033[35m%s\033[0m' "$model" "$effort")
else
  model_seg=$(printf '\033[34m%s\033[0m' "$model")
fi
if [ -n "$parts" ]; then
  parts=$(printf '%s%s%s' "$parts" "$sep" "$model_seg")
else
  parts="$model_seg"
fi

# Context window usage (labeled with the window size: 1M / 200k / …)
if [ -n "$ctx_used_pct" ]; then
  c=$(color_for_pct "$ctx_used_pct")
  hint=""
  if [ -n "$ctx_used_tokens" ] && [ "$ctx_used_tokens" -ge "$compact_hint_tokens" ]; then
    c=31
    hint=$(printf '\033[31m⚠\033[0m')
  elif [ -n "$ctx_used_tokens" ] && [ "$ctx_used_tokens" -ge "$compact_warn_tokens" ]; then
    # Never downgrade a red percent to yellow.
    [ "$c" = 32 ] && c=33
    hint=$(printf '\033[33m⚠\033[0m')
  fi
  parts=$(printf '%s%s%s\033[38;5;245m:\033[0m\033[%sm%d%%\033[0m%s' "$parts" "$sep" "$ctx_label" "$c" "$ctx_used_pct" "$hint")
fi

# Project and branch as "project#branch": the project (green) is the git
# repository root, falling back to the cwd; the branch is bright white because
# yellow and red are reserved for usage warnings.
dir_base="$git_root_name"
[ -z "$dir_base" ] && dir_base=$(basename "$cwd" 2>/dev/null)
loc_seg=""
[ -n "$dir_base" ] && loc_seg=$(printf '\033[32m%s\033[0m' "$dir_base")
if [ -n "$git_info" ]; then
  loc_seg=$(printf '%s\033[38;5;245m#\033[0m\033[97m%s\033[0m' "$loc_seg" "$git_info")
fi
[ -n "$loc_seg" ] && parts=$(printf '%s%s%s' "$parts" "$sep" "$loc_seg")

# 5-hour and 7-day windows: "<countdown>:<usage%>" each, no labels
rl_dim=$five_hour_dim
fh_seg=$(rate_seg "$five_hour_reset" "$five_hr")
[ -n "$fh_seg" ] && parts=$(printf '%s%s%s' "$parts" "$sep" "$fh_seg")
rl_dim=$seven_day_dim
sd_seg=$(rate_seg "$seven_day_reset" "$seven_day")
[ -n "$sd_seg" ] && parts=$(printf '%s%s%s' "$parts" "$sep" "$sd_seg")

# Extra / overage usage
if [ -n "$extra_pct" ]; then
  ex_int=$(printf '%.0f' "$extra_pct")
  c=$(color_for_pct "$ex_int")
  parts=$(printf '%s%sextra \033[%sm%d%%\033[0m' "$parts" "$sep" "$c" "$ex_int")
elif [ -n "$extra_dollars" ]; then
  # Fallback: dollars used (and limit if known)
  if [ -n "$extra_limit_dollars" ] && awk -v l="$extra_limit_dollars" 'BEGIN{exit !(l+0 > 0)}'; then
    pct=$(awk -v u="$extra_dollars" -v l="$extra_limit_dollars" 'BEGIN{printf "%d", (u/l)*100 + 0.5}')
    c=$(color_for_pct "$pct")
    parts=$(printf '%s%sextra \033[%sm$%.2f/$%.2f\033[0m' "$parts" "$sep" "$c" "$extra_dollars" "$extra_limit_dollars")
  else
    parts=$(printf '%s%sextra \033[38;5;245m$%.2f\033[0m' "$parts" "$sep" "$extra_dollars")
  fi
fi

# PORT (magenta, only when set)
if [ -n "$port_display" ]; then
  parts=$(printf '%s%s\033[35m%s\033[0m' "$parts" "$sep" "$port_display")
fi

printf '%b' "$parts"