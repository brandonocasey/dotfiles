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

After `ship`, follow **Watch CI after shipping** below.
Otherwise, never watch an MR/PR or pipeline for success unless the user asks; `pr-fix` counts as that request.
"When it merges, do X" also counts. Start one watcher with a long `--deadline-seconds`.
Run the queued action only when the watcher reports reason `merged`.
On any other result, such as `required_checks_passed`, a deadline, or a new head SHA, report it to the user.
`agent-watch` takes GitHub `OWNER/REPO#PR@SHA` and GitLab `GROUP[/SUBGROUP...]/PROJECT!IID@SHA` targets. For other platforms, say the watch is unsupported.
The queued action keeps its consent rules.
Otherwise, report the pipeline URL and stop: no watcher or polling.

## Watch CI after shipping

After `ship` finishes its pushes, start one `agent-watch` with a `--target` for each MR/PR this run shipped, at its last recorded `HEAD_SHA`, and `--deadline-seconds 3300`.
Before starting it, stop any earlier CI watch this session started for the same MR/PR. A later push in the same task starts a new watch at the new head.
Skip it, and give the reason in the report, for `ship --merge` (`merge.md` owns the watch), an explicit monitoring request, a user request not to watch, or a platform other than GitHub or GitLab.
In Claude Code, run it as a background command in the main session; its exit is the only wake.
Add no periodic wakes, monitor timeouts, or status checks, and never poll the same targets.
The main session's 1-hour prompt cache keeps that single wake cached within the 55-minute deadline.
On another harness, or when the harness cannot notify on exit, run it through one `cheap` agent under the sub-agent wake rule above.
Do not wait for it before the ship report; give `Waiting on: CI watch, ends by <time>`.

On exit, read the final event's top-level `reason`, then each target's `results[].reason`, and report once per watch exit:
- `checks_complete`: one line per MR/PR with its target reason, such as `required_checks_passed` or `merged`.
- `action_required`: for a target with `check_failed` or `check_cancelled`, list each failed or cancelled check with its job URL. For any other blocked target reason, give the reason and detail. Name any target that was still pending; it is no longer watched.
  Before repairing a target, check that its checkout is on the shipped branch, `HEAD` equals the watched head, and the tree is clean. Otherwise, report without repairing.
  For each failed target, give one `worker` agent, on its role pin, the failed job URLs, that target's checkout path and branch, and these limits. Assign it to commit, never push, and to change only files the failing jobs need.
  It returns each job's first error, up to 20 log lines, and its cause: flaky or infrastructure, this ship's change, or other. A cancelled job without an error is other.
  For this ship's change, it runs `ship`'s [ci-repair.md](../../ship/references/ci-repair.md) step 1, fixes the error, makes one commit through the `commit` skill, and stops.
  The main session then checks that `<watched head>..HEAD` holds only the worker's one commit, runs the **Manual check** of `shared/git-flow.md`, and pushes per `ship` step 2.
  If either check fails, do not push; report it and leave the commit for the user.
  For flaky or infrastructure, the main session retries the job per ci-repair.md.
  Per MR/PR per ship, allow at most 1 retry and 2 fix pushes. A job that fails again after its retry is not flaky.
  Report without repairing when the cause is other, when the fix would weaken, skip, or remove a test or add a suppression, or when a cap is reached.
  After each fix push or retry, start a new watch with that target at its new head and every target still pending. List each fix commit in the report.
- `deadline_exceeded`: CI is still running; give each pipeline URL.
- `cancelled`: say the watch was stopped.
Do not restart the watch unless the user asks, except after a repair or retry above.
