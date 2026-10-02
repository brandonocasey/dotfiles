# Koof server work

The Compose repository is `/boot/config/plugins/compose.manager/projects`.
Its main checkout serves live workloads. Read its `AGENTS.md` and the affected
stack instructions before changing server files.

Implement and test in an isolated worktree. Changes to bind-mounted files in
the live checkout can affect running services without a restart.

A request to investigate, implement, commit, or push does not authorize deployment.
Keep live services, volumes, secrets, and databases unchanged unless the user
has authorized the exact production action and scope.

For landing, pushing, or deploying, follow the repository's
`skills/land-push-deploy/SKILL.md`. Before production writes, show its read-only
preview, rollback limits, and backup requirements. Ask only for missing approval.
Existing scoped approval persists; a saved task record does not expand it.

Use `agent-preflight --remote root@koof.win` before depending on remote tools.
SSH commands use `-T -o RemoteCommand=none`. Do not assume an interactive PATH
or that Python, ripgrep, or chezmoi is available in noninteractive shells.
The agent CLIs are in `/root/.local/bin`; use their absolute paths when needed.
Run GitHub watchers from a host where `gh` and its authentication are available.
