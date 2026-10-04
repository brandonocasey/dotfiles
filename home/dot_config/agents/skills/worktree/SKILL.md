---
name: worktree
description: >
  Create, reuse, or remove an isolated Git worktree. Use before branch work.
---

# Git worktree

Do branch work in a worktree. Never switch branches in the main checkout.
`<main-checkout>` below is the first `worktree` entry of
`git worktree list --porcelain`. It is not `land`'s `MAIN_WT`, which can be
unset when the target branch is checked out nowhere.

## Create

For a separate task that depends on an unmerged MR/PR, first read
[dependent-branches.md](../shared/dependent-branches.md). Use its parent base
and record the child target and task boundary.
For an independent new branch, read [default-branch.md](../shared/default-branch.md) and
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

## Prepare

A new worktree has no ignored files: no dependencies, builds, or generated git
hooks. Install dependencies and build only when required by the affected checks,
commit hooks, or review evidence. A commit alone does not require installation;
check the repository's setup instructions and hooks first. Preserve all required
checks and hooks. Start required setup in the background and read code while it
runs; dependent checks or commits wait for it.

- When setup is required, run the worktree setup that the repo documents (the repo's agent
  instructions and the files they link, CONTRIBUTING, README). Without one, run the install of
  the lockfile's tool (npm, pnpm, yarn, bun, uv, poetry, cargo, or go) in the
  worktree root, with its frozen-lockfile option when it has one.
- Never symlink dependency directories from another checkout. Workspace links
  then resolve into that checkout.
- Only when the install fails for lack of network, clone dependencies
  copy-on-write from the source checkout:
  `cp -cR` on macOS, `cp --reflink=auto -R` on Linux. Do this only when both
  lockfiles are identical (`cmp`). Clone every dependency directory, nested
  ones included. Then run the lifecycle step that installs git hooks, for npm
  `npm run prepare --if-present`. Report that dependencies came from a clone.
- A setup step that changes a repo git setting needs consent under AGENTS.md
  **Git**.
- If a commit hook fails for missing files, finish Prepare and commit again;
  `commit` owns `--no-verify`. If Prepare fails, report the command and error
  as a blocker. Continue work that does not need the missing dependencies.
  Leave changes uncommitted when their hooks or checks need them.

## Recover changes made in the main checkout

If this task already changed files in the main checkout, read
[recover-main-checkout.md](references/recover-main-checkout.md) before moving them.

## Remove

A skill that creates a worktree for its own use, such as `review`, removes it
when its task ends unless its file says to keep it. Remove a task branch's
worktree once the branch is merged or pushed. Report the removed path or exact
blocker. Never remove the main checkout, a `locked` worktree, or a worktree
another task uses.

When the remote holds a task's work, clean up automatically at task end, without asking.
The remote holds the work when **Remove after push** proves that the remote tip equals the
local tip; a detached review worktree compares `HEAD` with its source branch. Remove the
worktree, the task's scratch directory, and the servers, browser pages, and ports the task
started. Run cleanup as its own command. Never chain it with approve, merge, ticket, or
other outward steps, so a blocked outward step cannot leave assets behind.

Take `<worktree-path>` from `git worktree list --porcelain`, because older
worktrees can live elsewhere:

```sh
git -C <main-checkout> worktree remove <worktree-path>
```

Move your shell out before removal. A shell in the deleted directory makes
later commands fail with "Unable to read current working directory".

### Remove after push

Use when the branch's work lives on the remote and the task has nothing more
to commit. Prove the remote holds the local tip before touching anything:

```sh
git ls-remote origin refs/heads/<branch>   # remote tip
git rev-parse <branch>                     # local tip; must be the same ID
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
must be set (`git push -u` sets it). Without one, `-d` checks against HEAD and
refuses a pushed branch: run `git branch -u origin/<branch> <branch>` and retry
`-d` once. Report the removed path and the branch's last commit ID; the remote
branch keeps the history.

To work on the branch again later (CI fix, review feedback):

```sh
git -C <main-checkout> fetch origin <branch>:refs/remotes/origin/<branch>
git -C <main-checkout> worktree add --track -b <branch> .worktrees/<branch> origin/<branch>
```

### Submodules

Before removing an initialized submodule worktree, read
[removal-checks.md](references/removal-checks.md), **Submodules**.
It owns the recorded, clean, and preserved commit checks and the single-force rule.

### Blocked removal

If ordinary removal fails, read
[removal-checks.md](references/removal-checks.md), **Blocked removal**.
Keep unknown work. Follow its classification, backup, and submodule checks
before any force removal. Never force removal of a locked worktree.

Batch cleanup runs only when the user invokes `clean-merged-worktrees`.
Do not start it because a worktree task ended.
