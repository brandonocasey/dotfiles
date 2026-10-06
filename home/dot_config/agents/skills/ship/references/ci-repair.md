# Repair failed CI

Then: pull the failing job's log (`glab ci trace <job>` / `gh run view <run-id> --log-failed`), find
  the real error under the boilerplate, fix it, commit via the `commit` skill, run the
  **Manual check** of `shared/git-flow.md` for the fix, push, and run
  step 5 after the requested work ends. If an earlier run removed the worktree,
  recreate it with the commands in `worktree`'s **Restore a removed worktree**. Retry a job once
  (`glab ci retry <job>` / `gh run rerun <run-id> --failed`) when the project's docs name that suite
  as flaky or the log shows an infrastructure failure; a second failure is real.
