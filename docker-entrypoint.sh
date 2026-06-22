#!/usr/bin/env bash
# Container entrypoint: make node/npx available, seed Claude config into the
# bind-mounted state dir, allow access to a mounted Docker socket, register the
# chrome-devtools MCP server, then run the requested command. Every step is
# best-effort: nothing here may stop the container from starting.

export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

# Activate mise so the node/npx that Claude launches MCP servers with is on PATH.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)" 2>/dev/null || true
fi

# Consolidate all persistent state under one (bind-mountable) dir: ~/state.
STATE_DIR="${STATE_DIR:-$HOME/state}"
# compose creates a missing bind-source as root; make sure we own the mount root
# so this non-root user can populate it. Non-recursive to stay cheap.
sudo chown "$(id -u):$(id -g)" "$STATE_DIR" 2>/dev/null || true
mkdir -p "$STATE_DIR/projects" "$XDG_STATE_HOME" 2>/dev/null || true

# Avoid git "dubious ownership" errors on the bind-mounted projects when the
# container UID doesn't match the host owner.
git config --global --get-all safe.directory 2>/dev/null | grep -Fqx '*' || \
  git config --global --add safe.directory '*' 2>/dev/null || true

# No systemd-logind in the container to create XDG_RUNTIME_DIR (/run/user/<uid>),
# so tools that expect it (gpg, chezmoi, ...) fail with "permission denied" once
# the shell sets it. Create it ourselves with the right owner and mode.
RUNTIME_DIR="/run/user/$(id -u)"
sudo mkdir -p "$RUNTIME_DIR" 2>/dev/null \
  && sudo chown "$(id -u):$(id -g)" "$RUNTIME_DIR" 2>/dev/null \
  && chmod 700 "$RUNTIME_DIR" 2>/dev/null || true

# Seed a chezmoi-managed config dir into its ~/state location on first run only
# (mirrors how a named volume seeds from the image, but for an empty host bind
# mount). Auth/sessions then accumulate and persist there. Config refreshes only
# when the host dir is emptied, so dotfile updates can be picked up deliberately.
seed_state() {
  src="$1"; dest="$2"
  [ -d "$src" ] && [ -n "$dest" ] && [ "$src" != "$dest" ] || return 0
  mkdir -p "$dest"
  [ -z "$(ls -A "$dest" 2>/dev/null)" ] && cp -a "$src/." "$dest"/ 2>/dev/null || true
}
seed_state "$HOME/.claude" "$CLAUDE_CONFIG_DIR"
seed_state "$HOME/.codex" "$CODEX_HOME"

# Point each tool's state dir at ~/state via symlink. This is env-agnostic: the
# tool's configured path (often $XDG_DATA_HOME/<x> from fish) resolves through
# the link into ~/state, so we don't have to fight shell-set env vars.
link_state() {
  target="$1"; link="$2"
  mkdir -p "$target" "$(dirname "$link")"
  [ -L "$link" ] || rm -rf "$link"
  ln -sfn "$target" "$link"
}
link_state "$STATE_DIR/opencode"  "$HOME/.local/share/opencode"        # opencode auth/sessions
link_state "$STATE_DIR/gh"        "$HOME/.config/gh"                   # GitHub CLI token
link_state "$STATE_DIR/gnupg"     "$HOME/.local/share/gnupg"           # GPG keyring (GNUPGHOME)
link_state "$STATE_DIR/pass"      "$HOME/.local/share/pass"            # password-store
link_state "$STATE_DIR/bitwarden" "$HOME/.config/Bitwarden CLI"        # bw session
link_state "$STATE_DIR/zoxide"    "$HOME/.local/share/zoxide"          # zoxide jump db
link_state "$STATE_DIR/direnv"    "$HOME/.local/share/direnv"          # direnv allow-list
link_state "$STATE_DIR/docker"    "$HOME/.config/docker"               # docker registry auth (DOCKER_CONFIG)
link_state "$STATE_DIR/tmux-resurrect" "$HOME/.local/share/tmux/resurrect" # tmux-continuum saved sessions
chmod 700 "$STATE_DIR/gnupg" 2>/dev/null || true                      # gpg refuses loose perms

# npm writes auth tokens into its userconfig (the chezmoi-managed npmrc), so seed
# the managed config into ~/state once, then symlink it. The modify_npmrc template
# preserves existing keys, so a later apply won't drop persisted `npm login` tokens.
seed_state "$HOME/.config/npm" "$STATE_DIR/npm"
link_state "$STATE_DIR/npm"      "$HOME/.config/npm"

mkdir -p "$HOME/.local/share/fish"
[ -e "$HOME/.local/share/fish/fish_history" ] && [ ! -L "$HOME/.local/share/fish/fish_history" ] && rm -f "$HOME/.local/share/fish/fish_history"
ln -sfn "$STATE_DIR/fish_history" "$HOME/.local/share/fish/fish_history"  # shell history

# Reinstall mise toolchains into the persisted ~/state/mise on first run (they
# were dropped from the image to keep it small). No-op once present. node from
# here is needed by the chrome-devtools MCP below, so do it first.
if command -v mise >/dev/null 2>&1; then
  mise install -y >/dev/null 2>&1 || true
fi

# Docker-out-of-Docker: if the host Docker socket is mounted, make it usable by
# this (non-root) user so `docker ...` works inside the container.
if [ -S /var/run/docker.sock ]; then
  sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
fi

# Optional SSH/mosh access. Opt in with ENABLE_SSHD=1 and supply a public key
# via SSH_PUBKEY or a file mounted at /run/authorized_keys. Password login stays
# off (the user has no password), so it's key-only. authorized_keys lives in
# ~/state (not ~/.ssh, which may be a read-only host mount of your private keys).
if [ "${ENABLE_SSHD:-0}" = "1" ]; then
  AUTH_KEYS="$STATE_DIR/ssh/authorized_keys"
  mkdir -p "$STATE_DIR/ssh" && chmod 700 "$STATE_DIR/ssh"
  if [ -f /run/authorized_keys ]; then
    cp /run/authorized_keys "$AUTH_KEYS"
  elif [ -n "${SSH_PUBKEY:-}" ]; then
    printf '%s\n' "$SSH_PUBKEY" > "$AUTH_KEYS"
  fi
  chmod 600 "$AUTH_KEYS" 2>/dev/null || true
  sudo mkdir -p /run/sshd
  sudo ssh-keygen -A >/dev/null 2>&1 || true
  sudo /usr/sbin/sshd -o "AuthorizedKeysFile=$AUTH_KEYS" 2>/dev/null || true
fi

CHROME_BIN="${CHROME_BIN:-$(command -v google-chrome-stable || command -v google-chrome || command -v chromium || true)}"

# chrome-devtools-mcp's plugin form launches a headed, sandboxed Chrome that
# cannot start in a container. Register our own copy of the server pointed at the
# system Chromium with the flags a container needs. Idempotent across restarts.
if command -v claude >/dev/null 2>&1 && [ -n "$CHROME_BIN" ]; then
  if ! claude mcp list 2>/dev/null | grep -q 'chrome-devtools'; then
    claude mcp add --scope user chrome-devtools -- \
      npx -y chrome-devtools-mcp@latest \
        --headless --isolated \
        -e "$CHROME_BIN" \
        --chrome-arg=--no-sandbox \
        --chrome-arg=--disable-dev-shm-usage \
        --chrome-arg=--disable-gpu \
      >/dev/null 2>&1 || true
  fi
fi

exec "$@"
