#!/usr/bin/env bash
# Reruns only when this file changes, e.g. a new version pin.

mkdir -p "$HOME/.local/bin"

# Claude Code uses its native installer on every platform.
# Claude Code is pinned to 2.1.296: from 2.1.299 the managed security plugin bypasses
# context-lean's attachment edits. DISABLE_AUTOUPDATER in the shell env keeps it there.
echo "Installing Claude Code 2.1.296 (native installer)"
curl -fsSL https://claude.ai/install.sh | bash -s 2.1.296 || echo "Claude Code install failed (continuing)"
