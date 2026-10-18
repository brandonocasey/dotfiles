#!/usr/bin/env bash
# Makes the brew-installed fish the login shell. The Dockerfile does this itself.
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin"

# Current login shell of USER: getent on Linux, Directory Services on macOS.
login_shell() {
  if command -v getent >/dev/null 2>&1; then
    getent passwd "$1" | cut -d: -f7
  else
    dscl . -read "/Users/$1" UserShell | awk '{print $2}'
  fi
}

if [ "$RUNNING_IN_DOCKER" != "true" ] && command -v fish >/dev/null 2>&1; then
  fish_loc="$(command -v fish)"
  user="$(whoami)"
  # chsh only accepts shells listed in /etc/shells.
  if ! grep -qxF "$fish_loc" /etc/shells; then
    echo "$fish_loc" | sudo tee -a '/etc/shells'
  fi
  if [ "$(login_shell "$user")" != "$fish_loc" ]; then
    echo "Changing default shell to fish"
    sudo chsh -s "$fish_loc" "$user"
  fi
fi
