## Fix failing checks

Unless the invocation is read-only, use this order for each pull request with
a failing check on the user's own non-fork branch:

1. Capture the head SHA, the failing check, and the run URL.
2. Reuse or create the head branch's worktree as [Rebase or update the branch](branch-repair.md) step 1 describes. In broader mode, rebase first when the branch is
   behind, so the fix runs on the current base. Default mode never rebases.
3. Read the relevant code and the full failing log. Make the smallest
   root-cause fix. Preserve input validation, error handling, security
   controls, accessibility behavior, and repository output-parity rules.
4. Run the repository's targeted checks, then any required formatting, lint,
   type, or test commands documented for the changed paths. Never skip or
   weaken a check.
5. Load the `commit` skill, commit only the intended files, and push with a
   normal push. Use the lease-protected force-push only when a rebase happened
   in this pass.
6. Refresh the inventory and record the new head SHA and the started checks.
   Keep the worktree while local work is needed; use the cleanup section on
   every completed or blocked outcome.

For an eligible infrastructure failure, capture the run URL and failure reason,
then run `gh run rerun RUN_ID --failed` at most once per run. Do not rerun a
code failure or repeatedly rerun a flaky check. After the retry, refresh the
inventory and classify the new result.

For a fork-owned or another author's branch with a code failure, report the
failure, the cause, and the fix the author needs.
