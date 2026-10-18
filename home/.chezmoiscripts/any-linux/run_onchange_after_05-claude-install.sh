#!/usr/bin/env bash
# Reruns when this file changes, e.g. a new version pin, or after a failed run:
# chezmoi records a run_onchange script only when it exits 0.
set -euo pipefail

mkdir -p "$HOME/.local/bin"

# Claude Code uses its native installer on every platform.
# Claude Code is pinned to 2.1.296: from 2.1.299 the managed security plugin bypasses
# context-lean's attachment edits. DISABLE_AUTOUPDATER in the shell env keeps it there.
echo "Installing Claude Code 2.1.296 (native installer)"
installer="$(curl -fsSL https://claude.ai/install.sh)"
bash -s 2.1.296 <<<"$installer"
