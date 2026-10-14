# Shared setup for the brew bundle scripts. Sourced, not run.
# chezmoi skips this dot-folder, so the Brewfiles here are never applied.

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"

export HOMEBREW_NO_AUTO_UPDATE=1
# Only install missing packages; never upgrade outdated ones here. Upgrades
# are manual via `brew upgrade` so a Brewfile edit stays fast.
export HOMEBREW_BUNDLE_NO_UPGRADE=1
# Homebrew 6 refuses formulae from third-party taps (wader, anomalyco, …) and
# aborts the entire bundle on the first one. These are taps we deliberately use,
# so opt out of the trust requirement for the bundle.
export HOMEBREW_NO_REQUIRE_TAP_TRUST=1
# brew clears every variable without a HOMEBREW_ prefix before it reads a
# Brewfile, so pass the container flag through under that prefix.
export HOMEBREW_RUNNING_IN_DOCKER="${RUNNING_IN_DOCKER:-}"

# chezmoi sets CHEZMOI_SOURCE_DIR; the Dockerfile sets it the same way.
BREW_DIR="$CHEZMOI_SOURCE_DIR/.chezmoiscripts/.brew"

# Path of the named Brewfile, e.g. `brewfile cli`.
brewfile() {
  printf '%s/%s.Brewfile' "$BREW_DIR" "$1"
}

# Install whatever the named Brewfile lists but the host lacks.
brew_bundle_install() {
  # `check` is seconds when nothing is missing; skip the slow install then.
  # One bad entry (e.g. a cask Homebrew disabled) fails the whole bundle. Warn
  # instead of failing, so it never blocks the rest of `chezmoi apply`.
  if ! brew bundle check --file="$(brewfile "$1")"; then
    brew bundle install --file="$(brewfile "$1")" ||
      echo "brew bundle install for $1.Brewfile failed (continuing)" >&2
  fi
}
