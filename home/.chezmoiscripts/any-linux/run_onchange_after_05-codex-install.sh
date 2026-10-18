#!/usr/bin/env bash
# Reruns when this file changes or after a failed run (chezmoi records a
# run_onchange script only when it exits 0); Codex updates itself between runs.
set -euo pipefail

mkdir -p "$HOME/.local/bin"

# Codex ships an official node-free installer that detects the host architecture.
echo "Installing/updating Codex (official installer)"
installer="$(curl -fsSL https://chatgpt.com/codex/install.sh)"
sh <<<"$installer"
