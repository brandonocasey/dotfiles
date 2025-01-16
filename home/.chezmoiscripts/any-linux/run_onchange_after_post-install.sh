#!/usr/bin/env bash

if command -v fish 2>/dev/null 1>/dev/null; then
  echo "Updating fisher plugins"
  if [ ! -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update"
  fi
  fish -c "fish_update_completions"
fi

if command -v nvim 2>/dev/null >/dev/null; then
  nvim --headless "+Lazy! sync" +qa
fi
