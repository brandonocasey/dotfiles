---
name: worktree
description: >
  Create, use, and remove a git worktree for branch work. Owns the exact
  commands, the base-branch rule, and the recovery step for changes made in the
  main checkout by mistake. Load before you start work on any new or existing
  branch. For push plus MR/PR use ship; for local merge and cleanup use land.
---

# Git worktree

Do branch work in a worktree. Never switch branches in the main checkout.

## Create

```sh
git fetch origin
git worktree add .worktrees/<branch> -b <branch> origin/<default>
```

- Find `<default>` in this order: the branch `git symbolic-ref --short
  refs/remotes/origin/HEAD` names, then `main` if `refs/heads/main` exists, then
  `master`. Ask the user if none of the three resolves. Do not pick a name from a
  naming convention alone — a repo can have a local `master` and a remote
  `origin/main`, and `origin/<default>` must name a ref that exists on the remote.
- Base the branch on the freshly fetched default branch, unless the user asks
  for a different base.
- For a branch that already exists, drop `-b`:
  `git worktree add .worktrees/<branch> <branch>`.
- `.worktrees/` is ignored through the global excludes file
  (`~/.config/git/ignore`), so it needs no per-repo `.gitignore` entry.

Work inside `.worktrees/<branch>` for the whole task.

## Recover changes made in the main checkout

If you already changed files in the main checkout, move them into the worktree
so the main checkout stays clean:

```sh
git stash push -u -m move-to-worktree
git worktree add .worktrees/<branch> -b <branch> origin/<default>
git -C .worktrees/<branch> stash pop
```

The bare `stash pop` is safe only because nothing else stashes between the push and
the pop. If any other stash was pushed in between, pop the `move-to-worktree` entry
by the ref that `git stash list` shows for that label.

Check `git status --short` in both checkouts afterwards.

## Ports

Give each worktree its own `PORT` from the open ports, and export it, so
parallel agents do not collide.

## Remove

Remove the worktree once the branch is merged:

```sh
git worktree remove .worktrees/<branch>
```

The tree must be clean first. `git worktree remove` refuses a dirty tree, and
you must never force it — commit or ask the user instead.

Move your shell out of the worktree before you remove it. Git removes the
directory under you, and a shell left in a deleted directory fails every later
command with "Unable to read current working directory".

To clean up several merged worktrees at once, use the `clean-merged-worktrees`
skill. It sets `disable-model-invocation`, so only the user can invoke it with
`/clean-merged-worktrees` — say so instead of trying to load it yourself.

## Related skills

- `ship` — push, open the MR/PR, watch CI.
- `land` — local merge into the default branch, then cleanup.
- `commit` — chunking and Conventional Commit messages.
