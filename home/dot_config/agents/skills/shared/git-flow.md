# Shared git flow — facts, commit gate, rules

Shared by the `land` and `ship` skills. This directory is not a skill.

## Facts

Establish these first; refresh any fact after an action that changes it:

```sh
git rev-parse --abbrev-ref HEAD                         # current branch
git rev-parse --path-format=absolute --git-dir --git-common-dir  # the two differ → linked worktree
git worktree list --porcelain                           # paths + which branch is where
git status --short --ignore-submodules=none             # dirty? (flag defeats diff.ignoreSubmodules)
git log --oneline -8
```

- `BRANCH` — current branch. `HEAD` here means a detached checkout (for example a review
  worktree): stop and ask which branch to use.
- `TARGET` — for `land`, resolve **Local target name** in
  [default-branch.md](default-branch.md); it never fetches. For `ship`, use
  the remote target from its setup step; no matching local branch is required.
- `COMMIT_BASE` — `TARGET` for `land`; the fetched target commit ID for `ship`.
  Use this revision for the commit report below.
- `IN_WORKTREE` — true if this checkout is a linked worktree (git-dir ≠ git-common-dir).
  Compare absolute paths: from a subdirectory of the main checkout, plain
  `--git-common-dir` prints a relative path that never equals `--git-dir`.
- `MAIN_WT` — filesystem path of the worktree that has `TARGET` checked out (from
  `git worktree list`). Unset if `TARGET` is not checked out anywhere.
- `TARGET_DIRTY` — true when the worktree holding `TARGET` has uncommitted changes (staged,
  unstaged, or untracked — check with
  `git -C <MAIN_WT> status --short --ignore-submodules=none`).

## Commit gate

Commit only authorized task work. Before invoking `commit`, identify unrelated
staged, unstaged, and untracked changes. Preserve them. If they block the gate,
ask how to handle them. Never commit, stash, or discard them to clear the gate.
Skip committing when the tree is clean.

- Load [commit](../commit/SKILL.md) through the harness's skill tool or read its
  file directly, and follow it for the diff, the split, staging, the message, amend or
  new, and hook failures. Defer to a project-level `commit` skill/command if one exists.
- Repeat for the authorized chunks, then check the gate below.

**Gate — the tree must be fully committed before anything moves.** Re-run
`git status --short --ignore-submodules=none`. If it prints anything, stop and
ask what to do.

After all chunks: show `git log --oneline <COMMIT_BASE>..HEAD` so the user sees what is about to
move.

## Shared rules

- Never rebase, merge, push, or remove a worktree while the tree is dirty.
- Resolve rebase and merge conflicts per the global rules (AGENTS.md, **Git**); never guess
  or pick a side. Never `rebase --skip` past a conflict.
- Stop and ask on any unexpected worktree state or other ambiguity; never hide a problem to
  keep the workflow moving.
