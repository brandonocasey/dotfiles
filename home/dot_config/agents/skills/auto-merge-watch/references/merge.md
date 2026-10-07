## Merge and approve

Let an enabled auto-merge complete. Before any manual merge, run a final
read-only preflight: open, not a draft, mergeable, approved, and passing every
required check at the recorded head SHA. Then use the configured merge method
or the repository default, passed as its flag:
`gh pr merge N --<METHOD> --match-head-commit HEAD_SHA`, where `METHOD` is
`merge`, `squash`, or `rebase` (a repository merge method, not a local rebase). Outside a merge queue, `gh` refuses a
non-interactive merge without a method flag. Never use `--admin` or
`--delete-branch`. Do not merge a pull request that still has a review,
required check, conflict, queue, policy, or permission blocker.

On GitLab, merge with the GitLab command in ship's
[merge reference](../../ship/references/merge.md#enable-auto-merge) and
`--sha HEAD_SHA`. Never pass `--auto-merge=false`.

Either mode may merge manually when auto-merge is enabled but cannot complete,
after the preflight. Only broader mode merges a pull request without
auto-merge, and only when the user's own text contains `merge`. Otherwise a
passing pull request is complete; report it as ready.

With `approve` (broader mode only), approve a pull request only when approval
is its last blocker. Use the commands and limits in the merge reference's
[Approve](../../ship/references/merge.md#approve) section. Then refresh it and
run the preflight. Report a policy error from the approve call as-is; do not
retry or bypass it.
