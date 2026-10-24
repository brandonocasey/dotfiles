# Fast-forward the local target to its upstream

Run this after [default-branch.md](default-branch.md) **Newest default base**
selects a base for a new branch, and after a merge into the target. Never run
it for a review comparison. When no fetched commit is
recorded, fetch the upstream per **Fetch and pin** first. For a base that
`agt worktree create` selected and reported with `local_default`, agt already
did this: report it per the `worktree` skill's create.md and do not repeat it.

Use the commit fetched from the target's upstream: `branch.<target>.remote` and
`branch.<target>.merge`, else `origin`'s branch of the same name. A commit from
another remote, such as `upstream` in a fork, would make the target look ahead
of its upstream. Skip when that upstream branch is not the one fetched.

Never create a merge commit, rebase, stash, or reset:

- Target equals the commit or contains it: nothing to do.
- Neither contains the other: skip, because they diverged.
- Target checked out in a worktree (see `git worktree list --porcelain`): skip
  when `git diff --raw --ignore-submodules=none <target> <commit>` shows a
  `160000` mode, because a merge leaves a moved submodule at its old commit.
  Otherwise run
  `git -C <that-worktree> merge --ff-only --no-overwrite-ignore --no-autostash <commit>`,
  even with local changes. Git keeps changes the merge does not touch. With
  these flags it refuses, changing nothing, when the merge would overwrite a
  local change or an ignored file; without them it replaces ignored files and
  may stash.
- Target checked out nowhere: run
  `git fetch . <commit>:refs/heads/<target>` from any checkout. Without `+`, Git
  refuses a non-fast-forward, and it refuses a branch being rebased.

A skip or refusal never changes the base choice or blocks the task. Put it in
the final report as `⚠ local <target> not updated: <reason>`. Add how many
commits it is behind, and the command that updates it once the cause is fixed.
