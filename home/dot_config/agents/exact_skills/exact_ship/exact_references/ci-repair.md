# Repair failed CI

1. Pull the failing job's log (`glab ci trace <job>` / `gh run view <run-id> --log-failed`).
   Find the real error under the boilerplate.
2. If an earlier run removed the worktree, recreate it with the commands in
   `worktree`'s **Restore a removed worktree**.
3. Fix the error. Commit through the `commit` skill. Run the **Manual check** of
   `shared/git-flow.md` for the fix. Push per `ship` step 2.
4. Run `ship` step 5 after the requested work ends.

Retry a job once (`glab ci retry <job>` / `gh run rerun <run-id> --failed`) when the project's
docs name that suite as flaky or the log shows an infrastructure failure. A second failure is real.
