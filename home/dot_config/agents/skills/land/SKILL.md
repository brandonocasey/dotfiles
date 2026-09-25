---
disable-model-invocation: true
name: land
description: >
  Commit and land a branch into the local default branch, then clean up. Use
  for local landing requests; never fetch or push.
---

Land the current branch into the local default branch (`TARGET`, resolved in
step 0), then clean up. The **Hard rules** apply to every step.

## 0. Detect context (always run first)

Read [git-flow.md](../shared/git-flow.md), resolved against this file's path, not the
user's repo. Establish its **Facts**: `BRANCH`, `TARGET`, `COMMIT_BASE`, `IN_WORKTREE`,
`MAIN_WT`, `TARGET_DIRTY`. Refresh them before mutating the target or cleaning up.
Record the initial checkout path and the primary checkout path from
`git worktree list --porcelain` so cleanup can run from a surviving directory.
When `.gitmodules` exists, also read [submodules.md](../shared/submodules.md) and
establish its **Facts**. A changed owned submodule lands together with `BRANCH`: its
**Commit gate** runs before step 1, its **Land** steps 1–3 run before the superproject
rebase and fast-forward, and its step 4 check runs after step 4 here.

### Already on the target branch → commit only

If `BRANCH` == `TARGET`, do not stop or invent a branch. Do not warn or suggest
moving commits unless the user asks.

- Run the **Commit gate** from `shared/git-flow.md`, except its final clean-tree
  check: nothing moves on this path.
- If the tree is already clean, say so plainly and stop.
- Skip steps 2–5 (tests, rebase, ff-merge, cleanup).
- Report as step 6 describes, minus the branch/worktree lines: which commits were created (or
  that the tree was already clean) and the current `TARGET` tip. Still do not push.

## 1. Commit the working tree in logical chunks

Run the **Commit gate** from `shared/git-flow.md`. It owns task scope, the
clean-tree check, and the commit report. Nothing proceeds to rebase/ff while
the tree is dirty; cleanup requires every intended change to be committed.

## 2. Run tests

Run the project's test suite before rebasing.

- Detect the test command from the project: check `package.json` scripts for `test`, `test:unit`,
  or `test:ci`; without a `package.json`, fall back to common runners (`cargo test`,
  `go test ./...`, `pytest`, etc.).
- Run the test command and capture its output.
- If tests fail: fix the failures. Make the minimal changes needed to make tests pass, then commit
  the fix as a separate logical commit through the `commit` skill. Re-run tests to check that
  they pass before proceeding. If you cannot determine how to fix the failures, stop and ask
  the user.

## 3. Rebase onto the local target

```sh
git rebase <TARGET>
```

- This replays `BRANCH` onto the current local `TARGET` tip. No fetch — local only.
- On conflict: follow the **Shared rules** of `shared/git-flow.md` — resolve it when the
  combined result is clear; otherwise stop, show `git status` and the conflicting hunks, and ask
  how to resolve. Then continue with `git rebase --continue`; offer `git rebase --abort` to cancel.
- If `TARGET` is already an ancestor of `BRANCH`, the rebase is a no-op — fine, proceed.
- If the rebase replayed commits (it was not a no-op), re-run the step 2 tests before
  proceeding — the branch was tested on its old base, not on top of the current `TARGET`.

## 4. Fast-forward the target to the branch

The merge must fast-forward. If it cannot, stop and investigate the rebase.

**If `TARGET_DIRTY`** (the target tree has local uncommitted work): stash it first so the
fast-forward lands on a clean tree, then restore it afterward. Run the stash in `MAIN_WT` — the
worktree that holds `TARGET`. Use a labelled, include-untracked stash with a unique
`<stash-label>` for this run, so it is identifiable and nothing is left behind:

```sh
git -C <MAIN_WT> stash push --include-untracked -m <stash-label>
```

Verify the entry has this run's label and record its commit ID, not its stack
position. If `stash push` reports "No local changes to save", skip restoration.

Do the fast-forward:

- **`TARGET` is checked out somewhere** (`MAIN_WT` is set): run the ff-merge from that worktree —
  you can't merge into a branch that is checked out elsewhere:
  ```sh
  git -C <MAIN_WT> merge --ff-only <BRANCH>
  ```
- **`TARGET` is not checked out anywhere** (`MAIN_WT` unset): create a temporary
  worktree for the existing target under the primary checkout, never nested in
  another worktree, and set `MAIN_WT` to its absolute path. Do not switch the main
  checkout:
  ```sh
  git -C <primary-checkout> worktree add .worktrees/<unused-name> <TARGET>
  git -C <MAIN_WT> merge --ff-only <BRANCH>
  ```
  Record that this run created it; remove it after successful cleanup, from a
  surviving checkout outside that directory (the `worktree` skill's **Blocked
  removal** applies if it refuses). On failure, keep it if needed for recovery and
  report its path.

If `--ff-only` fails, stop and report. If you stashed, report the stash and how
to restore it. Never fall back to a non-fast-forward merge.

**Restore the stash** after a successful ff, only if this run created one. Apply
the recorded commit ID so another stash cannot change which work is restored:

```sh
git -C <MAIN_WT> stash apply --index <stash-commit>
```

If that commit cannot be identified as this run's stash, stop and report.

- Clean apply: verify the restored files and staging state against the recorded
  pre-stash status, then find the entry by commit ID in
  `git stash list --format='%gd %H'` and drop only that matching entry. Recheck
  the ref's commit immediately before dropping it; retain it on any mismatch.
- **Conflicts on apply** (the landed commits touched the same lines as the stashed local work):
  resolve them. For each conflicted file, read both sides, reconcile by intent (the landed change
  is now the base; reapply the local edit on top so neither is lost — never just delete a side),
  then `git -C <MAIN_WT> add <file>`. When all are resolved, check the restored work
  and drop only the entry matching the recorded commit ID as above. Do not create
  a commit — the restored changes stay as uncommitted local work, matching how they started.
  If a conflict is ambiguous, stop and ask; the stash is intact.

## 5. Clean up

A branch may track a remote upstream, and `git branch -d` checks against that upstream,
not HEAD — so it can refuse a branch that was only landed locally. The delete below unsets the
upstream first, so `-d` checks against `TARGET` instead.

- If `IN_WORKTREE`, remove the worktree first — a branch checked out in a live worktree can't be
  deleted. Move your shell out of it first, per the `worktree` skill's **Remove** section, which
  owns that rule (`git -C <MAIN_WT>` does not move your cwd):
  ```sh
  cd <MAIN_WT>
  git worktree remove <worktree-path>
  git worktree prune
  ```
  If removal refuses, follow the `worktree` skill's **Blocked removal** section. It
  owns the classification, the backup, and the single `--force`; ask only when it says
  to. A worktree with initialized submodules always refuses plain removal; the same
  skill's **Submodules** section decides whether `--force` is allowed.
  Cleanup is not optional: the step 6 report names the removed path and the deleted
  branch, or the exact blocker (path, class, evidence) that kept them.
- Then delete the landed branch, from a checkout that is not on `BRANCH` (it is now an ancestor
  of `TARGET`, so `-d` is safe and refuses if it somehow is not):
  ```sh
  git -C <MAIN_WT> branch --unset-upstream <BRANCH> || true
  git -C <MAIN_WT> branch -d <BRANCH>
  ```
  When `IN_WORKTREE` is false, `BRANCH` is still checked out here and git refuses the delete:
  leave the branch and say so in the step 6 report.
- If step 4 created a temporary target worktree, move to the primary checkout and
  remove that temporary worktree after the merge and source cleanup.
  Do this even when the source branch must stay checked out in the primary checkout.
  If the temporary tree has become dirty or active, retain it and report its path.
  Never remove a target worktree that existed before this run.

## 6. Report

End by stating, plainly: which commits landed (`<short> <subject>` each), the new `TARGET` tip,
what was cleaned up (branch deleted, worktree removed), and — if you stashed — that the target's
local changes were restored (and whether restoration needed conflict resolution).

## Hard rules

- Everything in **Shared rules** of `shared/git-flow.md`.
- Local only: never `git fetch`/`pull`/`push` here. The exceptions are the local-path
  fetches between two submodule clones in `shared/submodules.md` **Land** steps 1–2.
- Never `git merge` without `--ff-only`, and never fall back to a merge commit (step 4).
- Never delete a branch that is not fully merged into `TARGET` (rely on `branch -d`, not `-D`).
- A dirty target tree is the one exception to the shared dirty-tree rule: step 4 stashes and
  restores it. Never drop a stash you have not successfully reapplied.
