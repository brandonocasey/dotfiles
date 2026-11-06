#!/bin/sh
# Feeds the sesh picker (sesh-pick.sh). Colors each tmux session's
# name with its @session_color, as in the status line, and adds its
# agent state after the name, colored like the window list: a red ●
# when any pane needs input, else a yellow ● when any pane waits with
# background work running, else a green ● when any pane works. Then
# come its project (green, from project.sh on the active pane's directory)
# and the agents it runs (claude, codex), from tmux.conf's @agent_tool.
# It reads the state from the colors in tmux.conf's @agent_status; keep them in
# sync. The state follows a tab, so the picker passes only the part before it on.
# Usage: sesh-list.sh list [sesh list flags]
#        sesh-list.sh kill <picker line>
case ${1:-} in
kill)
  name=$(printf '%s\n' "$2" | cut -f1)
  name=${name#* }
  tmux kill-session -t "=$name"
  ;;
list)
  shift
  # One tmux call and one awk pass: under heavy CPU load, each extra
  # process per line made the picker wait seconds for its list.
  panes=$(tmux list-panes -a -F '#{session_name}	#{session_created}	#{@session_color}	#{E:@agent_status}	#{E:@agent_tool}	#{?#{&&:#{window_active},#{pane_active}},#{pane_current_path},}' 2>/dev/null)
  # One project.sh run per distinct directory, not per session.
  projects=$(printf '%s\n' "$panes" | cut -f6 | sort -u | while IFS= read -r d; do
    [ -z "$d" ] || printf '%s\t%s\n' "$d" "$(sh "$(dirname "$0")/project.sh" --name "$d")"
  done)
  # sesh sorts tmux sessions by activity, so they jump around on every
  # switch. Put them in a fixed order (by creation time); other entries keep theirs.
  sesh list "$@" | PANES=$panes PROJECTS=$projects awk '
    function hex(h) {
      return (index("0123456789abcdef", substr(h, 1, 1)) - 1) * 16 + index("0123456789abcdef", substr(h, 2, 1)) - 1
    }
    BEGIN {
      n = split(ENVIRON["PROJECTS"], p, "\n")
      for (i = 1; i <= n; i++) {
        split(p[i], f, "\t")
        project[f[1]] = f[2]
      }
      n = split(ENVIRON["PANES"], p, "\n")
      for (i = 1; i <= n; i++) {
        split(p[i], f, "\t")
        s = f[1]
        created[s] = f[2]
        color[s] = tolower(f[3])
        if (f[4] ~ /D70000/) state[s] = "input"
        else if (f[4] ~ /D7AF00/ && state[s] != "input") state[s] = "background"
        else if (f[4] ~ /5FD700/ && state[s] == "") state[s] = "working"
        if (f[6] != "") proj[s] = project[f[6]]
        if (f[5] != "" && !((s, f[5]) in seen)) {
          seen[s, f[5]] = 1
          used[s] = used[s] (used[s] == "" ? "" : " ") f[5]
        }
      }
    }
    {
      line = $0
      name = line
      gsub(/\033\[[0-9;]*m/, "", name)
      sub(/^[^ ]* /, "", name)
      c = color[name]
      if (c ~ /^#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$/ && substr(line, length(line) - length(name) + 1) == name)
        line = sprintf("%s\033[38;2;%d;%d;%dm%s\033[39m", substr(line, 1, length(line) - length(name)),
          hex(substr(c, 2, 2)), hex(substr(c, 4, 2)), hex(substr(c, 6, 2)), name)
      dot = ""
      if (state[name] == "input") dot = "\033[38;5;160m● "
      else if (state[name] == "background") dot = "\033[38;5;178m● "
      else if (state[name] == "working") dot = "\033[38;5;76m● "
      key = (name in created) ? created[name] : 10000000000 + NR
      pr = proj[name] == "" ? "" : "\033[38;5;76m" proj[name] (used[name] == "" ? "" : " ")
      if (dot pr used[name] != "")
        printf "%s\t%s\t%s%s\033[38;5;245m%s\033[0m\n", key, line, dot, pr, used[name]
      else
        printf "%s\t%s\n", key, line
    }' | sort -n -s -k1,1 | cut -f2-
  ;;
*) exit 2 ;;
esac
