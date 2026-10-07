# Shipping from a target/default branch

**If `BRANCH` equals `REMOTE_DEFAULT` or `TARGET`**:

- Fetch `refs/heads/<BRANCH>` from `origin` and record its commit ID before
  comparing it with local `HEAD`. If local commits are ahead or histories
  diverge, ask which commits should ship on a new branch. Never guess, reset,
  or force the checked-out branch. Stop on a missing remote branch or failed fetch.
- With a dirty tree and no local-only commits, move the work onto a branch named by the repo
  convention, using the `worktree` skill's **Recover changes made in the main checkout**
  steps. Continue from inside the new worktree and refresh `BRANCH`.
- With a clean tree and no local-only commits, report that there is nothing to ship and stop.
