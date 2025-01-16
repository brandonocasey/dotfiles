#!/usr/bin/env bash
UNAME="$(uname)"
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
export MANPATH="$MANPATH:./man:/usr/share/man:/usr/local/man:/usr/local/share/man"
cmd_exists() {
  if command -v "$1" 2>/dev/null 1>/dev/null; then
    return 0
  fi

  return 1
}

if cmd_exists mise; then
  echo "installing mise"
  mise install
  eval "$(~/.local/bin/mise activate bash)"
fi

if cmd_exists "fish"; then
  echo "Updating fisher plugins"
  if [ ! -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update" 1>/dev/null
  fi
  fish -c "fish_update_completions" 1>/dev/null
fi

if cmd_exists nvim; then
  echo "updating nvim"
  if [ ! -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]; then
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$HOME/.local/share/nvim/lazy/lazy.nvim" 1>/dev/null
  fi

  nvim --headless "+Lazy! sync" +qa 1>/dev/null
  nvim --headless "+MasonToolsInstallSync" +qall 1>/dev/null
fi

if cmd_exists tldr; then
  echo "updating tldr"
  tldr --update
fi


if cmd_exists chezmoi; then
  if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
    echo "fixing chezmoi config"
    chezmoi init
  fi
fi
