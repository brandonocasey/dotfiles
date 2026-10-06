## Monitoring

For a command this session started, use the harness's completion notice or monitor tool when available.
For external targets, prefer a deterministic watcher such as `agent-watch`.
Start it once and use the harness's completion notice or monitor tool.
Use a `cheap` agent when the harness cannot monitor the process or interpretation is needed.
It runs the watcher once and reports the outcome and relevant details.
The main session never polls the same target while the watcher runs.

For a long run (workflow, build, or watcher), state an ETA in minutes at the start.
Report each phase change without a prompt.
Answer "status?" from the run's own log or journal.

Never watch an MR/PR or pipeline for success unless the user asks; `pr-unblock` counts as that request.
"When it merges, do X" also counts. Start one watcher with a long `--deadline-seconds`.
Run the queued action only when the watcher reports reason `merged`.
On any other result, such as `required_checks_passed`, a deadline, or a new head SHA, report it to the user.
`agent-watch` takes GitHub `OWNER/REPO#PR@SHA` and GitLab `GROUP[/SUBGROUP...]/PROJECT!IID@SHA` targets. For other platforms, say the watch is unsupported.
The queued action keeps its consent rules.
Otherwise, report the pipeline URL and stop: no watcher or polling.
