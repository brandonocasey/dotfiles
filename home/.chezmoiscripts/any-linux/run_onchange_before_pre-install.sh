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
  # Prime sudo once, then refresh the cached credential in the background so
  # sudo-backed steps (apt/yum/pacman, chsh) don't re-prompt.
  sudo -v
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

BUNDLE=$(
  cat <<EOF
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
# auto-routes staged hunks into the right commits as fixups (git absorb)
brew 'git-absorb'
# syntactic/AST-aware diff, wired as 'git dft' (delta stays the default pager)
brew 'difftastic'
brew 'neovim'
brew 'ripgrep'
brew 'ripgrep-all'
brew 'sd'
brew 'sad'
brew 'vivid'
brew 'zoxide'
brew 'wget2'
brew 'tmux'
# smart tmux session manager (zoxide + fzf aware), bound to prefix+T
brew 'sesh'
brew 'mise'
brew 'rsync'
brew 'ast-grep'
brew 'luajit'
brew 'shellcheck'
# shell formatter to pair with shellcheck
brew 'shfmt'
brew 'pass'

brew 'tealdeer'
brew 'mosh'
brew 'bottom'
brew 'hyperfine'
# multi-shell completion engine (hundreds of CLIs), bridges into fish
brew 'carapace'
# universal archive (de)compression front-end
brew 'ouch'
brew 'bash'
brew 'make'
brew 'bitwarden-cli'
brew 'wget'
brew 'ctop'
brew 'curl'
brew 'gh'
brew 'grex'
brew 'http-server'
brew 's-search'
brew 'lazygit'
brew 'lazydocker'
brew 'luarocks'
brew 'forgejo-cli'
brew 'glab'
brew 'cloc'
brew 'media-info'
brew 'yt-dlp'

## JSON, YAML, XML, CSV, TOML manipulation
brew 'jq'
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

EOF
)

# additional packages for mac only
if [ "$(uname)" = "Darwin" ]; then
  BUNDLE+=$(
    cat <<EOF

cask 'font-iosevka-term-nerd-font'

# Claude Code: cask on macOS, native installer on Linux (see below)
cask 'claude-code@latest'
# codex: cask on macOS (no brew formula; Linux uses a release binary, see below)
cask 'codex'
# Cursor CLI: cask on macOS, official installer on Linux (see below)
cask 'cursor-cli'
# Antigravity CLI: macOS-only (no standalone Linux CLI; it ships inside the IDE)
cask 'antigravity-cli'

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
cask 'docker-desktop'
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
cask 'ghostty'
cask 'wireshark-app'
cask 'openinterminal'

# App Store applications
mas 'Xcode', id: 497799835
mas 'WireGuard', id: 1451685025

EOF
  )
fi

# additional packages for Linux only
if [ "$UNAME" = "Linux" ]; then
  BUNDLE+=$(
    cat <<EOF

# opencode lives only in a third-party tap; HOMEBREW_NO_REQUIRE_TAP_TRUST (set
# below) lets the bundle use it. Its Linux bottles cover both x86_64 and arm64.
tap 'anomalyco/tap'
brew 'anomalyco/tap/opencode'
EOF
  )
fi

# Tools skipped in the container image to keep it small, installed everywhere else:
#   - heavy media/doc tools (use the host or docker-ffmpeg/docker-ffprobe there)
#   - gcc / docker-buildx: redundant in the container (apt provides cc and the
#     buildx plugin); brew gcc is ~hundreds of MB
#   - act / localias: GitHub-Actions runner and local DNS aliasing, not needed
#     in the dev container
if [ "$RUNNING_IN_DOCKER" != "true" ]; then
  BUNDLE+=$(
    cat <<EOF

# keg-only (versioned formula) — installed but NOT auto-symlinked onto PATH as 'ffmpeg'
brew 'ffmpeg-full'
brew 'imagemagick'
brew 'pandoc'
brew 'aider'
brew 'gcc'
brew 'docker-buildx'
brew 'act'
tap 'peterldowns/tap'
brew 'peterldowns/tap/localias'
EOF
  )
fi

export HOMEBREW_NO_AUTO_UPDATE=1
# Homebrew 6 refuses formulae from third-party taps (wader, peterldowns, …) and
# aborts the entire bundle on the first one. These are taps we deliberately use,
# so opt out of the trust requirement for the bundle.
export HOMEBREW_NO_REQUIRE_TAP_TRUST=1

# Write a real Brewfile: `brew bundle` reads the file twice (install, then
# cleanup), and a /dev/stdin pipe is empty on the second read, which makes
# cleanup uninstall everything it just installed.
BREWFILE="$(mktemp)"
printf '%s\n' "$BUNDLE" > "$BREWFILE"
# The `brew bundle --cleanup` switch is deprecated, so run install and the
# cleanup subcommand separately; `cleanup --force` prunes anything not listed.
brew bundle install --file="$BREWFILE"
brew bundle cleanup --force --file="$BREWFILE"
rm -f "$BREWFILE"
brew cleanup --prune=all

# Homebrew casks are macOS-only, so install Claude Code natively on Linux.
# No install guard: re-run every apply so it self-updates to the latest release.
if [ "$UNAME" = "Linux" ]; then
  echo "Installing/updating Claude Code (native installer)"
  curl -fsSL https://claude.ai/install.sh | bash || echo "Claude Code install failed (continuing)"
fi

# `codex` has no Linux brew formula and Cursor's CLI is a macOS-only cask, so on
# Linux install both natively. opencode now comes from the brew bundle above (its
# tap ships Linux bottles). No guards: all re-pull the latest each run.
if [ "$UNAME" = "Linux" ]; then
  mkdir -p "$HOME/.local/bin"

  # codex ships an official node-free installer (arch-aware, always latest).
  echo "Installing/updating codex (official installer)"
  curl -fsSL https://chatgpt.com/codex/install.sh | sh || echo "codex install failed (continuing)"

  # Cursor CLI: official installer, handles Linux x86_64 and arm64.
  echo "Installing/updating Cursor CLI (official installer)"
  curl -fsSL https://cursor.com/install | bash || echo "cursor install failed (continuing)"
fi

if [ "$RUNNING_IN_DOCKER" != "true" ] && cmd_exists fish; then
  fish_loc="$(which fish)"
  if ! grep -q "$fish_loc" /etc/shells && command -v fish 2>/dev/null >/dev/null; then
    echo "Changing default shell to fish"
    echo "$fish_loc" | $SUDO_ME tee -a '/etc/shells'
    sudo chsh -s "$fish_loc" "$(whoami)"
  fi
fi
