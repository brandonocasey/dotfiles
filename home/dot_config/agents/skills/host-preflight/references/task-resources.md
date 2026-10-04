# Task resources

Read before starting an application/preview server, creating temporary task
resources, or cleaning them up.

## Locations

For new disposable resources in a task worktree, use
`<worktree>/.agent/<task>/`, where `<worktree>` is the checkout root and `<task>`
is a unique task name. Keep logs, temporary helpers, generated preview assets,
and intermediate results there. For work without a task worktree, use
`$XDG_CACHE_HOME/agents/scratch/<task>/`, defaulting to
`~/.cache/agents/scratch/<task>/` when unset.

Before using `.agent/`, verify that the candidate path is ignored with
`git check-ignore -v <candidate-path>` and that no files under `.agent/` are
tracked. The managed global ignore file supplies `/.agent/`; repository rules
can override it. If it is not effective, use external cache scratch and report
why; do not change repository Git settings. Do not reuse or overwrite an
existing task directory or follow a symlink at `.agent/` or the task path.
Use external cache scratch when the root conflicts with existing project files.

Keep credentials, preview access tokens, and private gallery state outside the
repository in private external storage. Backups, cross-session recovery records,
copy files awaiting use, and requested deliverables keep their established
locations; never place them in disposable `.agent/` storage. A temporary preview
may use scratch assets while its URL is in use, but retain those assets for the
entire preview lifetime. Promote a file to the requested destination if the
user asks to keep it.

Do not migrate existing scratch directories or running previews. Apply this
layout to new resources only. Skills should use this location policy rather
than hardcode a scratch directory; tools with explicit output paths keep them.

## Servers and artifacts

Bind application and preview HTTP servers to `0.0.0.0`; tool-control endpoints
keep their required binding. Report `http://<lan-ip>:<port>`, never `localhost`.
Get the LAN IP with `ipconfig getifaddr en0` on macOS, `hostname -I` on Linux,
or `ipconfig` on Windows. Give each dev server and worktree its own random free
port; pass the same port to every start command for the task.

Use native attachments for screenshots, diagrams, and reports when available.
Otherwise serve them through HTTP. The global destination rule still applies:
a skill's default does not authorize a hosted write.

## Cleanup

Close task-owned MCP resources, stop servers and background processes, and free
their ports before deleting their resources. Remove only known task-owned
disposable scratch files, helpers, test data, debug output, and logs, even when
an open-PR worktree stays. Inspect contents first: `.agent/` or a Git ignore
match alone is not evidence that a file is disposable. Preserve unknown files
and other tasks' directories; do not recursively remove a shared `.agent/` root.
Delete with literal resolved task paths, never `rm -rf "$VAR"`.

When removing a worktree, its remaining disposable `.agent/` contents go with
it, but directory removal does not stop processes. Run the `worktree` skill's
preservation checks before removal, including its checks of ignored files.
Keep requested files and copy files awaiting use. If a helper could serve a
teammate or later task, propose a project path and let the user decide; never
leave it in the repository without consent.

Keep a server running when a requested deliverable depends on its URL. Report
its address and purpose; stop it after the user finishes using it or requests
shutdown. Follow `worktree` for branch/worktree retention and preservation checks;
open-PR worktrees remain available for follow-up work.
