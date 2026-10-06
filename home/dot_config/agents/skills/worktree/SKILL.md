---
name: worktree
description: "Create, reuse, or remove isolated Git worktrees before branch work."
---

Scope: Create, reuse, or remove an isolated Git worktree. Use before branch work.


# Git worktree

Do branch work in a worktree. Never switch branches in the main checkout.
`<main-checkout>` below is the first `worktree` entry of
`git worktree list --porcelain`. It is not `land`'s `MAIN_WT`, which can be
unset when the target branch is checked out nowhere.

## Create

Before creating or attaching a worktree, read [create.md](references/create.md).

## Prepare

Before checks or commits that require setup, read [prepare.md](references/prepare.md).

## Recover changes made in the main checkout

If this task already changed files in the main checkout, read
[recover-main-checkout.md](references/recover-main-checkout.md) before moving them.

## Restore a removed worktree

Before restoring a removed worktree, read [restore.md](references/restore.md).

## Remove

Before removing a worktree or branch, read [remove.md](references/remove.md).
It owns cleanup eligibility, preservation checks, and removal after push.
Batch cleanup runs only when the user invokes `clean-merged-worktrees`.

### Submodules

For removal with initialized submodules, follow **Remove**, then
[removal-checks.md](references/removal-checks.md), **Submodules**.

### Blocked removal

If ordinary removal fails, follow **Remove**, then
[removal-checks.md](references/removal-checks.md), **Blocked removal**.
