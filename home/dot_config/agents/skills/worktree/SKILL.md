---
name: worktree
description: >
  Use before branch work to create or reuse an isolated Git worktree. Select
  the newest default base across local and remote copies; preserve existing work.
---

# Git worktree

Do branch work in a worktree. Never switch branches in the main checkout.
`<main-checkout>` below is the first `worktree` entry of
`git worktree list --porcelain`. It is not `land`'s `MAIN_WT`, which can be
unset when the target branch is checked out nowhere.

## Create

For a new branch, read [default-branch.md](../shared/default-branch.md) and
follow **Newest default base**. It owns remote discovery and ancestry comparison.
Use the selected commit as `<base-commit>`. Create every worktree under
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
- A branch created from a commit ID has no automatic remote upstream. Existing
  branches may have one; `ship` and `land` account for that.

- A new worktree leaves every submodule directory empty. When `.gitmodules`
  exists, initialize them before work:
  `git -C <main-checkout>/.worktrees/<branch> submodule update --init --recursive`.
  This leaves each submodule on a detached HEAD. Before you commit inside a
  submodule, create a branch there (`git -C <sub-path> switch -c <branch>`),
  so the commit has a ref to push and cannot be orphaned by the next update.

Work inside `<main-checkout>/.worktrees/<branch>` for the whole task.

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

The global rules (AGENTS.md, **General**) own the `PORT` rule: one exported
open port per worktree, released when the task ends.

## Remove

Every worktree a skill creates is removed by that skill when its task ends,
unless that skill's own file says the worktree stays: `review` after the report
or the `--fix` push, `land` after the fast-forward, `ship` after the verified
push (**Remove after push**), `benchmark-change` after the measurements are
recorded. `run-task-list`, `repo-audit`, and `pr-unblock` keep a worktree that
holds unlanded or unpushed commits and name it in their reports. Removal is
part of the deliverable: the report names the removed path, or the exact
blocker that stopped it. Never remove the main checkout, a `locked` worktree,
or a worktree another task still uses.

Remove the worktree once the branch is merged or pushed. Take `<worktree-path>`
from `git worktree list --porcelain`, because older worktrees can live elsewhere:

```sh
git -C <main-checkout> worktree remove <worktree-path>
```

Move your shell out of the worktree before you remove it. Git removes the
directory under you, and a shell left in a deleted directory fails every later
command with "Unable to read current working directory".

### Remove after push

Use when the branch's work lives on the remote and the task has nothing more
to commit. Prove the remote holds the local tip before touching anything:

```sh
git ls-remote origin refs/heads/<branch>   # remote tip
git rev-parse <branch>                     # local tip; MUST be the same ID
```

Pass the full ref: a bare `<branch>` pattern also matches
`refs/heads/<prefix>/<branch>` and can print a second ID.
If the IDs differ, `ls-remote` prints nothing, or the command fails, keep the
worktree and the branch and report both IDs. Otherwise, with your shell in
`<main-checkout>`:

```sh
git -C <main-checkout> worktree remove <worktree-path>
git -C <main-checkout> branch -d <branch>
git -C <main-checkout> worktree prune
```

`branch -d` checks the branch against its upstream and refuses a tip the
upstream lacks. Never answer that refusal with `-D`; report it. The upstream
MUST be set (`git push -u` sets it). Without one, `-d` checks against HEAD and
refuses a pushed branch: run `git branch -u origin/<branch> <branch>` and retry
`-d` once. Report the removed path and the branch's last commit ID; the remote
branch keeps the history.

To work on the branch again later (CI fix, review feedback):

```sh
git fetch origin <branch>:refs/remotes/origin/<branch>
git -C <main-checkout> worktree add --track -b <branch> .worktrees/<branch> origin/<branch>
```

### Submodules

Git refuses to remove a worktree that holds an initialized submodule, clean or
not: `working trees containing submodules cannot be moved or removed`. Only
`--force` removes it, and `--force` deletes the submodule's git directory under
`.git/worktrees/<name>/modules/`, so a submodule commit that exists nowhere else
is lost. Before that single `--force`, prove all three points for every
initialized submodule (an entry of `git -C <worktree-path> submodule status
--recursive` without a leading `-`):

1. **Recorded**: the entry has no `+` or `U` prefix. `+` means the checked-out
   commit differs from the gitlink the superproject records, which is an
   uncommitted change; `U` is a merge conflict. Treat either like a modified
   tracked file.
2. **Clean**: `git -C <sub-path> status --porcelain --ignore-submodules=none`
   prints nothing.
3. **Preserved**: the commit exists outside this worktree's clone. Either
   `git -C <sub-path> fetch --quiet` and then
   `git -C <sub-path> branch -r --contains HEAD` prints a remote branch, or
   the main checkout's clone holds it:
   `git -C <main-checkout>/<sub-path> merge-base --is-ancestor <commit> <sub-target>`
   succeeds (the `land` path in `shared/submodules.md`). Neither: push the
   commit to the submodule's remote first, or keep the worktree and report the
   submodule path and commit ID.

When all three hold for every submodule and no other blocker exists, remove
with `--force` once, as in **Blocked removal** step 5. Uninitialized
submodules (`-` prefix, empty directory) never block removal.

### Blocked removal

`git worktree remove` refuses a tree with modified tracked files or untracked
files. Ignored files never block it. Never commit, stash, or discard to clear
the block. Classify every blocker first; `--force` is allowed only when every
blocker is either already saved in the repository or disposable, and every
initialized submodule passes **Submodules**.

1. List the blockers. `--ignore-submodules=none` is required: the global
   `diff.ignoreSubmodules=dirty` setting hides dirty submodules otherwise.
   ```sh
   git -C <worktree-path> status --porcelain --untracked-files=all \
     --ignore-submodules=none
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
   git -C <main-checkout> worktree remove --force <worktree-path>
   ```
   Never pass `--force` twice. A locked worktree (`locked` in
   `git worktree list --porcelain`) is never removed; report it.
6. Report each blocker with its class, evidence, and backup path.

For batch cleanup, the user invokes `clean-merged-worktrees` explicitly. Its
Claude frontmatter and Codex metadata both mark it explicit-only. Do not start
batch cleanup merely because a worktree task has ended.

## Related skills

- `ship` — push, open or update the MR/PR, remove the pushed worktree, and
  report without watching CI.
- `land` — local merge into the default branch, then cleanup.
- `commit` — chunking and Conventional Commit messages.
