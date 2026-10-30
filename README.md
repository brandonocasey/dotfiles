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

## Backup
Run `bash ./backup-settings.sh`. It zips shell history, zoxide data, `~/.ssh`,
local Git config, and `~/Projects` (without `node_modules`) into `~/Downloads`.
Projects are not modified. If a step fails, it exits non-zero and keeps the
staged copy, printing its path.
