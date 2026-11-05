#!/bin/sh
# Hook shells may find a system client incompatible with the Homebrew server.
for candidate in /opt/homebrew/bin/tmux /home/linuxbrew/.linuxbrew/bin/tmux /usr/local/bin/tmux "$(command -v tmux || true)"; do
  [ -x "$candidate" ] || continue
  "$candidate" list-sessions >/dev/null 2>&1 || continue
  printf '%s\n' "$candidate"
  exit 0
done
exit 1
