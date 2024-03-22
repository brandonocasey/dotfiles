#!/usr/bin/env bash
UNAME="$(uname)"
export PATH="$PATH:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
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
else
  install_linux_pkg curl git build-essential
fi

# install brew if not installed
if ! cmd_exists brew; then
  echo "Installing Brew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BUNDLE=$(cat <<EOF
brew 'gcc'
brew 'make'
brew 'act'
brew 'bat'
brew 'bitwarden-cli'
brew 'chezmoi'
brew 'choose'
brew 'ctop'
brew 'curl'
brew 'curlie'
brew 'dasel'
brew 'duf'
brew 'dust'
brew 'entr'
brew 'eza'
brew 'fd'
brew 'fish'
brew 'forgit'
brew 'gh'
brew 'git'
brew 'git-extras'
brew 'git-delta'
brew 'git-lfs'
brew 'glow'
brew 'grex'
brew 'hyperfine'
brew 'http-server'
brew 'lazygit'
brew 'neovim'
brew 'nnn'
brew 'parallel'
brew 'ripgrep'
brew 'tealdeer'
brew 's-search'
brew 'sd'
brew 'sad'
brew 'vifm'
brew 'vivid'
brew 'wget'
brew 'xh'
brew 'zoxide'
brew 'wget2'
brew 'mosh'
brew 'bottom'
brew 'lazydocker'
brew 'age'
brew 'python-setuptools'
brew 'bash'
brew 'tmux'
brew 'mise'
brew 'htmlq'
brew 'yq'


tap 'jdx/tap'
brew 'jdx/tap/usage'

tap 'wader/tap'
brew 'wader/tap/fq'

tap 'doron-cohen/tap'
brew 'doron-cohen/tap/antidot'

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
cask 'devutils'
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

EOF
)
fi

export HOMEBREW_NO_AUTO_UPDATE=1
echo "$BUNDLE" | brew bundle --no-lock --file=/dev/stdin

if cmd_exists fish; then
  fish -c "fish_update_completions" 2>/dev/null 1>/dev/null &
  disown
  fish_loc="$(which fish)"
  if ! grep -q "$fish_loc" /etc/shells && command -v fish 2>/dev/null >/dev/null; then
    echo "Changing default shell to fish"
    echo "$fish_loc" | sudo tee -a '/etc/shells'
    chsh -s "$fish_loc"
  fi

fi

if cmd_exists tldr; then
  tldr --update 2>/dev/null 1>/dev/null &
  disown
fi


if [ ! -d ~/.config/nvim/.git ]; then
  mkdir -p ~/.config/nvim
  git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
  nvim --headless +qall 2>/dev/null 1>/dev/null &
  nvim --headless +MasonInstallAll +qall 2>/dev/null 1>/dev/null &
  disown
fi

if cmd_exists mise; then
  mise install 2>/dev/null 1>/dev/null
fi

if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
  chezmoi init
fi
