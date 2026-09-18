#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin"

installed_skill="$(
  gh skill list --agent codex --scope user --json skillName \
    --jq '.[] | select(.skillName == "frontend-design") | .skillName'
)"

if [[ -n "$installed_skill" ]]; then
  echo "frontend-design is already installed."
  exit 0
fi

gh skill install anthropics/skills skills/frontend-design \
  --agent codex --scope user
