## Fix failing checks

Unless the invocation is read-only, use this order for each pull request with
a failing check on the user's own non-fork branch:

1. Capture the head SHA, the failing check, and the run URL.
2. Reuse or create the head branch's worktree as [Rebase or update the branch](branch-repair.md) step 1 describes. Rebase first when the branch is
   behind, so the fix runs on the current base, unless SKILL.md **Authorization** rules out a rebase.
3. Read the relevant code and the full failing log. Make the smallest
   root-cause fix. Preserve input validation, error handling, security
   controls, accessibility behavior, and repository output-parity rules.
4. Run the repository's targeted checks, then any required formatting, lint,
   type, or test commands documented for the changed paths.
5. Load the `commit` skill, commit only the intended files, and push with
   `git push origin HEAD:<head-branch>`. Use the lease-protected force-push from
   [branch-repair.md](branch-repair.md) step 5 only when a rebase happened in this pass.
6. Refresh the inventory and record the new head SHA and the started checks.
   Keep the worktree while local work is needed; use the cleanup section on
   every completed or blocked outcome.

A proven service or runner failure permits one retry per run: capture the run
URL and failure reason, then `gh run rerun RUN_ID --failed`. Never rerun a code
failure or an unproven flaky test. After the retry, refresh the inventory and
classify the new result.

For a fork-owned or another author's branch with a code failure, report the
failure, the cause, and the fix the author needs.
