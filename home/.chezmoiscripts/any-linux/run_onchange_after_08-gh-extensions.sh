#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin"

# gh stack links dependent pull requests into a GitHub stack and merges them in one step.
if gh extension list | grep -q 'github/gh-stack'; then
  echo "gh-stack is already installed."
  exit 0
fi

gh extension install github/gh-stack
