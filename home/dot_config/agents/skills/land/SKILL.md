---
disable-model-invocation: true
name: land
description: >
  Commit and land a branch into the local default branch, then clean up. Use
  for local landing requests; never fetch or push.
---

Land the current branch into the local `main`/`master` and clean up after it. Everything is
local: no `fetch`, no `push`, no force-push. If anything is ambiguous, STOP and ask — never paper
over a problem to keep the pipeline moving.

## 0. Detect context (always run first)

Read `git-flow.md` from the `shared/` directory next to this skill's own directory — resolve it
against this file's path (`<skills-dir>/shared/git-flow.md`), not against the current working
directory, which is the user's repo. Establish its **Facts**: `BRANCH`, `TARGET`, `IN_WORKTREE`,
`MAIN_WT`, `TARGET_DIRTY`. Refresh them before mutating the target or cleaning up.
`MAIN_WT` matters here because you can't ff-merge a branch that is checked out elsewhere;
`TARGET_DIRTY` means you'll stash those changes around the ff-merge (step 4), not bail.
Record the initial checkout path and the primary checkout path from
`git worktree list --porcelain` so cleanup can run from a surviving directory.

### Already on the target branch → commit only

If `BRANCH` == `TARGET`, there is nothing to rebase, fast-forward, or clean up: the work is
already on the target. Do **not** stop, and do **not** invent a branch to land. Instead, run the
`commit` skill over the working tree and finish there.

- Load [commit](../commit/SKILL.md) through the harness's skill tool or read its
  file directly, and follow it — it owns the
  chunking, message format, and amend-vs-new decision. Do not re-implement that logic here.
- If the tree is already clean, say so plainly and stop. A clean tree on `TARGET` means the work
  is already committed; there is no no-op "landing" to perform and nothing to report beyond the
  current tip.
- Skip steps 2–5 entirely (tests, rebase, ff-merge, cleanup). Those exist to move a branch onto
  `TARGET` and tear it down; none of it applies when you are already standing on `TARGET`.
- Report as step 6 describes, minus the branch/worktree lines: which commits were created (or
  that the tree was already clean) and the current `TARGET` tip. Still do not push.

This is the expected path in repos where work happens directly on the default branch. It is not
an error, so do not warn about it or suggest retroactively moving the commits onto a branch
unless the user asks.

## 1. Commit the working tree in logical chunks

Run the **Commit gate** from `shared/git-flow.md`. It owns task scope, the
clean-tree check, and the commit report. Nothing proceeds to rebase/ff while
the tree is dirty; cleanup requires every intended change to be committed.

## 2. Run tests

Run the project's test suite to verify the committed changes are green before rebasing.

- Detect the test command from the project: check `package.json` scripts for `test`, `test:unit`,
  or `test:ci`; fall back to common runners (`npm test`, `cargo test`, `go test ./...`, `pytest`,
  etc.) if no `package.json` is present.
- Run the test command and capture output.
- If tests fail: fix the failures. Make the minimal changes needed to make tests pass, then commit
  the fix as a separate logical commit following the same Conventional Commit rules as step 1.
  Re-run tests to confirm green before proceeding. If you cannot determine how to fix the failures,
  STOP and ask the user.
- If tests pass: continue.

## 3. Rebase onto the local target

```sh
git rebase <TARGET>
```

- This replays `BRANCH` onto the current local `TARGET` tip. No fetch — local only.
- On conflict: follow the **Shared rules** of `shared/git-flow.md` — resolve it when the
  combined result is clear; otherwise STOP, show `git status` and the conflicting hunks, and ask
  how to resolve. Then continue with `git rebase --continue`; offer `git rebase --abort` to bail.
- If `TARGET` is already an ancestor of `BRANCH`, the rebase is a no-op — fine, proceed.
- If the rebase replayed commits (it was not a no-op), re-run the step 2 tests before
  proceeding — the branch was tested on its old base, not on top of the current `TARGET`.

## 4. Fast-forward the target to the branch

The merge must be a clean fast-forward; if it can't be, the rebase in step 3 didn't take and you
should stop and investigate rather than create a merge commit.

**If `TARGET_DIRTY`** (the target tree has local uncommitted work): stash it first so the
fast-forward lands on a clean tree, then restore it afterward. Run the stash in `MAIN_WT` — the
worktree that holds `TARGET`. `TARGET_DIRTY` can only be true when `MAIN_WT` is set: an
unchecked-out branch has no working tree to dirty, so this block never runs without a path. Use a labelled, include-untracked stash so it's identifiable and
nothing is left behind. Use a unique `<stash-label>` for this run:

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
  worktree for the existing target and set `MAIN_WT` to its absolute path. Do not
  switch the main checkout:
  ```sh
  git worktree add <unused-target-worktree-path> <TARGET>
  git -C <MAIN_WT> merge --ff-only <BRANCH>
  ```
  Record that this run created it; remove it after successful cleanup, from a
  surviving checkout outside that directory (**Blocked removal** applies if it
  refuses). On failure, keep
  it if needed for recovery and report its path.

If `--ff-only` fails, STOP and report — do not fall back to a non-ff merge. (If you stashed, the
work is safe in the stash; tell the user it's there and how to restore it.)

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
not HEAD — so it can refuse a branch that was only landed locally. Run
`git branch --unset-upstream <BRANCH> || true` right before every `branch -d` below, so `-d`
checks against `TARGET` instead.

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
  to.
- Then delete the landed branch, from a checkout that is NOT on `BRANCH` (it's now an ancestor of
  `TARGET`, so `-d` is safe and refuses if it somehow isn't):
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
local changes were restored (and whether restoration needed conflict resolution). Do not push —
pushing is a separate, explicit step the user must ask for.

## Hard rules

- Everything in **Shared rules** of `shared/git-flow.md`.
- Local only: never `git fetch`/`pull`/`push` here.
- Never force-push, never `git merge` without `--ff-only`; on any non-ff, STOP and report
  (step 4) — never fall back to a merge commit.
- Never delete a branch that isn't fully merged into `TARGET` (rely on `branch -d`, not `-D`).
- Dirty target tree: the one exception to the shared dirty-tree rule — handled by stash/ff/apply
  (step 4), not a hard stop; but stop and ask if restoration conflicts ambiguously, and never
  drop a stash you haven't successfully reapplied.
- Being on `TARGET` already is not an error state: hand off to the `commit` skill (step 0) rather
  than stopping or fabricating a branch to land.
