# Dotfiles


## Install
### Linux/Mac
`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply brandonocasey; rm -rf ./bin/chezmoi && rmdir bin`

On Linux, the bootstrap script installs Homebrew's prerequisites with `apt-get`,
`dnf`, `yum`, or `pacman`. With another package manager, install a compiler,
`curl`, `file`, `git`, `xsel`, and `unzip` first. If an agent installer fails,
`chezmoi apply` reports the error and retries it on the next apply.

### Windows
`Set-ExecutionPolicy RemoteSigned -scope CurrentUser; (irm -useb https://get.chezmoi.io/ps1) | powershell -c -; bin/chezmoi init --apply brandonocasey; rm -r ./bin -fo`

## Tmux

On Linux and macOS, `chezmoi apply` reloads the running tmux server when its
managed configuration changes. Reloading reapplies bindings, plugins, and agent
session naming hooks. If no server is running, the script exits without starting
one. An unchanged configuration does not trigger another reload.

Before that reload, the same configuration change runs tpm to install missing
plugins and update all plugins.

## Agent skills

Chezmoi manages `~/.config/agents/` and every owned folder under it as
[exact directories](https://www.chezmoi.io/reference/source-state-attributes/).
Applying removes files and folders absent from the source, including nested references.
Claude's ignored `synced/` tree retains its existing ownership.

Delete owned skills or files from `home/dot_config/exact_agents/exact_skills/` in this repository.
Commit and sync those source deletions, then apply on each machine.
Deleting only an installed file causes chezmoi to restore it.
New owned source directories need the `exact_` prefix at every depth.
Preview with `chezmoi diff ~/.config/agents/skills`, then apply only the skills:

```sh
chezmoi apply --exclude=scripts ~/.config/agents/skills
```

Chezmoi manages `frontend-design`, copied from
[anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design)
with local changes: a shorter description, a `Scope:` line, and an explicit-only
rule that hands verification to `ux-verify`. Its `agents/openai.yaml` makes Codex require an
explicit invocation. The managed Claude settings apply the same restriction to
the skill and to its plugin.

Chezmoi also manages `ux-verify` in the shared skills directory. Codex and
Claude can select it automatically.

Codex keeps the synced `docs` and `google-workspace` bodies disabled and exposes
explicit-only wrappers with those names. The wrappers read the installed synced
skill only for an explicitly requested hosted destination. Codex uses its native
`skill-creator`; Claude keeps its synced version.

Codex discovers `docx`, `xlsx`, `pptx`, and `pdf` through compact wrappers that
load the installed synced skill on demand, including its examples, scripts,
and assets. These four wrappers remain automatically selectable. Claude keeps
its existing compact listings. Neither harness changes the app-owned bodies.
The Codex config modifier discovers synced paths on each host. Apply the
wrappers before the config on an existing installation:

```sh
chezmoi apply ~/.codex/skills/docx ~/.codex/skills/xlsx ~/.codex/skills/pptx ~/.codex/skills/pdf
chezmoi apply ~/.codex/config.toml
```

Rerun the config apply after a synced account path changes, then restart Codex
to refresh skill discovery.

Codex limits the skill catalog to 1,000 tokens and retained tool outputs to
4,000 tokens each. Automatic compaction uses the model's default threshold.
Output limits can truncate evidence.

Codex disables shared-server auto-start with `features.daemon_auto_start = false`.
Fish and Bash launches also add `--no-daemon`, bypassing existing servers.
These sessions cannot use shared-server features such as `codex agents`.
Use `command codex` for an explicit unwrapped invocation.

All seven Codex roles omit automatic skill guidance and bundled skills.
Delegating sessions must pass required skill paths and task constraints.
The explorer, tester, reviewer, and consult roles disable apps and plugins.
Other roles retain them; standalone MCP servers remain available.
The documentation MCP exposes search, page retrieval, and OpenAPI retrieval.
Linux disables the bundled browser and Chrome plugins, whose configured
backends require macOS. The standalone browser MCP configuration stays available.
These settings follow the [Codex configuration reference](https://developers.openai.com/codex/config-reference)
and [custom-agent controls](https://developers.openai.com/codex/subagents#custom-agents).
Restart Codex after applying them to refresh configuration and agent discovery.

Shared writing rules live in `~/.config/agents/AGENTS.md`. Multi-step work and
change recaps additionally load `skills/shared/work-output.md`. The delegation
skill loads monitoring and escalation procedures only when those operations
apply; its role pins, handoff rules, and verification requirements remain in
the main skill.

Claude's cleanup notice and output-expiry hooks run on startup, resume, fork,
and clear. They skip compaction. Output cleanup removes disposable report copies
untouched for seven days.

To update `frontend-design`, copy the upstream files into
`home/dot_config/exact_agents/exact_skills/exact_frontend-design/`. Keep the
local `description` and `disable-model-invocation` frontmatter, the `Scope:`
line, and the explicit-only paragraph under the title.

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
| `pi/`, `gemini/` | Pi and Gemini auth, sessions, config | symlinked from `~/.pi`, `~/.gemini`, seeded |
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
entrypoint grants the container user's UID access through an ACL (`setfacl`),
leaving the socket's mode alone. If ACLs are unsupported it prints a warning;
add the socket's group ID under `group_add` in `docker-compose.yml` instead.
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
unsupported on ARM64 Linux (no bottles), so an arm64 build ships empty, and Google
Chrome is amd64-only. `docker-compose.yml` sets `platform: linux/amd64`, so local
builds match CI. On Apple Silicon it runs under Docker Desktop's emulation.

### Customization

Edit `docker-compose.yml` to change the host folders, add more bind mounts, or
remove the Docker socket. Claude Code is installed via the macOS cask locally and
via the native installer (`claude.ai/install.sh`) inside the Linux image; Codex
and opencode come from the shared Homebrew bundle.

## Backup
Run `bash ./backup-settings.sh`. It zips shell history, zoxide data, `~/.ssh`,
local Git config, and `~/Projects` (without `node_modules`) into `~/Downloads`.
Projects are not modified. If a step fails, it exits non-zero and keeps the
staged copy, printing its path.
