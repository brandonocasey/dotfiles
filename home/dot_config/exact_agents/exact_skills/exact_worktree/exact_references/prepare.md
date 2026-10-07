## Prepare

A new worktree has no ignored files: no dependencies, builds, or generated git
hooks. Install dependencies and build only when required by the affected checks,
commit hooks, or review evidence. A commit alone does not require installation;
check the repository's setup instructions and hooks first. Preserve all required
checks and hooks. Start required setup in the background and read code while it
runs; dependent checks or commits wait for it.

- When setup is required, run the worktree setup that the repo documents (the repo's agent
  instructions and the files they link, CONTRIBUTING, README). Without one, run the install of
  the lockfile's tool (npm, pnpm, yarn, bun, uv, poetry, cargo, or go) in the
  worktree root, with its frozen-lockfile option when it has one.
- Never symlink dependency directories from another checkout. Workspace links
  then resolve into that checkout.
- Only when the install fails for lack of network, clone dependencies
  copy-on-write from the source checkout:
  `cp -cR` on macOS, `cp --reflink=auto -R` on Linux. Do this only when both
  lockfiles are identical (`cmp`). Clone every dependency directory, nested
  ones included. Then run the lifecycle step that installs git hooks, for npm
  `npm run prepare --if-present`. Report that dependencies came from a clone.
- A setup step that changes a repo git setting needs consent under
  [git-policy.md](../../shared/git-policy.md).
- If a commit hook fails for missing files, finish Prepare and commit again;
  `commit` owns `--no-verify`. If Prepare fails, report the command and error
  as a blocker. Continue work that does not need the missing dependencies.
  Leave changes uncommitted when their hooks or checks need them.
