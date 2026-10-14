#!/usr/bin/env bash
# Base toolchain and Homebrew itself. Packages live in ../.brew/*.Brewfile and
# install from their own scripts, so a package edit never reruns this.
UNAME="$(uname)"
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
export MANPATH="$MANPATH:./man:/usr/share/man:/usr/local/man:/usr/local/share/man"
cmd_exists() {
  if command -v "$1" 2>/dev/null 1>/dev/null; then
    return 0
  fi

  return 1
}

SUDO_ME=""
if cmd_exists sudo; then
  SUDO_ME="sudo"
  # Prime sudo once, then refresh the cached credential in the background so
  # the apt/yum/pacman and Homebrew installs below don't re-prompt.
  if ! sudo -n true 2>/dev/null; then
    sudo -v
  fi
  while true; do
    sudo -n true 2>/dev/null
    sleep 50
    kill -0 "$$" 2>/dev/null || exit
  done &
fi

install_linux_pkg() {
  if [ "$UNAME" = "Linux" ]; then
    if cmd_exists apt-get; then
      $SUDO_ME apt-get -y update && $SUDO_ME apt-get install -y "$@"
    elif cmd_exists yum; then
      $SUDO_ME yum install -y "$@"
    elif cmd_exists pacman; then
      $SUDO_ME pacman -S --no-confirm "$@"
    fi
  fi
}

if [ "$UNAME" = "Darwin" ]; then
  xcode-select --install 2>/dev/null 1>/dev/null
  # Wait until XCode Command Line Tools installation has finished.
  until xcode-select -p 1>/dev/null 2>/dev/null; do
    echo "Waiting for xcode command line tools to finish installing"
    sleep 5
  done
else
  install_linux_pkg curl git build-essential xsel unzip
fi

# install brew if not installed
if ! cmd_exists brew; then
  echo "Installing Brew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
