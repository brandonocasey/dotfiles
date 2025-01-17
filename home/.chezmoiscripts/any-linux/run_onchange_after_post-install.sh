#!/usr/bin/env bash
UNAME="$(uname)"
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
export MANPATH="$MANPATH:./man:/usr/share/man:/usr/local/man:/usr/local/share/man"
OUTPUT=/dev/stdout
if [[ $- == *i* ]]; then
  OUTPUT=/dev/null
fi
cmd_exists() {
  if command -v "$1" 2>/dev/null 1>/dev/null; then
    return 0
  fi

  return 1
}

if cmd_exists mise; then
  echo "installing mise"
  mise install
  eval "$(mise activate bash)"
fi

if cmd_exists "fish"; then
  echo "Updating fisher plugins and fish manuals"
  if [ ! -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update" 1>$OUTPUT
  fi
  fish -c "fish_update_completions" 1>$OUTPUT
fi

if cmd_exists nvim; then
  echo "updating nvim plugins / lsp servers"
  if [ ! -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]; then
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$HOME/.local/share/nvim/lazy/lazy.nvim" 1>$OUTPUT
  fi

  nvim --headless "+Lazy! sync" +qa 1>$OUTPUT
  nvim --headless "+MasonToolsInstallSync" +qall 1>$OUTPUT
  nvim --headless "+MasonToolsUpdateSync" +qall 1>$OUTPUT
fi

if cmd_exists tldro; then
  echo "updating tldr"
  tldr --update
fi

if cmd_exists chezmoi; then
  if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
    echo "writing chezmoi config"
    FILE="$(chezmoi execute-template < "$(chezmoi source-path)/.chezmoi.toml.tmpl")"
    echo "$FILE" > "$HOME/.config/chezmoi/chezmoi.toml"
  fi

  CM_PATH="$(dirname "$(chezmoi source-path)")"
  _cmgit() {
    git -C "$CM_PATH" "$@"
    return $?
  }
  GIT_ORIGIN="$(_cmgit config --get remote.origin.url)"
  if ! echo "$GIT_ORIGIN" | grep -q ssh; then
    echo "changing chezmoi origin to ssh"
    _cmgit remote remove origin
    _cmgit remote add origin "$(echo "$GIT_ORIGIN" | sed 's~https://github.com/~git@github.com:~')"
  fi
  USER_NAME="$(_cmgit config --get user.name)"
  USER_EMAIL="$(_cmgit config --get user.email)"

  if [ -z "$USER_NAME" ]; then
    echo "Setting chezmoi git user.name"
    _cmgit config user.name "Brandon Casey"
  fi

  if [ -z "$USER_EMAIL" ]; then
    echo "Setting chezmoi git user.email"
    _cmgit config user.email "brandonocasey@gmail.com"
  fi

fi
