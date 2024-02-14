#!/usr/bin/env bash

cmd_exists() {
  if command -v "$1" 2>/dev/null 1>/dev/null; then
    return 0
  fi

  return 1
}
PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"

echo "Installing linux packages"
if cmd_exists apt-get; then
  sudo apt-get update && sudo apt-get install -y gcc make flatpak gnome-software-plugin-flatpak
elif cmd_exists yum; then
  sudo yum install -y curl gcc make
  echo "TODO: this distro is mostly untested"
elif cmd_exists pacman; then
  sudo pacman -S --no-confirm gcc make
  echo "TODO: this distro is mostly untested"
fi

if cmd_exists flatpak; then
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install flathub org.wezfurlong.wezterm
fi
