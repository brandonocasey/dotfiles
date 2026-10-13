# Fast-forward the local target to the selected base

Read from [default-branch.md](default-branch.md) **Newest default base** after step 3 or 4
selects a base. All of these conditions must be true, or skip
the fast-forward:

- The base is the commit fetched from the target's upstream remote
  (`git config branch.<target>.remote`). A commit from another remote, such as
  `upstream` in a fork, would make the target look ahead of its upstream.
- The local target is a strict ancestor of the base.
- `git diff --raw <target> <base-commit>` shows no `160000` mode. A merge does
  not update submodule checkouts, so a changed gitlink leaves the checkout
  dirty.

Never create a merge commit, rebase, or reset:

- Target checked out in a worktree (see `git worktree list --porcelain`) with an
  empty `git -C <that-worktree> status --porcelain --ignore-submodules=none`:
  run `git -C <that-worktree> merge --ff-only <base-commit>`.
- Target checked out nowhere: run
  `git fetch . <base-commit>:refs/heads/<target>` from any checkout of the
  repository. Without `+`, Git refuses a non-fast-forward update.
- Target checked out in a dirty worktree, or the command fails: skip the
  fast-forward and report why. The base choice does not change.
