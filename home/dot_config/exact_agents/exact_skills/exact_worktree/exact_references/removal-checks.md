# Removal checks

`agt worktree remove` (see [remove.md](remove.md)) runs these checks itself and
prints a refusal in its plan. Never bypass a refusal with
`git worktree remove --force`.

### Submodules

`--force` deletes every repository inside the worktree and every submodule clone
under `<git-common-dir>/worktrees/<name>/modules/`. agt removes the worktree only
when each of them holds nothing unique:

- every commit its local branches, tags, stash, other refs and HEAD reach is on a
  remote-tracking branch or in the main checkout's clone (a tag may also be one
  its remote advertises);
- it is at the commit the worktree records, clean, untracked files included, and
  holds no non-disposable ignored files;
- it has no linked worktrees and no unfinished rebase, merge or bisect.

This holds whatever `git submodule status` prints, deinitialized submodules
included. The worktree itself refuses for `refs/worktree/*` or `refs/bisect/*`
refs, an unfinished rebase, merge, cherry-pick, revert or bisect, a path with
both staged and unstaged changes, and files in a submodule directory that is not
initialized. Each refusal names the path and the reason.

### Blocked removal

Dirty tracked files, untracked files, and non-disposable ignored files do not
block removal: the backup keeps them. Only an agt refusal does. For each
refusal in the plan:

- Main checkout, a path that is not a linked worktree, or a locked worktree:
  never remove it; report it.
- The current directory is inside it: move your shell out and plan again.
- Another Claude Code session or another process runs in it (agt ignores the calling
  session and its processes): this is a real refusal. Retain it and report the session or process, or ask.
- A refusal from **Submodules**: report the path and agt's reason, and name what
  would clear it (push, commit, finish or abort the operation, move the files).

When a refusal does not clear, retain the worktree, report the path and agt's
reason, and ask. Do not commit, stash, or discard to clear it, and never pass
`--force` by hand.
