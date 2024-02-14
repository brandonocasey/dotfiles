#!/usr/bin/env bash

cmd_exists() {
  if command -v "$1" 2>/dev/null 1>/dev/null; then
    return 0
  fi

  return 1
}
UNAME="$(uname)"
PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"

if ! cmd_exists curl || ! cmd_exists git; then
  echo "Installing git/curl"
  if cmd_exists apt-get; then
    sudo apt-get install curl git
  elif cmd_exists yum; then
    sudo yum install curl git
  elif cmd_exists pacman; then
    sudo pacman -S curl git
  fi
fi
