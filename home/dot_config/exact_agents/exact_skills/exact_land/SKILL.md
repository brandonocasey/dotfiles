---
model: claude-sonnet-5-5
effort: medium
name: land
description: "On request, commit and fast-forward into the local default branch, then clean up; never fetch or push."
---

Land the current branch into the local default branch (`TARGET`, resolved in
step 0), then clean up. The **Hard rules** apply to every step.

Start only when the user asked to land or merge locally. Otherwise ask one
question and stop.

## 0. Detect context (always run first)

Read [git-flow.md](../shared/git-flow.md), resolved against this file's path, not the
user's repo. Establish its **Facts**: `BRANCH`, `TARGET`, `COMMIT_BASE`, `IN_WORKTREE`,
`MAIN_WT`, `TARGET_DIRTY`. Refresh them before mutating the target or cleaning up.
Record the initial checkout path and the primary checkout path from
`git worktree list --porcelain` so cleanup can run from a surviving directory.
When `.gitmodules` exists, also read [submodules.md](../shared/submodules.md) and
establish its **Facts**. A changed owned submodule lands together with `BRANCH`: its
**Commit gate** runs before step 1. Read
[submodules.md](references/submodules.md) for its land steps: steps 1–3 run before the
superproject rebase and fast-forward, and its step 4 check runs after step 4 here.

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

- This replays `BRANCH` onto the current local `TARGET` tip.
- On conflict: follow the **Shared rules** of `shared/git-flow.md` — resolve it when the
  combined result is clear; otherwise stop, show `git status` and the conflicting hunks, and ask
  how to resolve. Then continue with `git rebase --continue`; offer `git rebase --abort` to cancel.
- If `TARGET` is already an ancestor of `BRANCH`, the rebase is a no-op — fine, proceed.
- Re-run the step 2 tests and the **Manual check** of `shared/git-flow.md` only
  when the rebase needed conflict resolution or edits; a clean rebase keeps
  earlier evidence and review records (the review bullet below still runs a
  review the change never had). The same applies after a step 2 fix commit.
- Then run any review that `review/references/when-to-run.md` triggers, pinned to
  `<TARGET>..<BRANCH>` so it needs no fetch. Skip it when `agt review status --default-branch <TARGET>`
  reports `reviewed: true` and an empty `unreviewed_commits`; otherwise review from
  its `review_from`. A review fix
  commit repeats the step 2 tests before step 4.

## 4. Fast-forward the target to the branch

The merge must fast-forward.

**If `TARGET_DIRTY`**: stash the target's local work first and restore it after the
fast-forward, per [dirty-target.md](references/dirty-target.md).

- **`TARGET` is checked out somewhere** (`MAIN_WT` is set): run the ff-merge from that worktree —
  you can't merge into a branch that is checked out elsewhere:
  ```sh
  git -C <MAIN_WT> merge --ff-only <BRANCH>
  ```
- **`TARGET` is not checked out anywhere** (`MAIN_WT` unset): create a temporary
  worktree and merge there, per [temp-target.md](references/temp-target.md).

If `--ff-only` fails, stop and report. Never fall back to a non-fast-forward merge.

## 5. Clean up

Run cleanup automatically after a successful land, before reporting completion.
The land request includes it: do not ask for confirmation or offer it as a
follow-up. Keep the `worktree` skill's safety checks; ask only for blockers it
requires the user to resolve.

Follow [task-resources.md](../host-preflight/references/task-resources.md) for
task-owned servers, processes, browser resources, and disposable files
(including `.cache/agents/scratch/<task>/`). If a live preview still needs a
server, files, or a worktree, keep them, report the exception and its URL, and
defer worktree removal until the preview ends.

- If `IN_WORKTREE`, remove the worktree first — a branch checked out in a live worktree can't be
  deleted. Move your shell out of it first, per the `worktree` skill's **Remove** section, which
  owns that rule. Needs `agt` 0.10.0 ([agt.md](../shared/agt.md)):
  ```sh
  cd <MAIN_WT>
  agt worktree remove <worktree-path> --yes
  ```
  Report the backup id it prints. If it refuses, follow the `worktree` skill's **Blocked removal** and **Submodules** sections, keep the branch, and report the refusal.
- Then delete the landed branch, from a checkout that is not on `BRANCH` (it is now an ancestor
  of `TARGET`, so `-d` is safe and refuses if it somehow is not):
  ```sh
  git -C <MAIN_WT> branch --unset-upstream <BRANCH> || true
  git -C <MAIN_WT> branch -d <BRANCH>
  ```
  When `IN_WORKTREE` is false, `BRANCH` is still checked out here and git refuses the delete:
  leave the branch and say so in the step 6 report.
- If step 4 created a temporary target worktree, remove it last, per
  [temp-target.md](references/temp-target.md).

## 6. Report

End by stating, plainly: which commits landed (`<short> <subject>` each), the `Checked:` line
from the commit gate, the new `TARGET` tip,
what was cleaned up (branch deleted, worktree removed), and — if you stashed — that the target's
local changes were restored (and whether restoration needed conflict resolution).

## Hard rules

- Everything in **Shared rules** of `shared/git-flow.md`.
- Local only: never `git fetch`/`pull`/`push`, except the local-path fetches between
  submodule clones in [submodules.md](references/submodules.md) steps 1–2.
- Never `git merge` without `--ff-only`; never `branch -D`.
- A dirty target tree is the one exception to the shared dirty-tree rule
  ([dirty-target.md](references/dirty-target.md)). Never drop a stash you have not
  successfully reapplied.
