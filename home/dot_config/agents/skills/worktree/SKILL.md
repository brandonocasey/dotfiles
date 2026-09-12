---
name: worktree
description: >
  Use before branch work to create or reuse an isolated Git worktree. Select
  the newest default base across local and remote copies; preserve existing work.
---

# Git worktree

Do branch work in a worktree. Never switch branches in the main checkout.

## Create

For a new branch, read [default-branch.md](../shared/default-branch.md) and
follow **Newest default base**. It owns remote discovery and ancestry comparison.
Use the selected commit as `<base-commit>`:

```sh
git worktree add .worktrees/<branch> -b <branch> <base-commit>
```

- For an existing branch, first check `git worktree list --porcelain` and reuse
  its worktree when available. Otherwise run
  `git worktree add .worktrees/<branch> <branch>`. Do not reset its base.
- `.worktrees/` is ignored through the global excludes file
  (`~/.config/git/ignore`), so it needs no per-repo `.gitignore` entry.
- A branch created from a commit ID has no automatic remote upstream. Existing
  branches may have one; `ship` and `land` account for that.

Work inside `.worktrees/<branch>` for the whole task.

## Recover changes made in the main checkout

If you already changed files in the main checkout, move them into the worktree
so the main checkout stays clean:

Select the base as above before moving files. Stash only this task's changes;
leave unrelated user work in place. If ownership overlaps within a file and
cannot be separated safely, ask before moving it. Use a unique stash label and
record the created stash commit ID. Create the worktree, then apply that ID there
with `git stash apply --index <stash-commit>`. Drop the matching stash entry only
after checking that every intended change was restored. Resolve a stash-list ref
by its recorded commit ID immediately before dropping it; never use bare `pop`
or choose a repeated label. On an ambiguous conflict, retain the stash and report
its ID and both checkout paths.
Resolve merge, rebase, and stash conflicts automatically when the intended combined
result is clear. Ask only when the resolution is ambiguous; never discard either
side just to make a conflict disappear.

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

For batch cleanup, the user invokes `clean-merged-worktrees` explicitly. Its
Claude frontmatter and Codex metadata both mark it explicit-only. Do not start
batch cleanup merely because a worktree task has ended.

## Related skills

- `ship` — push, open or update the MR/PR, and report without watching CI.
- `land` — local merge into the default branch, then cleanup.
- `commit` — chunking and Conventional Commit messages.
