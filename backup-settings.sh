BACKUP_NAME="$RANDOM-chezmoi-dotfiles-backup"
BACKUP_DIR="/tmp/$BACKUP_NAME"
BACKUP_ZIP="$HOME/Downloads/$BACKUP_NAME.zip"
echo "Backing up to $BACKUP_DIR"

cleanup() {
  if command -v trash 2>/dev/null 1>/dev/null; then
    trash "$BACKUP_DIR"
  else
    rm -rf "$BACKUP_DIR"
  fi
}

trap cleanup SIGINT
trap cleanup SIGTERM
trap cleanup SIGHUP
trap cleanup EXIT

_rsync() {
  rsync -avhr --stats --links --human-readable -P "$@"
}

mkdir -p "$BACKUP_DIR/.local/share/fish"
_rsync ~/.local/share/zoxide "$BACKUP_DIR/.local/share/"
_rsync ~/.local/share/fish/fish_history "$BACKUP_DIR/.local/share/fish/fish_history"

find ~/Projects -name node_modules -type d -prune -exec trash {} +
_rsync ~/Projects "$BACKUP_DIR/"
echo "Creating zip file at $BACKUP_ZIP"
cd "$BACKUP_DIR"

zip -9 -mrv --symlinks "$BACKUP_ZIP" "."
echo "Created zip file at $BACKUP_ZIP"
