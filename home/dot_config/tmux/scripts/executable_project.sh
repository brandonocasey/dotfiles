#!/bin/sh
# tmux status: the active pane's project as "project#branch", like the Claude
# Code status line. The project (green) is the git repository root, so
# worktrees name the parent repo; outside git it is the directory name. The
# branch (white) is hidden on the default branch. Usage: project.sh <path>
dir=${1:-$PWD}
cd "$dir" 2>/dev/null || exit 0
name=
branch=
if common=$(git --no-optional-locks rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  if [ "$(basename "$common")" = .git ]; then
    name=$(basename "$(cd "$common/.." && pwd -P)")
  else
    # Bare repo: the gitdir itself is the project (e.g. "web-player.git").
    name=$(basename "$common" .git)
  fi
  branch=$(git --no-optional-locks branch --show-current 2>/dev/null)
  [ -n "$branch" ] || branch=detached
  default=$(git --no-optional-locks symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)
  default=${default#origin/}
  if [ -n "$default" ]; then
    [ "$branch" = "$default" ] && branch=
  else
    case $branch in master | main | develop | dev) branch= ;; esac
  fi
elif [ "$dir" = "$HOME" ]; then
  name=HOME
else
  name=$(basename "$dir")
fi
# tmux reads '##' as a literal '#'.
printf '#[fg=green]%s' "$name"
[ -z "$branch" ] || printf '#[fg=colour245]###[fg=brightwhite]%s' "$branch"
