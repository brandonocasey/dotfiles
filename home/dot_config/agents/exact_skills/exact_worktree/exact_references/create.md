## Create

For a separate task that depends on an unmerged MR/PR, first read
[dependent-branches.md](../../shared/dependent-branches.md). Use its parent base
and record the child target and task boundary.
For an independent new branch, read [default-branch.md](../../shared/default-branch.md) and
follow **Newest default base**. It owns remote discovery and ancestry comparison.
Use the selected commit as `<base-commit>`. Create worktrees under
`<main-checkout>/.worktrees/`, even when the session starts in a subdirectory
or in another worktree: removing an outer worktree also deletes a worktree
nested in it, because ignored files never block removal. If the first entry is
marked `bare`, it is the repository itself: ask where to create the worktree.

```sh
git -C <main-checkout> worktree add .worktrees/<branch> -b <branch> <base-commit>
```

- For an existing branch, first check `git worktree list --porcelain` and reuse
  its worktree when available. Otherwise run
  `git -C <main-checkout> worktree add .worktrees/<branch> <branch>`. Do not
  reset its base.
- `.worktrees/` is ignored through the global excludes file
  (`~/.config/git/ignore`), so it needs no per-repo `.gitignore` entry.
- A new worktree leaves every submodule directory empty. When `.gitmodules`
  exists, initialize them before work:
  `git -C <main-checkout>/.worktrees/<branch> submodule update --init --recursive`.
  This leaves submodules on detached HEADs. Before a submodule commit, create
  a branch there: `git -C <sub-path> switch -c <branch>`. This gives the commit
  a pushable ref and prevents the next update from orphaning it.

Work inside `<main-checkout>/.worktrees/<branch>` for the whole task.
