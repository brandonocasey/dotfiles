# Recover changes made in the main checkout

If you already changed files in the main checkout, move them into the worktree
so the main checkout stays clean:

1. Select the base per the `worktree` skill's **Create** section.
   Stash only this task's paths, new files included, under a unique label,
   and leave unrelated user work in place:
   `git -C <main-checkout> stash push --include-untracked -m <label> -- <paths>`.
   If ownership overlaps within a file and cannot be separated safely, ask
   before you move it.
2. Check that `stash@{0}` has your label, then record its commit ID:
   `git -C <main-checkout> rev-parse stash@{0}`.
3. Create the worktree, then apply that ID there:
   `git -C <main-checkout>/.worktrees/<branch> stash apply --index <stash-commit>`.
4. Check that every intended change was restored. Immediately before you drop
   the stash, find the entry whose commit is the recorded ID in
   `git stash list --format='%gd %H'`, and drop only that entry. Never use bare
   `pop`.
5. Resolve a conflict when the combined result is clear (AGENTS.md, **Git**);
   never discard either side just to make a conflict disappear. On an ambiguous
   conflict, retain the stash and report its ID and both checkout paths.
6. Check `git status --short` in both checkouts.
