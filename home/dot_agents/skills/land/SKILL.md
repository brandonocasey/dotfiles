---
name: land
description: >
  Finish a feature branch: split the working tree into logical Conventional-Commit chunks,
  rebase onto the local main/master, fast-forward main to the branch, then delete the branch
  and remove the worktree. Local-only — never fetches, pushes, or force-anything. Use when the
  user says "land this", "land the branch", "ship the worktree", "merge into main and clean up",
  or invokes /land. Designed for the dedicated-worktree workflow.
---

Land the current branch into the local `main`/`master` and clean up after it. Everything is
local: no `fetch`, no `push`, no force. If anything is ambiguous or conflicts, STOP and ask —
never paper over a problem to keep the pipeline moving.

## 0. Detect context (always run first)

```sh
git rev-parse --abbrev-ref HEAD                         # current branch
git show-ref --verify --quiet refs/heads/main && echo main || echo master   # target name (main if the branch exists, else master)
git rev-parse --git-common-dir                          # shared dir → are we in a worktree?
git worktree list --porcelain                           # paths + which branch is where
git status --short                                      # is the tree dirty?
git log --oneline -8
```

Establish and hold these facts for the whole run:
- `BRANCH` — current branch (must NOT be `main`/`master`; if it is, stop — nothing to land).
- `TARGET` — `main` if `refs/heads/main` exists, else `master`.
- `IN_WORKTREE` — true if this checkout is a linked worktree (git-dir ≠ git-common-dir).
- `MAIN_WT` — the filesystem path of the worktree that has `TARGET` checked out (from
  `git worktree list`). Needed to ff-merge a checked-out branch.

If `TARGET` is checked out in a worktree that has **uncommitted changes** (staged or unstaged),
note it as `TARGET_DIRTY` — you'll stash those changes around the ff-merge in step 3, not bail.

## 1. Commit the working tree in logical chunks

Skip if the tree is already clean (nothing staged/unstaged/untracked).

- Read the full diff: `git status --short` then `git diff` and `git diff --staged`.
- Group changes into the smallest coherent units, split by **concern, then type, then pattern**.
  One commit = one reviewable idea. Don't bundle a refactor with a feature or a fix with docs.
- Stage each chunk explicitly (`git add <paths>`; use `git add -p` when a single file spans
  chunks). **Stage new/untracked files** that belong to the chunk.
- Follow this repo's Conventional Commit rules — defer to the project `commit` skill/command if
  present, otherwise: `<type>(<scope>): <description>`, lowercase imperative, ≤50 chars, no
  trailing period. Scope is required by commitlint (e.g. core, deps, config, docs, test). Body
  only when the *why* isn't obvious. No emojis, no attribution, no secrets. Use a heredoc:

  ```sh
  git commit -m "$(cat <<'EOF'
  feat(core): <description>
  EOF
  )"
  ```

- Let the pre-commit hook run. If it fails, **fix the cause** and re-commit — do not `--no-verify`
  unless the user has said the failure is irrelevant to the change (see the worktree-hook caveat
  the user keeps in memory for TS-only changes in unbuilt worktrees).
- Repeat until `git status --short` is empty.

After all chunks: show `git log --oneline <TARGET>..HEAD` so the user sees what's about to land.

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

## 4. Rebase onto the local target

```sh
git rebase <TARGET>
```

- This replays `BRANCH` onto the current local `TARGET` tip. No fetch — local only.
- On conflict: STOP. Show `git status`, the conflicting hunks, and ask how to resolve. Never
  auto-resolve by guessing or by picking a side. After the user resolves, continue with
  `git rebase --continue`; offer `git rebase --abort` to bail.
- If `TARGET` is already an ancestor of `BRANCH`, the rebase is a no-op — fine, proceed.

## 5. Fast-forward the target to the branch

The merge must be a clean fast-forward; if it can't be, the rebase in step 4 didn't take and you
should stop and investigate rather than create a merge commit.

**If `TARGET_DIRTY`** (the target tree has local uncommitted work): stash it first so the
fast-forward lands on a clean tree, then restore it afterward. Run the stash *in the worktree that
holds `TARGET`* — that's `MAIN_WT` in the worktree case, the current checkout otherwise. Use a
labelled, include-untracked stash so it's identifiable and nothing is left behind:

```sh
git -C <TARGET_WT> stash push --include-untracked -m "land: pre-ff autostash"
```

Confirm it was created (`git -C <TARGET_WT> stash list | head -1`). If `stash push` reports
"No local changes to save", treat the tree as clean and skip the pop below.

Do the fast-forward:

- **Not in a worktree** (plain feature branch in the main checkout):
  ```sh
  git switch <TARGET>
  git merge --ff-only <BRANCH>
  ```
- **In a worktree** (`TARGET` is checked out at `MAIN_WT`): run the ff-merge from that worktree so
  you're not pushing to a checked-out branch:
  ```sh
  git -C <MAIN_WT> merge --ff-only <BRANCH>
  ```

If `--ff-only` fails, STOP and report — do not fall back to a non-ff merge. (If you stashed, the
work is safe in the stash; tell the user it's there and how to restore it.)

**Restore the stash** after a successful ff (only if you created one above):

```sh
git -C <TARGET_WT> stash pop
```

- Clean pop → done; verify `git -C <TARGET_WT> status` looks as expected.
- **Conflicts on pop** (the landed commits touched the same lines as the stashed local work):
  resolve them. For each conflicted file, read both sides, reconcile by intent (the landed change
  is now the base; reapply the local edit on top so neither is lost — never just delete a side),
  then `git -C <TARGET_WT> add <file>`. When all are resolved, **drop the now-applied stash entry**
  with `git -C <TARGET_WT> stash drop` (a conflicted `stash pop` does NOT auto-drop). Do not create
  a commit — the restored changes stay as uncommitted local work, matching how they started.
  If a conflict is genuinely ambiguous, STOP and ask rather than guessing; the stash is intact.

## 6. Clean up

- Delete the landed branch (it's now an ancestor of `TARGET`, so `-d` is safe and refuses if it
  somehow isn't):
  ```sh
  git branch -d <BRANCH>          # run from a checkout that is NOT on BRANCH
  ```
- If `IN_WORKTREE`, remove the worktree. You can't remove the worktree you're standing in, so do
  it from `MAIN_WT`:
  ```sh
  git -C <MAIN_WT> worktree remove <worktree-path>
  git -C <MAIN_WT> worktree prune
  ```
  If `worktree remove` complains about leftover untracked/build artifacts that you trust are
  disposable (e.g. a worktree-local `target/`, symlinked `node_modules`), report what they are and
  ask before using `--force`.
- Branch deletion ordering: when in a worktree, delete the branch *after* removing the worktree
  (a branch checked out in a live worktree can't be deleted), running `git -C <MAIN_WT> branch -d`.

## 7. Report

End by stating, plainly: which commits landed (`<short> <subject>` each), the new `TARGET` tip,
what was cleaned up (branch deleted, worktree removed), and — if you stashed — that the target's
local changes were restored (and whether the pop needed conflict resolution). Do not push —
pushing is a separate, explicit step the user must ask for.

## Hard rules

- Local only: never `git fetch`/`pull`/`push` here.
- Never force-push, never `git merge` without `--ff-only`, never `rebase --skip` past a conflict.
- Never delete a branch that isn't fully merged into `TARGET` (rely on `branch -d`, not `-D`).
- A dirty target tree is handled by stash/ff/pop (step 3), not a hard stop — but stop and ask if
  the stash pop conflicts ambiguously, and never drop a stash you haven't successfully reapplied.
- Stop and ask on any rebase conflict, any non-ff, or any unexpected worktree state.
