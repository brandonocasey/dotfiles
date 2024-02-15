# shellcheck shell=bash
UNAME="$(uname)"
cmd_exists() {
  if command -v "$1" 2>/dev/null 1>/dev/null; then
    return 0
  fi

  return 1
}

install_linux_pkg() {
  if [ "$UNAME" = "Linux" ]; then
    if cmd_exists apt-get; then
      sudo apt-get update && sudo apt-get install -y "$@"
    elif cmd_exists yum; then
      sudo yum install -y "$@"
    elif cmd_exists pacman; then
      sudo pacman -S --no-confirm "$@"
    fi
  fi
}

brew_shellenv() {
  local brew_locs=("/usr/local" "/opt/homebrew" "/home/linuxbrew/.linuxbrew")
  local loc

  for loc in "${brew_locs[@]}"; do
    if [ -s "$loc/bin/brew" ]; then
      eval "$("$loc/bin/brew" shellenv)"
      return 0
    fi
  done
  
  return 1
}

brew_shellenv


if [ "$UNAME" = "Darwin" ]; then
  xcode-select --install 2>/dev/null 1>/dev/null
  # Wait until XCode Command Line Tools installation has finished.
  until xcode-select -p 1>/dev/null 2>/dev/null; do
    echo "Waiting for xcode command line tools to finish installing"
    sleep 5;
  done
else
  install_linux_pkg curl git make gcc
fi
