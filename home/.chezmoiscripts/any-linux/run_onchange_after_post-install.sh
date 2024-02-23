#!/usr/bin/env bash
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
if [ ! -d "$HOME/.local/share/vale/styles" ]; then
  vale --config="$HOME/.config/vale/vale.ini" sync
fi
