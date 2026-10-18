## Prepare

A new worktree has no ignored files: no dependencies, builds, or generated git
hooks. Install dependencies and build only when a step you will actually run
needs them: affected checks, commit hooks, or review evidence. A commit alone does
not require installation; check the repository's setup instructions and hooks
first. Preserve all required checks and hooks. Once setup is needed, start it in
the background and read code while it runs; dependent checks or commits wait for it.

- When the repo documents its own worktree setup (the repo's agent
  instructions and the files they link, CONTRIBUTING, README), run that. Otherwise
  run `agt worktree prepare [<path>]` (needs `agt` 0.10.0; [agt.md](../../shared/agt.md)). It runs
  `mise install` when the repo pins tools, then one frozen-lockfile install per
  lockfile in the worktree root (npm, pnpm, yarn, bun, uv, poetry, cargo, go).
  Each step reports its command, `exit`, and `log`; it exits 1 when a step fails.
- Never symlink dependency directories from another checkout. Workspace links
  then resolve into that checkout. agt never does.
- Only when a node install failed and its report has `clone_available: true` (the main
  checkout has `node_modules` with the same lockfile), run
  `agt worktree prepare <path> --clone-deps`. It clones `node_modules` only,
  copy-on-write from the main checkout. The other installs still run, as does the git-hook
  `prepare` step.
  Report that dependencies came from a clone (`deps_from: "clone"`).
- A setup step that changes a repo git setting needs consent under
  [git-policy.md](../../shared/git-policy.md).
- If a commit hook fails for missing files, finish Prepare and commit again;
  `commit` owns `--no-verify`. If Prepare fails, report the command and error
  as a blocker. Continue work that does not need the missing dependencies.
  Leave changes uncommitted when their hooks or checks need them.
- For a dev server in the worktree, `agt worktree port [<path>] --env` prints its
  stable port as `PORT=<n>`. [task-resources.md](../../host-preflight/references/task-resources.md)
  owns which servers use it.
