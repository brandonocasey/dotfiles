# Task resources

Read before starting an application/preview server, creating temporary task
resources, or cleaning them up.

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
their ports. Remove disposable scratch files, helpers, test data, debug output,
and logs. Delete with literal paths, such as
`rm -rf ~/.cache/agents/scratch/<task>`; never `rm -rf "$VAR"`.
Keep requested files and copy files awaiting use. If a helper could serve a
teammate or later task, propose a project path and let the user decide; never
leave it in the repository without consent.

Keep a server running when a requested deliverable depends on its URL. Report
its address and purpose; stop it after the user finishes using it or requests
shutdown. Follow `worktree` for branch/worktree retention and preservation checks;
open-PR worktrees remain available for follow-up work.
