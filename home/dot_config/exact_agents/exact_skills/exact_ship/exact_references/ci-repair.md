# Watch and repair CI after shipping

## Watch CI after shipping

After each `ship` push, without waiting for its review, start one `agent-watch` with a `--target` for each MR/PR this run shipped, at its last recorded `HEAD_SHA`, and `--deadline-seconds 3300`.
Before starting it, stop any earlier CI watch this session started for the same MR/PR. A later push in the same task starts a new watch at the new head.
Skip it, and give the reason in the report, for `ship --merge` (`merge.md` owns the watch), an explicit monitoring request, a user request not to watch, or a platform other than GitHub or GitLab.
In Claude Code, run it as a background command in the main session; its exit is the only wake.
Add no periodic wakes, monitor timeouts, or status checks, and never poll the same targets.
On another harness, or when the harness cannot notify on exit, run it through one `cheap` agent under the wake rule in [monitoring.md](../../sub-agents/references/monitoring.md).
Do not wait for it before the ship report; give `Waiting on: CI watch, ends by <time>`.

On exit, read the final event's top-level `reason`, then each target's `results[].reason`, and report once per watch exit:

- `checks_complete`: one line per MR/PR with its target reason, such as `required_checks_passed` or `merged`.
- `action_required`: for a target with `check_failed` or `check_cancelled`, list each failed or cancelled check with its job URL. For any other blocked target reason, give the reason and detail. Name any target that was still pending; it is no longer watched. Repair as below.
- `deadline_exceeded`: CI is still running; give each pipeline URL.
- `cancelled`: say the watch was stopped.

Do not restart the watch unless the user asks, except after a repair or retry.

## Repair

Before repairing a target, check that its checkout is on the shipped branch, `HEAD` equals the watched head, and the tree is clean. Otherwise, report without repairing.

1. Pull the failing job's log (`glab ci trace <job>` / `gh run view <run-id> --log-failed`).
   Find the real error under the boilerplate.
2. If an earlier run removed the worktree, recreate it with the commands in
   `worktree`'s **Restore a removed worktree**.
3. Fix the error. Commit through the `commit` skill. Run the **Manual check** of
   `shared/git-flow.md` for the fix. Push per `ship` step 2, then restore any
   paused auto-merge per [auto-merge-pause.md](../../shared/auto-merge-pause.md).
4. Run `ship` step 5 after the requested work ends.

Retries follow [ci-and-conflicts.md](../../review/references/ci-and-conflicts.md): a proven runner or service failure permits one retry of the failed jobs per run (`glab ci retry <job>` / `gh run rerun <run-id> --failed`). A second failure is real.

From a watch failure, delegate the diagnosis:

- For each failed target, give one `worker` agent, on its role pin, the failed job URLs, that target's checkout path and branch, and these limits: commit, never push, and change only files the failing jobs need.
- It returns each job's first error, up to 20 log lines, and its cause: runner or service failure, this ship's change, or other. A cancelled job without an error is other.
- For this ship's change, it runs step 1, fixes the error, makes one commit through the `commit` skill, and stops.
- The main session checks that `<watched head>..HEAD` holds only that commit, runs step 3's Manual check, and pushes. If either check fails, do not push; report it and leave the commit for the user.
- For a runner or service failure, the main session retries the job.
- Per MR/PR per ship, allow at most 1 retry and 2 fix pushes.
- Report without repairing when the cause is other, when the fix would weaken, skip, or remove a test or add a suppression, or when a cap is reached.
- After each fix push or retry, start a new watch with that target at its new head and every target still pending. List each fix commit in the report.
