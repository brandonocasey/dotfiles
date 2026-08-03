# Shared git flow — facts, commit gate, rules

Shared by the `land` and `ship` skills. Skills reference this file instead of duplicating it;
per-skill deltas live in each SKILL.md. (No `SKILL.md` here on purpose — this directory is not
a skill.)

## Facts

Establish these first and hold them for the whole run:

```sh
git rev-parse --abbrev-ref HEAD                         # current branch
git show-ref --verify --quiet refs/heads/main && echo main || echo master   # target name
git rev-parse --git-common-dir                          # shared dir → are we in a worktree?
git worktree list --porcelain                           # paths + which branch is where
git status --short                                      # is the tree dirty?
git log --oneline -8
```

- `BRANCH` — current branch.
- `TARGET` — `main` if `refs/heads/main` exists, else `master`.
- `IN_WORKTREE` — true if this checkout is a linked worktree (git-dir ≠ git-common-dir).
- `MAIN_WT` — filesystem path of the worktree that has `TARGET` checked out (from
  `git worktree list`). Unset if `TARGET` is not checked out anywhere.
- `TARGET_DIRTY` — true when the worktree holding `TARGET` has uncommitted changes (staged or
  unstaged).

## Commit gate

Skip if the tree is already clean (nothing staged, unstaged, or untracked).

- Read the full diff: `git status --short`, then `git diff` and `git diff --staged`.
- Chunk and write messages per the `commit` skill (`Skill` tool, `skill: "commit"`) — it owns
  the split rules, message format, and amend-vs-new decision. Defer to a project-level `commit`
  skill/command if one exists.
- Stage each chunk explicitly (`git add <paths>`; use `git add -p` when a single file spans
  chunks). **Stage new/untracked files** that belong to the chunk.
- Let the pre-commit hook run. If it fails, **fix the cause** and re-commit — do not
  `--no-verify` unless the user has said the failure is irrelevant to the change.
- Repeat until `git status --short` is empty.

**Gate — the tree must be fully committed before anything moves.** Re-run `git status --short`
and confirm it prints nothing. If anything remains, do NOT proceed: either commit it as another
logical chunk or, if it is genuinely not meant to go, STOP and ask the user what to do with it.

After all chunks: show `git log --oneline <TARGET>..HEAD` so the user sees what is about to
move.

## Shared rules

- Never rebase, merge, push, or remove a worktree while the tree is dirty.
- Stop and ask on any rebase/merge conflict or unexpected worktree state — never auto-resolve
  by guessing or by picking a side.
- Never `rebase --skip` past a conflict.
- If anything is ambiguous, STOP and ask — never paper over a problem to keep the pipeline
  moving.
