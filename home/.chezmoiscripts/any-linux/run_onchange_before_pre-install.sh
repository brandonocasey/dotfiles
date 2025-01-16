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
    sleep 5;
  done
else
  install_linux_pkg curl git build-essential
fi

# install brew if not installed
if ! cmd_exists brew; then
  echo "Installing Brew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BUNDLE=$(cat <<EOF
# brew 'gcc'
# brew 'make'
# brew 'act'
brew 'bat'
# brew 'bitwarden-cli'
brew 'chezmoi'
# brew 'choose'
brew 'ctop'
brew 'curl'
brew 'curlie'
brew 'duf'
brew 'dust'
brew 'entr'
brew 'eza'
brew 'fd'
brew 'fish'
# brew 'forgit'
# brew 'gh'
brew 'git'
brew 'git-extras'
brew 'git-delta'
brew 'git-lfs'
# brew 'glow'
# brew 'grex'
# brew 'hyperfine'
# brew 'http-server'
# brew 'lazygit'
brew 'neovim'
brew 'ripgrep'
brew 'tealdeer'
# brew 's-search'
brew 'sd'
brew 'sad'
brew 'vivid'
brew 'wget'
# brew 'xh'
brew 'zoxide'
brew 'wget2'
brew 'mosh'
# brew 'bottom'
# brew 'lazydocker'
# brew 'age'
# brew 'python-setuptools'
brew 'bash'
brew 'tmux'
brew 'mise'
# brew 'moreutils'
brew 'aider'

# tap 'jdx/tap'
# brew 'jdx/tap/usage'

## JSON, YAML, XML, CSV, TOML manipulation
# brew 'dasel'
# or
# brew 'yq'

## Binary parsing on the cli
# tap 'wader/tap'
# brew 'wader/tap/fq'

## html parsing on the cli
# brew 'htmlq'

## dot file cleanup utility
# tap 'doron-cohen/tap'
# brew 'doron-cohen/tap/antidot'

EOF
)


# additional packages for mac only
if [ "$(uname)" = "Darwin" ]; then
BUNDLE+=$(cat <<EOF

tap 'homebrew/cask-fonts'
cask 'font-iosevka-term-slab-nerd-font'

brew 'sijanc147/formulas/macprefs'
brew 'mas'
brew 'mist-cli'

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
cask 'heynote'
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
cask 'vscodium'
cask 'wezterm'
cask 'wireshark'
cask 'zoom'

# App Store applications
mas 'Xcode', id: 497799835
mas 'WireGuard', id: 1451685025

EOF
)
fi

export HOMEBREW_NO_AUTO_UPDATE=1
echo "$BUNDLE" | brew bundle --no-lock --file=/dev/stdin --display-times
brew cleanup --prune=all

if cmd_exists fish; then
  fish_loc="$(which fish)"
  if ! grep -q "$fish_loc" /etc/shells && command -v fish 2>/dev/null >/dev/null; then
    echo "Changing default shell to fish"
    echo "$fish_loc" | $SUDO_ME tee -a '/etc/shells'
    sudo chsh -s "$fish_loc" "$(whoami)"
  fi
fi

if cmd_exists tldr; then
  tldr --update 2>/dev/null 1>/dev/null &
  disown
fi


if cmd_exists mise; then
  mise install 2>/dev/null 1>/dev/null
fi

if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
  chezmoi init
fi
