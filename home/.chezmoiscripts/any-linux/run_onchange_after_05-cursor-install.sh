#!/usr/bin/env bash
# Reruns only when this file changes.

# Cursor's CLI is a macOS cask (see mac.Brewfile), so install it natively on Linux.
if [ "$(uname)" = "Linux" ]; then
  mkdir -p "$HOME/.local/bin"
  echo "Installing/updating Cursor CLI (official installer)"
  curl -fsSL https://cursor.com/install | bash || echo "Cursor install failed (continuing)"
fi
