#!/usr/bin/env bash

if command -v fish 2>/dev/null 1>/dev/null; then
  echo "Updating fisher plugins"
  if [ ! -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update"
  fi
  fish -c "fish_update_completions"
fi

if command -v nvim 2>/dev/null >/dev/null; then
  echo "updating nvim"
  fish -c 'nvim --headless "+Lazy! sync" +qa' 1>/dev/null 2>/deb/null
fi

if cmd_exists tldr; then
  echo "updating tldr"
  fish -c "tldr --update"
fi


if cmd_exists mise; then
  echo "installing mise"
  fish -c "mise install"
fi

if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
  echo "fixing chezmoi config"
  fish -c "chezmoi init"
fi
