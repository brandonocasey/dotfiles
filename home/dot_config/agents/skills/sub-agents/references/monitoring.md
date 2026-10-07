## Monitoring

For a command this session started, use the harness's completion notice or monitor tool when available.
For external targets, prefer a deterministic watcher such as `agent-watch`.
Start it once and use the harness's completion notice or monitor tool.
Use a `cheap` agent when the harness cannot monitor the process or interpretation is needed.
It runs the watcher once and reports the outcome and relevant details.
While the watcher runs, the main session never polls the same target.

For a long run (workflow, build, or watcher), state an ETA in minutes at the start.
Report each phase change without a prompt.
Answer "status?" from the run's own log or journal, in three lines or fewer, state first.
While a background job you own is pending, put `Waiting on: <thing>, checked <time>, next check <time>` just before the final `Next:` line.

A sub-agent's prompt cache expires after an idle period set by its harness and model; its next request rewrites its whole context.
A waiting sub-agent wakes before that expiry: every 4 minutes in Claude Code (5-minute cache), every 25 minutes only on a verified API-billed OpenAI GPT-5.6 or later cache (30-minute minimum), and every 4 minutes on any other harness or model, or when unsure.
Run the wait in the background and give each monitor or wait call a timeout no longer than that wake interval.
On each wake, read the existing watcher's or process's output or status once; if it has not finished, wait again.
Never start a second watcher or query the watched target directly.
A wake costs a cache read at 0.025–0.1× the base input price, by model; an expiry rewrites the context at up to 1.25×.
This applies only to waits; never add calls during active work to keep the cache warm.

Never watch an MR/PR or pipeline for success unless the user asks; `auto-merge-watch` counts as that request.
"When it merges, do X" also counts. Start one watcher with a long `--deadline-seconds`.
Run the queued action only when the watcher reports reason `merged`.
On any other result, such as `required_checks_passed`, a deadline, or a new head SHA, report it to the user.
`agent-watch` takes GitHub `OWNER/REPO#PR@SHA` and GitLab `GROUP[/SUBGROUP...]/PROJECT!IID@SHA` targets. For other platforms, say the watch is unsupported.
The queued action keeps its consent rules.
Otherwise, report the pipeline URL and stop: no watcher or polling.
