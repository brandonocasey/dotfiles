# Command-line tools for every Mac and Linux host.
# Installed by any-linux/run_onchange_before_10-brew-cli.sh.tmpl.

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
# rewrites repository history (the maintained replacement for filter-branch)
brew 'git-filter-repo'
# auto-routes staged hunks into the right commits as fixups (git absorb)
brew 'git-absorb'
# syntactic/AST-aware diff, wired as 'git dft' (delta stays the default pager)
brew 'difftastic'
brew 'neovim'
brew 'ripgrep'
brew 'ripgrep-all'
brew 'python'
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

if OS.mac?
  brew 'opencode'
else
  # On Linux opencode comes from a third-party tap; HOMEBREW_NO_REQUIRE_TAP_TRUST
  # (set in brew-env.sh) lets the bundle use it. Its Linux bottles cover
  # both x86_64 and arm64.
  tap 'anomalyco/tap'
  brew 'anomalyco/tap/opencode'
end

# Tools skipped in the container image to keep it small, installed everywhere else:
#   - heavy media/doc tools (use the host or docker-ffmpeg/docker-ffprobe there)
#   - gcc / docker-buildx: redundant in the container (apt provides cc and the
#     buildx plugin); brew gcc is ~hundreds of MB
#   - act: GitHub-Actions runner, not needed in the dev container
unless ENV['HOMEBREW_RUNNING_IN_DOCKER'] == 'true'
  # keg-only (versioned formula) — installed but NOT auto-symlinked onto PATH as 'ffmpeg'
  brew 'ffmpeg-full'
  brew 'imagemagick'
  brew 'pandoc'
  brew 'aider'
  brew 'gcc'
  brew 'docker-buildx'
  brew 'act'
end
