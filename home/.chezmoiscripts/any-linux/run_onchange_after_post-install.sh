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
  if [ ! -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]; then
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$HOME/.local/share/nvim/lazy/lazy.nvim"
  fi

  fish -c 'nvim --headless "+Lazy! sync" +qa'
  fish -c 'nvim --headless "+MasonUpdateAll" +qa'
fi

if command -v tldr 2>/dev/null >/dev/null; then
  echo "updating tldr"
  fish -c "tldr --update"
fi


if command -v mise 2>/dev/null >/dev/null; then
  echo "installing mise"
  fish -c "mise install"
fi

if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
  echo "fixing chezmoi config"
  fish -c "chezmoi init"
fi
