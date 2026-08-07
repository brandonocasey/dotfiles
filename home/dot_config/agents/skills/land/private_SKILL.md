---
disable-model-invocation: true
name: land
description: >
  Finish a feature branch: split the working tree into logical Conventional-Commit chunks,
  rebase onto the local main/master, fast-forward main to the branch, then delete the branch
  and remove the worktree. When already on the default branch, degrades to just running the
  commit skill. Local-only — never fetches, pushes, or force-anything. Use when the user says
  "land this", "land the branch", "merge into main and clean up", or invokes /land. For pushing
  and opening an MR/PR use the ship skill instead. Designed for the dedicated-worktree workflow.
---

Land the current branch into the local `main`/`master` and clean up after it. Everything is
local: no `fetch`, no `push`, no force. If anything is ambiguous or conflicts, STOP and ask —
never paper over a problem to keep the pipeline moving.

## 0. Detect context (always run first)

Read `../shared/git-flow.md` (sibling of this skill's directory) and establish its **Facts**:
`BRANCH`, `TARGET`, `IN_WORKTREE`, `MAIN_WT`, `TARGET_DIRTY`. Hold them for the whole run.
`MAIN_WT` matters here because you can't ff-merge a branch that is checked out elsewhere;
`TARGET_DIRTY` means you'll stash those changes around the ff-merge (step 4), not bail.

### Already on the target branch → commit only

If `BRANCH` == `TARGET`, there is nothing to rebase, fast-forward, or clean up: the work is
already on the target. Do **not** stop, and do **not** invent a branch to land. Instead, run the
`commit` skill over the working tree and finish there.

- Invoke the `commit` skill (`Skill` tool, `skill: "commit"`) and follow it — it owns the
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

Run the **Commit gate** from `../shared/git-flow.md`: chunk via the `commit` skill until
`git status --short` prints nothing, then show `git log --oneline <TARGET>..HEAD`. Nothing
proceeds to rebase/ff while the tree is dirty — uncommitted work in the worktree is lost when
the worktree is removed in step 5.

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
- On conflict: STOP. Show `git status`, the conflicting hunks, and ask how to resolve. Never
  auto-resolve by guessing or by picking a side. After the user resolves, continue with
  `git rebase --continue`; offer `git rebase --abort` to bail.
- If `TARGET` is already an ancestor of `BRANCH`, the rebase is a no-op — fine, proceed.
- If the rebase replayed commits (it was not a no-op), re-run the step 2 tests before
  proceeding — the branch was tested on its old base, not on top of the current `TARGET`.

## 4. Fast-forward the target to the branch

The merge must be a clean fast-forward; if it can't be, the rebase in step 3 didn't take and you
should stop and investigate rather than create a merge commit.

**If `TARGET_DIRTY`** (the target tree has local uncommitted work): stash it first so the
fast-forward lands on a clean tree, then restore it afterward. Run the stash in `MAIN_WT` — the
worktree that holds `TARGET`. Use a labelled, include-untracked stash so it's identifiable and
nothing is left behind:

```sh
git -C <MAIN_WT> stash push --include-untracked -m "land: pre-ff autostash"
```

Confirm it was created (`git -C <MAIN_WT> stash list | head -1`). If `stash push` reports
"No local changes to save", treat the tree as clean and skip the pop below.

Do the fast-forward:

- **`TARGET` is checked out somewhere** (`MAIN_WT` is set): run the ff-merge from that worktree —
  you can't merge into a branch that is checked out elsewhere:
  ```sh
  git -C <MAIN_WT> merge --ff-only <BRANCH>
  ```
- **`TARGET` is not checked out anywhere** (`MAIN_WT` unset): switch to it here first:
  ```sh
  git switch <TARGET>
  git merge --ff-only <BRANCH>
  ```

If `--ff-only` fails, STOP and report — do not fall back to a non-ff merge. (If you stashed, the
work is safe in the stash; tell the user it's there and how to restore it.)

**Restore the stash** after a successful ff (only if you created one above):

```sh
git -C <MAIN_WT> stash pop
```

- Clean pop → done; verify `git -C <MAIN_WT> status` looks as expected.
- **Conflicts on pop** (the landed commits touched the same lines as the stashed local work):
  resolve them. For each conflicted file, read both sides, reconcile by intent (the landed change
  is now the base; reapply the local edit on top so neither is lost — never just delete a side),
  then `git -C <MAIN_WT> add <file>`. When all are resolved, **drop the now-applied stash entry**
  with `git -C <MAIN_WT> stash drop` (a conflicted `stash pop` does NOT auto-drop). Do not create
  a commit — the restored changes stay as uncommitted local work, matching how they started.
  If a conflict is genuinely ambiguous, STOP and ask rather than guessing; the stash is intact.

## 5. Clean up

- If `MAIN_WT` was unset and step 4 switched this checkout to `TARGET`: there is no separate
  worktree to remove (you are standing in the checkout that now holds `TARGET`) — skip the
  removal and delete the branch from here with `git branch -d <BRANCH>`.
- If `IN_WORKTREE`, remove the worktree first — a branch checked out in a live worktree can't be
  deleted. Move your shell out of the worktree before removing it: git happily removes the
  directory under you (`git -C <MAIN_WT>` does not move your cwd), and a shell left in the
  deleted directory fails every later command with "Unable to read current working directory".
  ```sh
  cd <MAIN_WT>
  git worktree remove <worktree-path>
  git worktree prune
  ```
  If `worktree remove` complains about leftover untracked/build artifacts that you trust are
  disposable (e.g. a worktree-local `target/`, symlinked `node_modules`), report what they are and
  ask before using `--force`.
- Then delete the landed branch, from a checkout that is NOT on `BRANCH` (it's now an ancestor of
  `TARGET`, so `-d` is safe and refuses if it somehow isn't):
  ```sh
  git -C <MAIN_WT> branch -d <BRANCH>
  ```

## 6. Report

End by stating, plainly: which commits landed (`<short> <subject>` each), the new `TARGET` tip,
what was cleaned up (branch deleted, worktree removed), and — if you stashed — that the target's
local changes were restored (and whether the pop needed conflict resolution). Do not push —
pushing is a separate, explicit step the user must ask for.

## Hard rules

- Everything in **Shared rules** of `../shared/git-flow.md`.
- Local only: never `git fetch`/`pull`/`push` here.
- Never force-push, never `git merge` without `--ff-only`; on any non-ff, STOP and report
  (step 4) — never fall back to a merge commit.
- Never delete a branch that isn't fully merged into `TARGET` (rely on `branch -d`, not `-D`).
- Dirty target tree: the one exception to the shared dirty-tree rule — handled by stash/ff/pop
  (step 4), not a hard stop; but stop and ask if the stash pop conflicts ambiguously, and never
  drop a stash you haven't successfully reapplied.
- Being on `TARGET` already is not an error state: hand off to the `commit` skill (step 0) rather
  than stopping or fabricating a branch to land.
