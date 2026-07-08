# Dotfiles


## Install
### Linux/Mac
`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply brandonocasey; rm -rf ./bin/chezmoi && rmdir bin`

### Windows
`Set-ExecutionPolicy RemoteSigned -scope CurrentUser; (irm -useb https://get.chezmoi.io/ps1) | powershell -c -; bin/chezmoi init --apply brandonocasey; rm -r ./bin -fo`

## Docker

Build and run your dotfiles in a containerized environment.

### Build the Image

```bash
docker build --pull -t brandonocasey/dotfiles:latest .
```

Build with custom UID/GID to match your local user:

```bash
docker build --pull \
  --build-arg UNAME=$(whoami) \
  --build-arg UID=$(id -u) \
  --build-arg GID=$(id -g) \
  -t brandonocasey/dotfiles:latest .
```

### Run with docker run

Basic interactive shell:

```bash
docker run -it --rm brandonocasey/dotfiles:latest
```

With volume mounts for projects:

```bash
docker run -it --rm \
  -v ~/Projects:/home/$(whoami)/Projects \
  brandonocasey/dotfiles:latest
```

With UID/GID mapping and volumes:

```bash
docker run -it --rm \
  --user $(id -u):$(id -g) \
  -v ~/Projects:/home/$(whoami)/Projects \
  brandonocasey/dotfiles:latest
```

### Run with docker-compose (recommended)

`docker-compose.yml` is ready to work in: one host folder holds all state, the
Docker socket is mounted, and `/dev/shm` is sized so the browser MCP works.

```bash
cp .env.example .env
printf 'USER=%s\nUID=%s\nGID=%s\n' "$(whoami)" "$(id -u)" "$(id -g)" >> .env

docker compose up -d --build
docker compose exec dotfiles fish     # attach
docker compose down                   # stop (the state folder keeps your data)
```

### Persistence — one shared folder

Everything persistent lives under a single host folder (`STATE_DIR`, default
`./state`), bind-mounted to `~/state` in the container — back up or move just
that one directory. The entrypoint lays out and seeds its subdirs:

| Under `~/state` | What | How |
| --- | --- | --- |
| `projects/` | your work (the working dir) | bind mount |
| `claude/` | Claude auth, sessions, MCP | `CLAUDE_CONFIG_DIR`, seeded |
| `codex/` | Codex auth, config, sessions | `CODEX_HOME`, seeded |
| `opencode/` | opencode auth, sessions | symlinked |
| `gh/` | GitHub CLI token | symlinked from `~/.config/gh` |
| `gnupg/` | GPG keyring (signing) | symlinked from `$GNUPGHOME` |
| `pass/` | password-store | symlinked from `$PASSWORD_STORE_DIR` |
| `bitwarden/` | `bw` session | symlinked from `~/.config/Bitwarden CLI` |
| `zoxide/`, `direnv/` | jump db, allow-list | symlinked |
| `mise/` | language toolchains (node, go, …) | `MISE_DATA_DIR`; reinstalled on first run |
| `xdg-state/` | nvim shada/undo + other `XDG_STATE_HOME` state | `XDG_STATE_HOME` |
| `fish_history` | shell history | symlinked |

mise toolchains are kept out of the image to shrink it; the entrypoint runs
`mise install` on first container start to populate `~/state/mise`, so the
**first start downloads node/go/etc.** (a one-time cost per state folder).

Your **SSH keys** are bind-mounted read-only from the host `~/.ssh` (set
`SSH_DIR` to override) so git/remotes work — they're not copied into `~/state`.
GPG keys aren't shipped in the image; import them once and they persist in
`~/state/gnupg`.

Seeded config dirs copy from the image's chezmoi config **only when empty**, so
auth survives rebuilds. To pull in dotfile changes after a rebuild, empty that
subdir so it reseeds. nvim **config and plugins/LSPs** are *not* persisted —
they stay baked in the image (`~/.config/nvim`, `~/.local/share/nvim`) and
refresh on each rebuild; only your editing state (undo, marks, command history)
persists.

### UID/GID and bind-mount ownership

Files written into `~/state` are owned by the container user. Keep that matched
to your host user so you can edit them back on the host:

- **Set `USER`/`UID`/`GID` in `.env`** (above). fish doesn't export `$UID`/`$GID`,
  so without `.env`, compose silently builds as UID 1000 and ownership mismatches
  on Linux.
- **macOS**: Docker Desktop maps ownership automatically — mismatches are masked.
- **Linux server**: ownership is literal. Build the image there (or with
  `--build-arg UID/GID`) so the baked user matches; the prebuilt GHCR image is
  UID 1000 and only lines up cleanly if your server user is 1000.
- The entrypoint `chown`s the mount root to the runtime user, so a root-created
  bind dir is still writable.

### Docker-out-of-Docker

The image ships the Docker CLI (+ compose/buildx plugins) and the compose file
mounts `/var/run/docker.sock`, so `docker` / `docker compose` inside the
container drive the **host** daemon (sibling containers, no nested daemon). The
entrypoint relaxes the socket permissions so the non-root user can use it.
Security note: socket access is root-equivalent on the host — comment out the
`docker.sock` mount if you don't want that.

### Shell / SSH access

Simplest is no SSH at all — attach with `docker compose exec dotfiles fish`
(works locally and on a remote host that has Docker).

For real `ssh`/`mosh` into the container (VS Code Remote-SSH, connecting without
the Docker CLI), opt in: uncomment the `ports` block in `docker-compose.yml`,
then run with key-only auth (no passwords):

```bash
export ENABLE_SSHD=1 SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)"
docker compose up -d --build
ssh -p 2222 $(whoami)@<host>
```

`mosh` is installed; it also needs its UDP ports published (add e.g.
`- "60000-60010:60000-60010/udp"` to `ports`).

### Chrome / chrome-devtools MCP

The image installs `chromium` plus its libraries. On macOS the
`chrome-devtools-mcp` plugin runs as usual; in the container the plugin is
disabled and the entrypoint registers an
equivalent `chrome-devtools` server tuned for headless containers
(`--headless --isolated -e /usr/bin/chromium --chrome-arg=--no-sandbox`).
Verify inside the container with `claude mcp list`.

### Architecture

The image is **amd64-only**: the toolchain is Homebrew-based and Homebrew is
unsupported on ARM64 Linux (no bottles), so an arm64 build ships empty. On Apple
Silicon it runs under Docker Desktop's emulation — slower, but everything works.

### Customization

Edit `docker-compose.yml` to change the host folders, add more bind mounts, or
remove the Docker socket. Claude Code is installed via the macOS cask locally and
via the native installer (`claude.ai/install.sh`) inside the Linux image; Codex
and opencode come from the shared Homebrew bundle.

## Backup
Run `bash ./backup-settings.sh`
