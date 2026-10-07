## Rebase or update the branch

Broader mode only. Default mode uses the merge update in SKILL.md and never
rebases or force-pushes.

For a stacked pull request whose base is another open pull request's branch,
rebase onto that branch, not the default branch, and finish the base pull
request first.

For the user's own branch:

1. Load the `worktree` skill and reuse or create the head branch's worktree.
   Without a local branch, use the two commands at the end of its **Restore a removed worktree**; they fetch the branch first.
2. Fetch the head branch and verify that its fetched SHA and the worktree
   HEAD equal the observed SHA. If either differs, preserve local work,
   refresh the inventory, and reconcile it before proceeding. Fetch the base
   explicitly with `git fetch origin refs/heads/BASE`, then immediately record
   `git rev-parse FETCH_HEAD` as `BASE_SHA`; a restricted fetch refspec may
   leave `origin/BASE` absent or stale.
3. Run `git rebase BASE_SHA`. Resolve conflicts when the combined result is
   clear; keep both sides' intent. Stop and report the conflicting files when
   the intended result is ambiguous.
4. Run the repository's targeted checks for the touched paths.
5. Push with `git push --force-with-lease=BRANCH:OBSERVED_SHA origin HEAD:BRANCH`.
   A rejected lease means someone else pushed; refresh and start over.
6. Refresh the inventory and record the new head SHA.

For another author's branch, use `gh pr update-branch N` only when the
repository permits a merge update. If linear history requires rebasing,
report that the author must rebase; do not rewrite another author's branch
through `--rebase`. If the update reports conflicts, report them to the author.
