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

Move your shell out of the worktree before you remove it. Git removes the
directory under you, and a shell left in a deleted directory fails every later
command with "Unable to read current working directory".

### Blocked removal

`git worktree remove` refuses a tree with modified tracked files or untracked
files. Ignored files never block it. Never commit, stash, or discard to clear
the block. Classify every blocker first; `--force` is allowed only when every
blocker is either already saved in the repository or disposable.

1. List the blockers:
   ```sh
   git -C <worktree-path> status --porcelain --untracked-files=all
   ```
2. Classify each path:
   - **Saved**: the file's current content already exists in the repository
     (a commit on any branch, or a stash). Evidence: this prints a commit:
     ```sh
     git -C <worktree-path> log --all -n 1 --oneline \
       --find-object=$(git -C <worktree-path> hash-object <file>)
     ```
   - **Disposable**: untracked (`??`) and generated: build or test output
     (`dist/`, `build/`, `coverage/`, `*.log`, `*.tsbuildinfo`, `.DS_Store`),
     dependency directories (`node_modules/`, `.venv/`, `vendor/`, `target/`),
     editor swap files. Source files, notes, `.env*`, and credentials are
     never disposable, even when untracked.
   - **Unknown**: anything else.
3. If any blocker is Unknown, retain the worktree, show a table with
   `path`, `class`, `evidence`, and ask.
4. Otherwise back up every Disposable file except dependency directories to
   the backups directory (AGENTS.md, **Directories**), keeping the relative
   paths. Saved files need no copy; record the commit that holds them.
5. Remove with a single `--force`, from outside the worktree:
   ```sh
   git -C <MAIN_WT> worktree remove --force <worktree-path>
   ```
   Never pass `--force` twice. A locked worktree (`locked` in
   `git worktree list --porcelain`) is never removed; report it.
6. Report each blocker with its class, evidence, and backup path.

For batch cleanup, the user invokes `clean-merged-worktrees` explicitly. Its
Claude frontmatter and Codex metadata both mark it explicit-only. Do not start
batch cleanup merely because a worktree task has ended.

## Related skills

- `ship` — push, open or update the MR/PR, and report without watching CI.
- `land` — local merge into the default branch, then cleanup.
- `commit` — chunking and Conventional Commit messages.
