# Temporary target worktree

Read when `TARGET` is not checked out anywhere (`MAIN_WT` unset) at `SKILL.md`
step 4, and again at step 5 cleanup.

Create a temporary worktree for the existing target under the primary checkout,
never nested in another worktree, and set `MAIN_WT` to its absolute path. Do not
switch the main checkout:

```sh
git -C <primary-checkout> worktree add .worktrees/<unused-name> <TARGET>
git -C <MAIN_WT> merge --ff-only <BRANCH>
```

Record that this run created it. On failure, keep it if needed for recovery and
report its path.

## Removal (step 5)

After the merge and source cleanup, move to the primary checkout and remove the
temporary worktree from a surviving checkout outside that directory (the
`worktree` skill's **Blocked removal** applies if it refuses). Do this even when
the source branch must stay checked out in the primary checkout. If the
temporary tree has become dirty or active, retain it and report its path. Never
remove a target worktree that existed before this run.
