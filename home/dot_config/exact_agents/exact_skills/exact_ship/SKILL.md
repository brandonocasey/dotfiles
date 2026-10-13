---
name: ship
description: "Commit, push, and open/update PRs/MRs with Git authorization; merge only when requested."
---

Ship the current branch: push it, open or update the MR/PR, and report. When
the argument names a local branch, run every step from that branch's worktree.
Create one with the `worktree` skill if none exists. Other argument text is a
task to finish first.
Parse `--merge` as an option, not a branch or task name.
With several branch names or `all`, ship each branch in turn, a parent before
its dependent children. For `all`, list the branches that have a `.worktrees/`
worktree with a clean tree and commits ahead of `TARGET`, excluding worktrees
another task uses. Show each with its ahead count and ask once before the first
push. For branches that depend on each other, follow **Chains of dependent
MRs/PRs** in [dependent-branches.md](../shared/dependent-branches.md).
Ordinary shipping ends after the push, MR/PR update, and any triggered review with its fix push.
With `--merge`, read [merge.md](references/merge.md) before mutations to check
platform support and scope. Continue that workflow after shipping.

When a `session-resume` record exists for the task, read it before the context
check and apply `session-resume`'s reuse rules.

Start only with push authorization under [git-policy.md](../shared/git-policy.md). Without it,
ask one question and stop. With it, run every step yourself. Never tell the
user to type `/ship`.

## 0. Detect context (always run first)

Always read first: [context.md](references/context.md).

## 1. Commit gate

Run the **Commit gate** from `shared/git-flow.md`. It owns task scope, the
clean-tree check, and the commit report against `COMMIT_BASE`. With a changed
submodule, run the **Commit gate** in `shared/submodules.md` first; it gates the
submodule and the gitlink bump before the superproject.

## 2. Push

Immediately before any push, refresh `BRANCH` and resolve the live
`REMOTE_DEFAULT` again. Stop if `BRANCH` equals it or `TARGET`.
Pause auto-merge on `EXISTING` and any submodule MR/PR per
[auto-merge-pause.md](../shared/auto-merge-pause.md). If `EXISTING` is queued,
follow its **Queued MR/PR** rule, then rerun step 0 on the new branch.

- First push, or new commits on an already-pushed branch: `git push -u origin <BRANCH>`.
- Branch exists on the remote but histories diverged (rebase/amend since last push):
  `git push --force-with-lease --force-if-includes origin <BRANCH>`.
  If rejected, reconcile remote changes and rerun affected checks; never drop either safeguard.
  Never plain `--force`; never any force on
  `TARGET` or `REMOTE_DEFAULT`; never push either from this skill.
- With a changed owned submodule, follow **Ship** in
  [submodules.md](../shared/submodules.md) first; it owns the submodule push and
  the superproject's `--recurse-submodules=check` push.
- Check that the push landed (`git status -sb` shows no ahead-count) and say so — the user
  should never have to ask "did you push?".
- Record `HEAD_SHA` from `git ls-remote origin refs/heads/<BRANCH>`. Record it
  again after each later push. Step 6 and `merge.md` use it.

## 3. Open or update the MR/PR

- Refresh `EXISTING` before creation. Update it instead of creating a duplicate.
  If its base changed during this run, reread it before deciding the target.
- **Title**: the repo's commit/MR convention — read the repo's AGENTS.md / CLAUDE.md /
  CONTRIBUTING for it. For conventional titles, choose the type with the `commit` skill's
  **Choosing the type** procedure; a squash merge makes the title the commit. Include `TICKET` when set. If the repo requires a ticket and there is
  none, never invent a key:
  - The user asked for a ticket: run [mr-ticket](../mr-ticket/SKILL.md) and use its key.
  - The user said no ticket: ship without one.
  - Otherwise ask once, with the options: create a ticket, no ticket, or use a key.
- **Description**: read [writing.md](references/writing.md) and follow the repository template
  or its default description format.
- Use the recorded `TARGET`. Leave draft state alone unless asked.
- When `TICKET` is set, move it to the open-MR/PR status per [mr-ticket](../mr-ticket/SKILL.md) step 6.

## 4. Finish the requested scope

Before finishing the requested shipping scope: [finish-scope.md](references/finish-scope.md).

## 5. Clean up

Follow [task-resources.md](../host-preflight/references/task-resources.md),
except keep a running CI watch from step 4. Keep a worktree and its branch while
the MR/PR is open, unless the user requests cleanup; after merge or closure, use
the `worktree` skill's **Remove** section. If `IN_WORKTREE` is false, leave the
main checkout and its branch in place. Report retained paths and reasons.

## 6. Report

Before reporting shipping results: [report.md](references/report.md).

## Hard rules

- Never merge, approve, close, or mark ready unless the user asks.
- Create or transition tickets only through `mr-ticket`, per step 3. Reuse keys you find.
  Transitions move `TICKET` forward only.
- Everything in **Shared rules** of `shared/git-flow.md`.
