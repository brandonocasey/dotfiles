# shellcheck shell=bash
UNAME="$(uname)"
PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
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

if [ "$UNAME" = "Darwin" ]; then
  xcode-select --install 2>/dev/null 1>/dev/null
  # Wait until XCode Command Line Tools installation has finished.
  until xcode-select -p 1>/dev/null 2>/dev/null; do
    echo "Waiting for xcode command line tools to finish installing"
    sleep 5;
  done
elif ! cmd_exists curl || !cmd_exists git; then
  install_linux_pkg curl git
fi
