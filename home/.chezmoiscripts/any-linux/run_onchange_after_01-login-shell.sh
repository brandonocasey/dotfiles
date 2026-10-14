#!/usr/bin/env bash
# Makes the brew-installed fish the login shell. The Dockerfile does this itself.
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin"

if [ "$RUNNING_IN_DOCKER" != "true" ] && command -v fish >/dev/null 2>&1; then
  fish_loc="$(command -v fish)"
  if ! grep -q "$fish_loc" /etc/shells; then
    echo "Changing default shell to fish"
    echo "$fish_loc" | sudo tee -a '/etc/shells'
    sudo chsh -s "$fish_loc" "$(whoami)"
  fi
fi
