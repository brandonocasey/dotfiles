## Rebase or update the branch

When SKILL.md **Authorization** rules out a rebase, use the update or report
path for another author's branch below.

For a stacked pull request whose base is another open pull request's branch,
rebase onto that branch, not the default branch, and finish the base pull
request first.

For the user's own branch:

1. Load the `worktree` skill and reuse or create the head branch's worktree.
   Without a local branch, use the two `git` commands in [restore.md](../../worktree/references/restore.md); they fetch the branch first.
2. Fetch the head branch and verify that its fetched SHA and the worktree
   HEAD equal the observed SHA. If either differs, preserve local work,
   refresh the inventory, and reconcile it before proceeding. Fetch and pin
   `BASE` per [default-branch.md](../../shared/default-branch.md) **Fetch and
   pin**, and record the pinned commit as `BASE_SHA`.
3. Run `git rebase BASE_SHA`. Resolve conflicts per
   [git-policy.md](../../shared/git-policy.md); report the conflicting files
   when the intended result is ambiguous.
4. Run the repository's targeted checks for the touched paths.
5. Push with `git push --force-with-lease=BRANCH:OBSERVED_SHA origin HEAD:BRANCH`.
   A rejected lease means someone else pushed; refresh and start over.
6. Refresh the inventory and record the new head SHA.

For another author's branch, use `gh pr update-branch N` only when the
repository permits a merge update. If linear history requires rebasing,
report that the author must rebase; do not rewrite another author's branch
through `--rebase`. If the update reports conflicts, report them to the author.
