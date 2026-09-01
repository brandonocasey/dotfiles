# Shared git flow — facts, commit gate, rules

Shared by the `land` and `ship` skills. Skills reference this file instead of duplicating it;
per-skill deltas live in each SKILL.md. (No `SKILL.md` here on purpose — this directory is not
a skill.)

## Facts

Establish these first and hold them for the whole run:

```sh
git rev-parse --abbrev-ref HEAD                         # current branch
git symbolic-ref --short refs/remotes/origin/HEAD       # origin's default, e.g. origin/main
git rev-parse --git-dir --git-common-dir                # the two differ → linked worktree
git worktree list --porcelain                           # paths + which branch is where
git status --short                                      # is the tree dirty?
git log --oneline -8
```

- `BRANCH` — current branch. `HEAD` here means a detached checkout (for example a review
  worktree): STOP and ask which branch to use.
- `TARGET` — the default branch, resolved per the `worktree` skill's order, which owns this
  rule: the branch `refs/remotes/origin/HEAD` names (strip the `origin/` prefix), then local
  `main`, then local `master`. Never pick a name from a naming convention alone. `TARGET` must
  be a **local** branch here, because `land` and `ship` rebase and fast-forward against it: if
  `origin/HEAD` names a branch with no local ref, fall through to `main`/`master`. Ask the user
  if none of the three resolves.
- `IN_WORKTREE` — true if this checkout is a linked worktree (git-dir ≠ git-common-dir).
- `MAIN_WT` — filesystem path of the worktree that has `TARGET` checked out (from
  `git worktree list`). Unset if `TARGET` is not checked out anywhere.
- `TARGET_DIRTY` — true when the worktree holding `TARGET` has uncommitted changes (staged,
  unstaged, or untracked — check with `git -C <MAIN_WT> status --short`).

## Commit gate

Skip if the tree is already clean (nothing staged, unstaged, or untracked).

- Run the `commit` skill (`Skill` tool, `skill: "commit"`) and follow it — it owns reading the
  diff, the split rules, staging (new and untracked files included, hunk-level splits within one
  file), the message format, the amend-vs-new decision, and the hook-failure rule. Do not restate
  or re-derive any of that here. Defer to a project-level `commit` skill/command if one exists.
- Repeat until `git status --short` is empty.

**Gate — the tree must be fully committed before anything moves.** Re-run `git status --short`
and confirm it prints nothing. If anything remains, do NOT proceed: either commit it as another
logical chunk or, if it is genuinely not meant to go, STOP and ask the user what to do with it.

After all chunks: show `git log --oneline <TARGET>..HEAD` so the user sees what is about to
move.

## Shared rules

- Never rebase, merge, push, or remove a worktree while the tree is dirty.
- Rebase/merge conflicts: resolve them when the combined result is clear — the global rules own
  this — then continue; STOP and ask when the intended result is ambiguous, and never guess or
  pick a side. Stop and ask on any unexpected worktree state.
- Never `rebase --skip` past a conflict.
- If anything is ambiguous, STOP and ask — never paper over a problem to keep the pipeline
  moving.
