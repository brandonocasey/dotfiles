## Remove

Keep worktrees and branches for open MRs/PRs unless the user requests cleanup.
Exception: remove a review worktree this review created when the review ends,
even for an open MR/PR, unless the review installed dependencies in it. Its
HEAD counts as preserved when `git -C <wt> rev-parse HEAD` equals the source SHA
the review recorded at creation (no local commits). Otherwise fetch inside the
worktree, because FETCH_HEAD is per worktree and `HEAD` under `-C <main-checkout>`
is the wrong commit: `git -C <wt> fetch origin <source-branch-or-head-ref>`, then
`git -C <wt> merge-base --is-ancestor HEAD FETCH_HEAD` must exit 0. For a review
worktree, this proof replaces the HEAD proof below; the state checks still apply.
Stop task-owned servers and background processes when finished; worktree retention
is separate from process cleanup. Remove a task worktree after merge or closure,
or on explicit cleanup, only after the preservation checks below. A temporary
local-review worktree may be removed when the review ends and its commits remain
on a named branch. Never remove the main checkout, a locked worktree, or one
another task uses. Report retained paths and reasons or the removed path.

Before removal, check tracked, untracked, ignored, and submodule state. Preserve
unknown files and requested deliverables; use **Blocked removal** (`removal-checks.md`) for classification
and backups even when ignored files would not stop Git. Dirty work is a blocker.
Prove the worktree's HEAD is preserved on a named local branch that will remain,
a current remote source branch, or a fetched merge target containing that commit.
For a detached worktree without that proof, keep it and report the commit ID.
A squash merge does not prove the original commits are preserved.

For a remote MR/PR, fetch and refresh its state before using merged/closed status.
Remove a local branch only through **Remove after push** below, `land`'s merged
branch checks, or the `-D` exceptions documented in `review` step 7 and
`clean-merged-worktrees`. If a deleted remote branch prevents that proof, retain the local
branch; a clean worktree can still be removed when that retained branch preserves
its HEAD. Outside those exceptions, never force-delete a branch to finish cleanup.

Follow [task-resources.md](../../host-preflight/references/task-resources.md) for
task scratch locations and cleanup, including `.cache/agents/scratch/<task>/`. Clean disposable
resources even when retaining an open-PR worktree. Stop task-owned processes
before removing their files; retain a worktree while a requested live preview
needs it.

Run cleanup separately from approve, merge, ticket, or other outward steps, so a
blocked outward step cannot prevent cleanup of task-owned processes and scratch.

Take `<worktree-path>` from `git worktree list --porcelain`, because older
worktrees can live elsewhere:

```sh
git -C <main-checkout> worktree remove <worktree-path>
```

Move your shell out before removal. A shell in the deleted directory makes
later commands fail with "Unable to read current working directory".

### Remove after push

Use only after **Remove** permits cleanup: the MR/PR is merged or closed, or
the user explicitly requested it. A push alone is not a cleanup trigger.
When the remote source branch still exists, prove it holds the local tip:

```sh
git ls-remote origin refs/heads/<branch>   # remote tip
git rev-parse <branch>                     # local tip; must be the same ID
```

Pass the full ref: a bare `<branch>` pattern also matches
`refs/heads/<prefix>/<branch>` and can print a second ID.
If the IDs differ, `ls-remote` prints nothing, or the command fails, keep the
worktree and the branch and report both IDs. Otherwise, with your shell in
`<main-checkout>`:

```sh
git -C <main-checkout> worktree remove <worktree-path>
git -C <main-checkout> branch -d <branch>
git -C <main-checkout> worktree prune
```

`branch -d` checks the branch against its upstream and refuses a tip the
upstream lacks. Never answer that refusal with `-D`; report it. The upstream
must be set (`git push -u` sets it). Without one, `-d` checks against HEAD and
refuses a pushed branch: run `git branch -u origin/<branch> <branch>` and retry
`-d` once. Report the removed path and the branch's last commit ID; the remote
branch keeps the history.
