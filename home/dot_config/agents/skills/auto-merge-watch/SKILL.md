---
name: auto-merge-watch
description: "Watch and repair existing PRs/MRs until merged, green, or blocked; excludes creation and general review."
---

Scope: Watch and unblock existing GitHub PRs or GitLab MRs until merged or blocked. Default: auto-merge PRs/MRs. Broader mode, only when the user asks to rebase or to handle all their open PRs/MRs: rebase, fix checks, watch CI. Not new PRs or review.

# Auto-merge watch

Get each selected pull request to merged, or report its blocker and next
action. On GitLab, "pull request" means merge request (MR). On any other
platform, stop before any mutation and name the unsupported platform.

## Modes

- Default mode: auto-merge pull requests of any author, unless the caller
  limits the scope.
- Broader mode: the user's own message asks to rebase named pull requests,
  or to get all their open PRs/MRs green or merged, including ones without
  auto-merge. Asking to fix or watch a pull request stays in default mode.
  Read [broader-mode.md](references/broader-mode.md) first.
- A status or report request is read-only in either mode: inspect and report,
  with no mutation.

Default mode authorizes read-only inspection, the smallest root-cause fix,
required local checks, one normal push, one eligible CI retry, a normal branch
update, and a manual merge after a clean preflight. In default mode, do not
approve, dismiss or request reviews, mark drafts ready, change branch policy,
disable auto-merge, bypass required checks, rebase, force-push, close pull
requests, delete branches, or push to forks.

Broader mode keeps those limits except where broader-mode.md adds
authorization: a lease-protected force-push after a rebase on the user's own
branch, and `approve` or `merge` only when the user's own text contains that
word for that pull request. Never infer `approve` or `merge`.

## Inventory

On GitHub, use `gh pr list` and keep entries with a non-null
`autoMergeRequest`. On GitLab, read [gitlab.md](references/gitlab.md): list
with `glab mr list -F json -P 100 -p 1`, fetch pages until one has fewer than
100 rows, keep `merge_when_pipeline_succeeds` true, and read each MR with
`glab mr view N -F json`.

Record the repository, number, URL, head SHA, author, fork state, draft state,
merge state, reviews, and required checks. Refresh this record after each
mutation. A new head SHA invalidates earlier check results. Run a fresh
inventory at the start of every turn.

## Diagnose and repair

Diagnose the first blocker. Handle branch state before check state.

- Stale branch: in default mode, run `gh pr update-branch N` when the
  repository permits a merge update; otherwise report the needed rebase. In
  broader mode, read [branch-repair.md](references/branch-repair.md).
- Failed check: read its complete log and distinguish a code failure from a
  proven service or runner failure. Retry a failed infrastructure run once:
  `gh run rerun RUN_ID --failed` or `glab ci retry JOB_ID`. For a code failure
  on the user's non-fork branch, read
  [check-repair.md](references/check-repair.md); it uses the `worktree`,
  `code-standards`, and `commit` skills. In default mode, skip its rebase
  and push normally.
- Pending checks or queue state: read [watch.md](references/watch.md). Run one
  watcher; never poll alongside it.
- Review, draft, policy, permission, conflict, fork, and ambiguous blockers:
  report to their owner.

Do not edit tests, lint configuration, or CI configuration only to make a
check pass.

## Merge

Let enabled auto-merge finish. Before any manual merge, or any approval in
broader mode, read [merge.md](references/merge.md). Preserve its preflight and
head-SHA checks. Never use `--admin` or `--delete-branch`.

## Clean up task resources

Record which worktrees this invocation created; never remove a pre-existing
worktree. On every exit path (completed, closed, or blocked), stop
task-created watchers and servers, free their ports, and close task-created
browser pages. Keep a repository watcher running while other selected pull
requests in that repository still need it.
Keep task-created worktrees while their PRs remain open, including review or
policy blockers. After merge or closure, or on explicit cleanup, move to a
surviving checkout and follow the `worktree` skill's **Remove** preservation
checks. A merge alone does not prove a changed local tip is preserved. Retain
dirty, unpushed, active, locked, or recovery worktrees and report their paths
and exact blockers. Do not delete a branch or recovery state merely to finish
cleanup. Rebase-only and code-fix paths both pass through this section.

## Report

Report one line per pull request with its URL, author, head SHA, state, blocker
or completed action, and next step. Include check-run URLs when available.
