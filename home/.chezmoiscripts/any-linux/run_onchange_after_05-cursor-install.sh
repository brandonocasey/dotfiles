#!/usr/bin/env bash
# Reruns when this file changes or after a failed run: chezmoi records a
# run_onchange script only when it exits 0.
set -euo pipefail

# Cursor's CLI is a macOS cask (see mac.Brewfile), so install it natively on Linux.
if [ "$(uname)" = "Linux" ]; then
  mkdir -p "$HOME/.local/bin"
  echo "Installing/updating Cursor CLI (official installer)"
  installer="$(curl -fsSL https://cursor.com/install)"
  bash <<<"$installer"
fi
