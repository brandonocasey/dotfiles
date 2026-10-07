## Merge and report

Let an enabled auto-merge complete. Merge manually only when the pull request
has auto-merge enabled but auto-merge cannot complete, or when the invocation
includes `merge`. Before a manual merge, run a final read-only preflight: open,
not a draft, mergeable, approved, and passing every required check. Then use
the configured merge method or the repository default, passed as its flag:
`gh pr merge N --<METHOD> --match-head-commit HEAD_SHA`, where `METHOD` is
`merge`, `squash`, or `rebase`. Outside a merge queue, `gh` refuses a
non-interactive merge without a method flag. Never use `--admin` or
`--delete-branch`. Do not merge a pull request that still has a review,
required check, conflict, queue, policy, or permission blocker.

On GitLab, merge with the GitLab command in ship's
[merge reference](../../ship/references/merge.md#enable-auto-merge) and
`--sha HEAD_SHA`. Never pass `--auto-merge=false`.

With `approve`, approve a pull request only when approval is its last blocker.
Use the commands and limits in the merge reference's
[Approve](../../ship/references/merge.md#approve) section. Then refresh it and
run the preflight. Without `merge` or auto-merge, a passing pull request is
complete; report it as ready.
