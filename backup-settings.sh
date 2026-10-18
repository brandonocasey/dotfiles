#!/usr/bin/env bash
# Backs up shell state, SSH and local Git config, and ~/Projects (without
# node_modules) to a zip in ~/Downloads. Source files are never modified.
set -euo pipefail

BACKUP_NAME="$(date +%Y%m%d-%H%M%S)-chezmoi-dotfiles-backup"
BACKUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/$BACKUP_NAME.XXXXXX")"
BACKUP_ZIP="$HOME/Downloads/$BACKUP_NAME.zip"
echo "Backing up to $BACKUP_DIR"

# Remove staging only after the zip is written. On failure keep it, so nothing
# already copied is lost.
cleanup() {
  status=$?
  if [ "$status" -eq 0 ]; then
    rm -rf "$BACKUP_DIR"
  else
    echo "Backup failed (exit $status); staged files kept in $BACKUP_DIR" >&2
  fi
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Copy SRC into the staging directory DEST; skip sources this host lacks.
_rsync() {
  if [ ! -e "$1" ]; then
    echo "Skipping missing $1"
    return
  fi
  mkdir -p "$BACKUP_DIR/$2"
  rsync -avhr --stats --links --human-readable -P "${@:3}" "$1" "$BACKUP_DIR/$2"
}

_rsync ~/.local/share/zoxide .local/share/
_rsync ~/.local/share/fish/fish_history .local/share/fish/
_rsync ~/.ssh ./
_rsync ~/.config/git/local .config/git/
_rsync ~/Projects ./ --exclude=node_modules/

echo "Creating zip file at $BACKUP_ZIP"
mkdir -p "$(dirname "$BACKUP_ZIP")"
cd "$BACKUP_DIR"
zip -9 -mrv --symlinks "$BACKUP_ZIP" "."
echo "Created zip file at $BACKUP_ZIP"
