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

SUDO_ME=""
if cmd_exists sudo; then
  SUDO_ME="sudo"
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

BUNDLE=$(
  cat <<EOF
brew 'gcc'
brew 'bat'
brew 'chezmoi'
brew 'curlie'
brew 'duf'
brew 'dust'
brew 'entr'
brew 'eza'
brew 'fd'
brew 'fish'
brew 'fzf'
brew 'git'
brew 'git-extras'
brew 'git-delta'
brew 'git-lfs'
brew 'neovim'
brew 'ripgrep'
brew 'ripgrep-all'
brew 'sd'
brew 'sad'
brew 'vivid'
brew 'zoxide'
brew 'wget2'
brew 'tmux'
brew 'mise'
brew 'rsync'
brew 'ast-grep'
brew 'luajit'

cask 'claude-code'

brew 'tealdeer'
brew 'mosh'
brew 'bottom'
brew 'bash'
brew 'aider'
brew 'make'
brew 'act'
brew 'bitwarden-cli'
brew 'wget'
brew 'ctop'
brew 'curl'
brew 'gh'
brew 'grex'
brew 'http-server'
brew 'ctop'
brew 's-search'
brew 'lazygit'
brew 'lazydocker'
brew 'docker-buildx'
brew 'imagemagick'
brew 'ffmpeg'

## JSON, YAML, XML, CSV, TOML manipulation
brew 'dasel'
# or
# brew 'yq'

## Binary parsing on the cli
tap 'wader/tap'
brew 'wader/tap/fq'

## html parsing on the cli
brew 'htmlq'

## dot file cleanup utility
## unsupported on arm
#tap 'doron-cohen/tap'
#brew 'doron-cohen/tap/antidot'
tap 'peterldowns/tap'
brew 'peterldowns/tap/localias'

EOF
)

# additional packages for mac only
if [ "$(uname)" = "Darwin" ]; then
  BUNDLE+=$(
    cat <<EOF

cask 'font-iosevka-term-nerd-font'

brew 'reattach-to-user-namespace'
brew 'dockutil'
brew 'mas'
brew 'mist-cli'
brew 'trash'
brew 'coreutils'

tap 'OJFord/formulae'
brew 'loginitems'

# Applications
# tap 'homebrew/cask'
cask 'android-platform-tools'
cask 'balenaetcher'
cask 'brave-browser'
cask 'browserstacklocal'
cask 'calibre'
cask 'charles'
cask 'docker'
cask 'firefox'
cask 'google-chrome'
cask 'grandperspective'
cask 'hammerspoon'
cask 'hex-fiend'
cask 'imageoptim'
cask 'karabiner-elements'
cask 'keka'
cask 'linearmouse'
cask 'microsoft-edge'
cask 'openvpn-connect'
cask 'plex'
cask 'plexamp'
cask 'postman'
cask 'rectangle'
cask 'replay'
cask 'speedcrunch'
cask 'spotify'
cask 'sublime-text'
cask 'vlc'
cask 'visual-studio-code'
cask 'wezterm'
cask 'ghostty'
cask 'wireshark'
cask 'openinterminal'
cask 'ollama'

# App Store applications
mas 'Xcode', id: 497799835
mas 'WireGuard', id: 1451685025

EOF
  )
fi

export HOMEBREW_NO_AUTO_UPDATE=1
echo "$BUNDLE" | brew bundle --cleanup --file=/dev/stdin
brew cleanup --prune=all

if [ "$RUNNING_IN_DOCKER" != "true" ] && cmd_exists fish; then
  fish_loc="$(which fish)"
  if ! grep -q "$fish_loc" /etc/shells && command -v fish 2>/dev/null >/dev/null; then
    echo "Changing default shell to fish"
    echo "$fish_loc" | $SUDO_ME tee -a '/etc/shells'
    sudo chsh -s "$fish_loc" "$(whoami)"
  fi
fi
