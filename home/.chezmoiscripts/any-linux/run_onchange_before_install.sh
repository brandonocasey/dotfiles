#!/usr/bin/env bash
source "$(chezmoi source-path)/.chezmoiscripts/.script-env.sh"

# install brew if not installed
if ! cmd_exists brew; then
  echo "Installing Brew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BUNDLE=$(cat <<EOF
brew 'act'
brew 'asdf'
brew 'bat'
brew 'gcc'
brew 'make'
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

tap 'wader/tap'
brew 'wader/tap/fq'

tap 'doron-cohen/tap'
brew 'doron-cohen/tap/antidot'

tap 'simonhammes/mcfly-fzf'
brew 'simonhammes/mcfly-fzf/mcfly-fzf'

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

if cmd_exists asdf; then
  plugin_list="$(asdf plugin-list)"
  while read -r p; do
    plugin_name="${p%%[[:space:]]*}"
    if ! echo "$plugin_list" | grep -q "$plugin_name"; then
      echo "Installing asdf plugin $plugin_name"
      asdf plugin-add "$plugin_name"
      asdf install "$plugin_name"
      if [ "$plugin_name" = "direnv" ]; then
        asdf direnv setup --shell fish --version latest
      fi
    fi
  done < ~/.tool-versions
fi

if [ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
  chezmoi init
fi
