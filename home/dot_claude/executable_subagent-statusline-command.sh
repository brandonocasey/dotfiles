#!/usr/bin/env bash
# Claude Code subagent status line: one row per agent in the agent panel.
# Reads {tasks: [...]} on stdin and prints one {"id", "content"} JSON line per
# task. Matches statusline-command.sh: model letter + version in blue, effort
# letter in magenta, then window:used% coloured green <65, yellow 65-79, red >=80.

input=$(cat)

# The task's tokenCount is an estimate of the agent's total tokens, not its
# context, so read the context from the agent's last API call instead (same
# input-only formula as statusline-command.sh). Agent transcripts live beside
# the session's own: <session>/subagents/agent-<id>.jsonl.
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
agent_dir="${transcript%.jsonl}/subagents"
ctx='{}'
if [ -n "$transcript" ] && [ -d "$agent_dir" ]; then
  for id in $(printf '%s' "$input" | jq -r '.tasks[]?.id'); do
    case $id in *[!A-Za-z0-9_-]*) continue ;; esac
    f="$agent_dir/agent-$id.jsonl"
    [ -f "$f" ] || continue
    used=$(tail -n 100 "$f" | jq -R -s '
      [split("\n")[] | fromjson? | select(.type == "assistant") | .message.usage | select(.)
       | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)]
      | last // empty' 2>/dev/null)
    [ -n "$used" ] && ctx=$(jq -c --arg id "$id" --argjson u "$used" '.[$id] = $u' <<<"$ctx")
  done
fi

settings=$(jq -c '{modelSettings, autoCompactWindow}' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" 2>/dev/null)
[ -n "$settings" ] || settings='{}'

printf '%s' "$input" | jq -c --argjson ctx "$ctx" --argjson settings "$settings" '
  def esc: "\u001b[";
  def dim: esc + "38;5;245m";
  def reset: esc + "0m";

  # "claude-sonnet-5-5[1m]", "Claude Opus 5.5" or "haiku" -> "S5.5", "O5.5", "H"
  def short_model:
    (sub("\\[[^]]*\\]$"; "") | sub("-[0-9]{8}$"; "")) as $m
    | ($m | ascii_downcase) as $l
    | (if $l | test("sonnet") then "S"
       elif $l | test("opus") then "O"
       elif $l | test("haiku") then "H"
       elif $l | test("fable") then "F"
       else null end) as $f
    | if $f == null then ($m | sub("^[Cc]laude[- ]"; ""))
      else $f + ([$m | scan("[0-9]+[-.][0-9]+|[0-9]+")] | first // "" | gsub("-"; "."))
      end;

  def short_effort:
    (ascii_downcase) as $e
    | if $e == "low" then "l"
      elif $e == "medium" or $e == "med" then "m"
      elif $e == "high" then "h"
      elif $e == "xhigh" or $e == "extreme" then "x"
      elif $e == "max" then "X"
      else .[0:1] end;

  def fmt_tokens:
    if . >= 1000000 then ((. / 100000 | floor) / 10 | tostring | sub("\\.0$"; "")) + "M"
    else "\(. / 1000 | round)k" end;

  def pct_color: if . >= 80 then "31" elif . >= 65 then "33" else "32" end;

  def canon: sub("\\[[^]]*\\]$"; "") | sub("-[0-9]{8}$"; "");
  # A whole token count, or null for "auto", unset or junk.
  def fixed:
    if type == "number" and . == floor then .
    elif type == "string" and test("^[0-9]+$") then tonumber
    else null end;

  # Same rules as statusline-command.sh: a per-model autoCompactWindow wins over
  # the top-level one; Claude Code accepts 100k to 1M and never exceeds the
  # context window; compaction happens 33k below it (20k output reserve plus a
  # 13k buffer).
  ($settings.autoCompactWindow | fixed) as $usual_window
  | def compact_window($model; $win):
      ($model | canon) as $k
      | ([($settings.modelSettings // {}) | to_entries
          | sort_by((.key | canon) != .key)[]
          | select((.key | canon) == $k)
          | .value.autoCompactWindow | select(. != null)] | first) as $per_model
      | ($per_model // $settings.autoCompactWindow | fixed)
      | if . == null or . < 100000 or . > 1000000 then null
        elif $win > 0 and $win < . then $win
        else . end;

  .tasks[]?
  | ((.model // "") | tostring) as $model
  | ((.effort // "") | tostring) as $effort
  | (.contextWindowSize // 0) as $win
  | ($ctx[.id] // .tokenCount // 0) as $used
  | ([
      (if $model != "" then esc + "34m" + ($model | short_model) + reset else empty end),
      (if $effort != "" then esc + "35m" + ($effort | short_effort) + reset else empty end)
    ] | join("")) as $model_seg
  | compact_window($model; $win) as $cw
  | (if $cw != null and $cw - 33000 > 0 then $cw - 33000 else null end) as $compact_at
  # Measure against the compaction point when one is set, since that is the
  # real ceiling; the usual (top-level) point goes unlabelled.
  | (if $compact_at != null then
       {limit: $compact_at, label: (if $cw == $usual_window then "" else $compact_at | fmt_tokens end)}
     elif $win > 0 then {limit: $win, label: ($win | fmt_tokens)}
     else null end) as $ceil
  | (if $ceil != null and $used > 0 then
       (($used * 100 / $ceil.limit) | round) as $p
       | (if $ceil.label != "" then $ceil.label + dim + ":" + reset else "" end)
         + esc + ($p | pct_color) + "m\($p)%" + reset
     else "" end) as $ctx_seg
  | {id, content: ([$model_seg, $ctx_seg] | map(select(. != "")) | join(dim + "|" + reset))}
'
