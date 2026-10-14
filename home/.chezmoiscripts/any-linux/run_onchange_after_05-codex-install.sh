#!/usr/bin/env bash
# Reruns only when this file changes; Codex updates itself between runs.

mkdir -p "$HOME/.local/bin"

# Codex ships an official node-free installer that detects the host architecture.
echo "Installing/updating Codex (official installer)"
curl -fsSL https://chatgpt.com/codex/install.sh | sh || echo "Codex install failed (continuing)"
