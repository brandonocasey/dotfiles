#!/bin/sh
# Renames the tmux session that holds an agent to the agent's session title, in
# plain words (Fix stop-hook loop). Usage:
#   agent-tmux-session.sh claude|codex   SessionStart or Stop hook, JSON on stdin
#   agent-tmux-session.sh set <title> [sid]
#                                        from auto-title.sh, right after Haiku
#   agent-tmux-session.sh restore        SessionEnd hook, JSON on stdin
#   agent-tmux-session.sh sync <title> [sid]
#                                        from the Claude status line after /rename;
#                                        renames only when the title changed
#   agent-tmux-session.sh tidy <title>   print the cleaned title only
#   agent-tmux-session.sh ported <title> <sid>
#                                        print the title with the session's port
#   agent-tmux-session.sh bare <title>   print the title without a port in front
# The first rename saves the session's old name; restore puts it back when the
# agent exits, unless the user renamed the session since or another agent pane
# still uses it. /clear does not restore it. Over ssh it never restores.
# Inside tmux it renames directly. Over ssh from a local tmux (the remote TERM is
# tmux* or screen*), it sends a marked window-name escape to $SSH_TTY; the
# window-renamed hook in the local tmux.conf turns that into a session rename.
# The marker MUST match tmux.conf. Other terminals can print the escape as text,
# so they get nothing.
# It exits 0 on every path, so a missing tool or title never blocks the agent.

agent=${1:-}
marker='agent-session:'

# The title as plain words (case kept), at most 60 characters, cut at a word
# break, without a closing period. Claude shows this form.
tidy() {
  printf '%s' "$1" | LC_ALL=C tr -d '[:cntrl:]' |
    LC_ALL=C sed -e 's/[.!?]*[[:space:]]*$//' -e 's/[[:space:]][[:space:]]*/ /g' -e 's/^ //' -e 's/ $//' |
    awk '{ if (length($0) > 60) { s = substr($0, 1, 61); sub(/ [^ ]*$/, "", s); $0 = substr(s, 1, 60) } print }'
}

# The tmux form: tmux treats ':' and '#' specially in names and turns '.' into
# '_', so 8.51.14 becomes 8_51_14 here but stays exact in Claude.
safe() {
  tidy "$1" | LC_ALL=C sed -e 's/[:#]/ /g' -e 's/\./_/g' -e 's/  */ /g' -e 's/^ //' -e 's/ $//'
}

# Claude session names start with the session's port ("47950 Fix login"). A
# block port already in front is replaced; the pattern MUST match
# session-port.sh's block layout.
bare() {
  printf '%s' "$1" | LC_ALL=C sed -E 's/^4[0-8][0-9][0-9]0( +|$)//'
}

session_port() {
  [ -n "$1" ] || return 0
  sid_file=$(printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_')
  port=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/port-$sid_file" 2>/dev/null)
  case $port in '' | *[!0-9]*) ;; *) printf '%s' "$port" ;; esac
}

# After /clear, Claude carries the old name over and auto-title.sh records it.
# That name, and the port-only name from session start, count as no title.
cleared_name() {
  [ -n "$1" ] || return 0
  cat "${XDG_STATE_HOME:-$HOME/.local/state}/agents/auto-title/$1.cleared" 2>/dev/null
}

no_title() {
  [ -z "$(bare "$1")" ] || [ "$1" = "$2" ]
}

# The title with the port of session <sid> in front; unchanged without a port.
ported() {
  port=$(session_port "$2")
  if [ -z "$port" ]; then
    printf '%s' "$1"
    return 0
  fi
  rest=$(bare "$1")
  printf '%s%s' "$port" "${rest:+ $rest}"
}

case $agent in
tidy)
  tidy "${2:-}"
  exit 0
  ;;
bare)
  bare "${2:-}"
  exit 0
  ;;
ported)
  ported "${2:-}" "${3:-}"
  exit 0
  ;;
esac

if [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ] && command -v tmux >/dev/null 2>&1; then
  target=tmux
elif [ -n "${SSH_TTY:-}" ] && [ -w "$SSH_TTY" ]; then
  case ${TERM:-} in
  tmux* | screen*) target=ssh ;;
  *) exit 0 ;;
  esac
else
  exit 0
fi

rename() {
  name=$(safe "$1")
  [ -n "$name" ] || return 0
  if [ "$target" = ssh ]; then
    printf '\033k%s%s\033\134' "$marker" "$name" >"$SSH_TTY" 2>/dev/null
    return 0
  fi
  session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null) || return 0
  current=$(tmux display-message -p -t "$session" '#{session_name}' 2>/dev/null)
  # Another session may already use the name; rename-session would fail.
  base=$name
  n=2
  while [ "$name" != "$current" ] && tmux has-session -t "=$name" 2>/dev/null; do
    name="$base ($n)"
    n=$((n + 1))
  done
  [ "$name" = "$current" ] && return 0
  [ -n "$(tmux show-options -qv -t "$session" @agent_orig_name)" ] ||
    tmux set-option -t "$session" @agent_orig_name "$current"
  tmux rename-session -t "$session" "$name" 2>/dev/null &&
    tmux set-option -t "$session" @agent_name "$name"
  return 0
}

if [ "$agent" = set ]; then
  rename "$(ported "${2:-}" "${3:-}")"
  exit 0
fi

# Compares with the last name set here, not the session name, so a session the
# user renamed in tmux keeps that name until the title changes again.
if [ "$agent" = sync ]; then
  [ "$target" = tmux ] || exit 0
  no_title "${2:-}" "$(cleared_name "${3:-}")" && exit 0
  session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null) || exit 0
  title=$(ported "${2:-}" "${3:-}")
  [ "$(safe "$title")" = "$(tmux show-options -qv -t "$session" @agent_name)" ] && exit 0
  rename "$title"
  exit 0
fi

command -v jq >/dev/null 2>&1 || exit 0
hook_input=$(cat)

if [ "$agent" = restore ]; then
  [ "$target" = tmux ] || exit 0
  [ "$(printf '%s' "$hook_input" | jq -r '.reason // empty' 2>/dev/null)" = clear ] && exit 0
  session=$(tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null) || exit 0
  orig=$(tmux show-options -qv -t "$session" @agent_orig_name)
  [ -n "$orig" ] || exit 0
  others=$(tmux list-panes -s -t "$session" -F '#{pane_id} #{@agent_state}' |
    awk -v p="$TMUX_PANE" '$1 != p && $2 != ""')
  [ -z "$others" ] || exit 0
  current=$(tmux display-message -p -t "$session" '#{session_name}')
  set_name=$(tmux show-options -qv -t "$session" @agent_name)
  tmux set-option -u -t "$session" @agent_orig_name
  tmux set-option -u -t "$session" @agent_name
  [ "$current" = "$set_name" ] || exit 0
  tmux has-session -t "=$orig" 2>/dev/null && exit 0
  tmux rename-session -t "$session" "$orig" 2>/dev/null
  exit 0
fi

case $agent in
claude)
  transcript=$(printf '%s' "$hook_input" | jq -r '.transcript_path // empty' 2>/dev/null)
  [ -n "$transcript" ] || exit 0
  sid=$(printf '%s' "$hook_input" | jq -r '.session_id // empty' 2>/dev/null)
  haiku_file=${XDG_STATE_HOME:-$HOME/.local/state}/agents/auto-title/$sid.haiku
  cleared=$(cleared_name "$sid")
  # At /clear, auto-title.sh may not have recorded the carried name yet.
  [ "$(printf '%s' "$hook_input" | jq -r '.source // empty' 2>/dev/null)" = clear ] &&
    cleared=$(printf '%s' "$hook_input" | jq -r '.session_title // empty' 2>/dev/null)
  ;;
codex)
  session_id=$(printf '%s' "$hook_input" | jq -r '.session_id // empty' 2>/dev/null)
  [ -n "$session_id" ] || exit 0
  index_file="${CODEX_HOME:-$HOME/.codex}/session_index.jsonl"
  # A detached watcher MUST stop when its Codex process exits or another session
  # takes this pane. Hook timeouts must not bound idle /rename synchronization.
  if [ "$target" = tmux ]; then
    owner=$PPID
    while [ "$owner" -gt 1 ] 2>/dev/null; do
      # macOS reports the interpreter, not the script, as comm for a script
      # started through a shebang (node, python), so also read the arguments.
      process=$(ps -p "$owner" -o comm= 2>/dev/null)
      case $process in
      codex | */codex) ;;
      *)
        read -r first second _ <<EOF
$(ps -p "$owner" -o args= 2>/dev/null)
EOF
        process=
        case $first in
        codex | */codex) process=codex ;;
        node | */node | python* | */python* | */Python | sh | */sh | bash | */bash | env | */env)
          case $second in codex | */codex) process=codex ;; esac
          ;;
        esac
        ;;
      esac
      case $process in
      codex | */codex)
        token="$session_id:$$"
        tmux set-option -p -t "$TMUX_PANE" @codex_title_owner "$token" 2>/dev/null || exit 0
        nohup sh "$0" watch-codex "$session_id" "$owner" "$token" </dev/null >/dev/null 2>&1 &
        exit 0
        ;;
      esac
      owner=$(ps -p "$owner" -o ppid= 2>/dev/null | tr -d ' ')
    done
  fi
  ;;
watch-codex)
  [ "$target" = tmux ] || exit 0
  session_id=${2:-}
  owner=${3:-}
  token=${4:-}
  case $owner in '' | *[!0-9]*) exit 0 ;; esac
  [ -n "$session_id" ] && [ -n "$token" ] || exit 0
  index_file="${CODEX_HOME:-$HOME/.codex}/session_index.jsonl"
  ;;
*)
  echo "agent-tmux-session: unknown agent '$agent'; use claude, codex, or set" >&2
  exit 0
  ;;
esac

# Claude: /rename writes custom-title; it wins over auto-title.sh's Haiku title,
# which wins over Claude's own ai-title.
session_title() {
  if [ "$agent" = claude ]; then
    [ -r "$transcript" ] || return 0
    haiku=
    [ -n "$sid" ] && [ -s "$haiku_file" ] && haiku=$(cat "$haiku_file")
    { IFS= read -r custom; IFS= read -r ai; } <<EOF
$(jq -rn '
      reduce (inputs | select(.type == "custom-title" or .type == "ai-title")) as $e
        ({}; .[$e.type] = ($e.customTitle // $e.aiTitle)) |
      .["custom-title"] // "", .["ai-title"] // ""
    ' "$transcript" 2>/dev/null)
EOF
    no_title "$custom" "$cleared" && custom=
    printf '%s' "${custom:-${haiku:-$ai}}"
    return 0
  fi
  [ -r "$index_file" ] || return 0
  jq -Rnr --arg id "$session_id" '
    reduce (inputs | fromjson? | select(.id == $id and (.thread_name | type) == "string")) as $e
      (""; $e.thread_name)
  ' "$index_file" 2>/dev/null
}

if [ "$agent" = watch-codex ]; then
  last_title=
  while kill -0 "$owner" 2>/dev/null &&
    [ "$(tmux show-options -pqv -t "$TMUX_PANE" @codex_title_owner 2>/dev/null)" = "$token" ]; do
    active=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_active} #{window_active}' 2>/dev/null)
    if [ "$active" = '1 1' ]; then
      title=$(session_title)
      title_pane=$(tmux display-message -p -t "$TMUX_PANE" '#{@codex_title_pane}' 2>/dev/null)
      if [ -n "$title" ] && { [ "$title" != "$last_title" ] || [ "$title_pane" != "$TMUX_PANE" ]; }; then
        [ "$(tmux show-options -pqv -t "$TMUX_PANE" @codex_title_owner 2>/dev/null)" = "$token" ] || break
        session=
        rename "$title"
        [ -z "$session" ] || tmux set-option -t "$session" @codex_title_pane "$TMUX_PANE" 2>/dev/null
        last_title=$title
      fi
    else
      last_title=
    fi
    sleep 1
  done
  if [ "$(tmux show-options -pqv -t "$TMUX_PANE" @codex_title_owner 2>/dev/null)" = "$token" ]; then
    tmux set-option -pu -t "$TMUX_PANE" @codex_title_owner 2>/dev/null
  fi
  exit 0
fi

# The title entry can land just after the hook fires, so retry briefly. A
# Claude session without a title yet is named by its port alone.
attempt=0
while [ "$attempt" -lt 10 ]; do
  title=$(session_title)
  if [ -n "$title" ]; then
    rename "$(ported "$title" "${sid:-}")"
    exit 0
  fi
  attempt=$((attempt + 1))
  sleep 0.1
done
rename "$(ported '' "${sid:-}")"
exit 0
