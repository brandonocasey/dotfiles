# Ship through merge on GitHub

`ship --merge` authorizes shipping, enabling auto-merge, and running
`auto-merge-watch` for this task's pull requests until merged or blocked.
It does not authorize approval, marking drafts ready, policy changes, or deployment.
For another hosting platform, report that this option needs a supported watcher
before starting mutations. Ordinary `ship` still supports those platforms.

After shipping, inspect the pull request's current head, draft state, fork state,
and auto-merge configuration. Keep an existing merge method. Otherwise use the
user's method or repository convention, checked against its enabled methods.
If several methods remain possible, ask for the method before enabling auto-merge.
Report a draft, fork, or unavailable auto-merge permission as a blocker.

Enable auto-merge with `gh pr merge <number> --auto --match-head-commit <sha>`
and the selected `--merge`, `--squash`, or `--rebase` flag. Never use `--admin`
or `--delete-branch`. A changed head requires a fresh inspection.

Load [auto-merge-watch](../../auto-merge-watch/SKILL.md). Limit its inventory to
the pull requests shipped for this task. Follow its repair limits, watcher,
and merge gates. Keep the worktree while a repair can still be needed.
For owned submodules, follow the existing submodule merge order first.

Return to `ship` cleanup after merge or a concrete blocker. Preserve unfinished
repairs and report their path. Report the merged head or blocker, rather than
treating enabled auto-merge as completed work.
