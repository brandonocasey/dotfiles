## Create

This needs `agt` 0.10.0 or newer. Follow [agt.md](../../shared/agt.md).

For a separate task that depends on an unmerged MR/PR, first read
[dependent-branches.md](../../shared/dependent-branches.md). Use its parent base
(`--base <parent-commit>`) and record the child target and task boundary.
For a branch that exists only on origin, pass no `--base`; agt checks it out as a local
tracking branch. For an independent new branch, pass no `--base`: agt starts it at the newest
default base (remote defaults and the local default branch, compared by ancestry). When the JSON
reports `base.diverged` (candidates that disagree), report the candidates to the user.

```sh
agt worktree create <branch> [--base <commit-ish>] [--prepare] [--port]
```

It prints JSON with the worktree `path`. Work in that path for the whole task. Check the JSON:
a remote branch shows `tracking: origin/<branch>`. A `base` field means agt made a new branch;
when a remote branch was expected, remove what agt made (`agt worktree remove <path> --yes`,
then delete the branch) and report. `branch -d` fails when local main is behind the base. Check
that the branch tip still equals the commit agt reported as `base`, then run
`git -C <main-checkout> branch -D <branch>`; if the tip moved, keep the branch and report it. For `reused: true` on an expected
remote branch, check that `git -C <path> rev-parse --abbrev-ref @{u}` prints `origin/<branch>`.

- It creates `<main-checkout>/.worktrees/<branch>`, even when the session starts
  in a subdirectory or in another worktree. A worktree nested in another is
  deleted with it, because ignored files never block removal. Do not pass
  `--path` to change this, except when the main checkout is bare (`bare` in
  `git worktree list --porcelain`): then ask where to create the worktree.
- For an existing branch it reuses the worktree that has it checked out
  (`reused: true`). A branch that exists only on origin gets a local branch tracking `origin/<branch>`.
  Otherwise it adds a worktree without moving the branch.
- `.worktrees/` is ignored through the global excludes file
  (`~/.config/git/ignore`), so it needs no per-repo `.gitignore` entry.
- When `.gitmodules` exists it runs `git submodule update --init --recursive`.
  This leaves submodules on detached HEADs. Before a submodule commit, create
  a branch there: `git -C <sub-path> switch -c <branch>`. This gives the commit
  a pushable ref and prevents the next update from orphaning it.
- `--prepare` runs `agt worktree prepare`; `--port` runs `agt worktree port`.
  Add them only when [prepare.md](prepare.md) says setup is needed.

In zsh, `$B:refs/...` applies the `:r` modifier and mangles the refspec. Write
`${B}` and quote refspecs, for example
`git fetch origin "+refs/heads/${B}:refs/remotes/origin/${B}"`.

Repository `worktree add` examples do not override this location or base.
Follow a repository location only when it is stated as a requirement.
