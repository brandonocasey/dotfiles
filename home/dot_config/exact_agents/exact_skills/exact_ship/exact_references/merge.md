# Ship through merge

`ship --merge` authorizes shipping, enabling auto-merge, and watching this
task's MRs/PRs until merged or blocked. It does not authorize approval,
marking drafts ready, policy changes, or deployment. It supports GitHub and
GitLab. For another platform, report that `--merge` is unsupported there
before any mutation. Ordinary `ship` still supports that platform.

## Inspect

After shipping, use the last `HEAD_SHA` from `ship` step 2, after any review fix push.
Inspect the MR/PR at that head: draft state, fork state, and auto-merge
configuration. Keep an existing merge method. Otherwise use the user's method
or the repository convention, checked against its enabled methods.
If several methods remain possible, ask for the method before enabling auto-merge.
Report a draft, fork, or unavailable auto-merge permission as a blocker.

## Enable auto-merge

When `ship` runs a review, enable auto-merge only after the review ends, any fix
push lands, and no blocking finding remains. CI could otherwise merge unreviewed
code. A method recorded by [auto-merge-pause.md](../../shared/auto-merge-pause.md)
counts as the existing method.

- GitHub: `gh pr merge <number> --auto --match-head-commit <HEAD_SHA>` with the
  selected `--merge`, `--squash`, or `--rebase` flag. It merges at once when
  all required checks already pass; report that.
- GitLab: `glab mr merge <iid> --auto-merge --sha <HEAD_SHA> --yes`, plus
  `--squash` or `--rebase` when selected. It merges at once when no pipeline
  is running. Read the state back with `glab mr view <iid> -F json` and
  report it.

Outside the repository's checkout, add `-R <owner/repo>` or `-R <group/project>`.
Never use `--admin`, `--delete-branch`, or `--remove-source-branch`.
A changed head requires a fresh inspection. Report a blocked command and its
reason in one line.

## Approve

Approve only when the user's words ask to approve that MR/PR. Never infer
approval from `--merge`.

- GitLab: `glab mr approve <iid> --sha <HEAD_SHA>`. Authors can approve their
  own MRs where the project allows it.
- GitHub: never approve your own PR. For another author's PR, run
  `gh pr review <number> --approve`.

## Watch

Load [pr-fix](../../pr-fix/SKILL.md). Limit its inventory to
the MRs/PRs shipped for this task. Follow its repair limits, watcher, and merge
gates on both platforms. Keep the worktree while a repair can still be needed.
For owned submodules, follow the existing submodule merge order first.

After the merge, move `TICKET` to the merged status per
[mr-ticket](../../mr-ticket/SKILL.md) step 6.

Return to `ship` cleanup after merge or a concrete blocker. Preserve unfinished
repairs and report their path. Report the merged head or blocker, rather than
treating enabled auto-merge as completed work.
