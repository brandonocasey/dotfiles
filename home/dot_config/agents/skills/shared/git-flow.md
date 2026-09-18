# Shared git flow — facts, commit gate, rules

Shared by the `land` and `ship` skills. Skills reference this file instead of duplicating it;
per-skill deltas live in each SKILL.md. Submodule handling lives in
[submodules.md](submodules.md). (No `SKILL.md` here on purpose — this directory is not
a skill.)

## Facts

Establish these first; refresh any fact after an action that changes it:

```sh
git rev-parse --abbrev-ref HEAD                         # current branch
git rev-parse --git-dir --git-common-dir                # the two differ → linked worktree
git worktree list --porcelain                           # paths + which branch is where
git status --short --ignore-submodules=none             # dirty? (flag defeats diff.ignoreSubmodules)
git log --oneline -8
```

- `BRANCH` — current branch. `HEAD` here means a detached checkout (for example a review
  worktree): STOP and ask which branch to use.
- `TARGET` — for `land`, resolve **Local target name** in
  [default-branch.md](default-branch.md); it never fetches. For `ship`, use
  the remote target from its setup step; no matching local branch is required.
- `COMMIT_BASE` — `TARGET` for `land`; the fetched target commit ID for `ship`.
  Use this revision for the commit report below.
- `IN_WORKTREE` — true if this checkout is a linked worktree (git-dir ≠ git-common-dir).
- `MAIN_WT` — filesystem path of the worktree that has `TARGET` checked out (from
  `git worktree list`). Unset if `TARGET` is not checked out anywhere.
- `TARGET_DIRTY` — true when the worktree holding `TARGET` has uncommitted changes (staged,
  unstaged, or untracked — check with
  `git -C <MAIN_WT> status --short --ignore-submodules=none`).

## Commit gate

Commit only the work authorized for this task. Identify unrelated staged,
unstaged, and untracked changes before invoking `commit`. Preserve them; if
they prevent the clean-tree gate below, ask how to handle them. Do not commit,
stash, or discard them just to clear the gate. Skip committing when the tree
is already clean.

- Load [commit](../commit/SKILL.md) through the harness's skill tool or read its
  file directly, and follow it — it owns reading the
  diff, the split rules, staging (new and untracked files included, hunk-level splits within one
  file), the message format, the amend-vs-new decision, and the hook-failure rule. Do not restate
  or re-derive any of that here. Defer to a project-level `commit` skill/command if one exists.
- Repeat for the authorized chunks, then check the gate below.

**Gate — the tree must be fully committed before anything moves.** Re-run
`git status --short --ignore-submodules=none`
and confirm it prints nothing. If anything remains, do NOT proceed: commit it only
if it is authorized task work; otherwise preserve it and ask what to do with it.

After all chunks: show `git log --oneline <COMMIT_BASE>..HEAD` so the user sees what is about to
move.

## Shared rules

- Never rebase, merge, push, or remove a worktree while the tree is dirty.
- Rebase/merge conflicts: resolve them when the combined result is clear — the global rules own
  this — then continue; STOP and ask when the intended result is ambiguous, and never guess or
  pick a side. Stop and ask on any unexpected worktree state.
- Never `rebase --skip` past a conflict.
- If anything is ambiguous, STOP and ask — never paper over a problem to keep the pipeline
  moving.
