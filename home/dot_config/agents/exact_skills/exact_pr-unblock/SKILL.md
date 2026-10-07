---
disable-model-invocation: true
name: pr-unblock
description: "Repair and monitor existing GitHub PRs or GitLab MRs until green or merged; excludes creation and review."
---

Scope: Get open GitHub PRs or GitLab MRs green or merged: rebase, fix failing checks, and watch CI. Use to babysit or unblock them. Not for creation or review.


# Unblock pull requests

Get every selected open pull request to a passing state, or report its exact
blocker and next action. A pull request is passing when it is not a draft, is
up to date with its base, passes every required check, and has no unresolved
conflict. Process every pull request independently. One blocked pull request
must not stop work on the others. On GitLab, "pull request" means merge request
(MR); use the [GitLab path](references/gitlab.md) commands in place of `gh`.

The user has authorized unattended operation for this skill. Do not pause for
confirmation before an action inside the safe scope below. If the user narrows
the request to `report` or `status`, only inspect and report.

## Select the pull requests

Parse the invocation arguments. The default selection is the user's open pull
requests in the current repository. Each argument narrows or replaces that
default; filters combine with AND.

| Argument | Selection |
| --- | --- |
| none | `--author @me` |
| `auto-merge` | pull requests with `autoMergeRequest` set (GitLab: `merge_when_pipeline_succeeds`); author default still applies |
| `all` | drop the author default |
| `--author LOGIN`, `--assignee`, `--label`, `--base`, `--head`, `--search` | passed to `gh pr list` (GitLab: see [GitLab path](references/gitlab.md)); `--author` replaces the default |
| `12 #34 !56 https://github.com/O/R/pull/56 https://gitlab.com/G/P/-/merge_requests/7 feature/x` | exactly these pull requests by number, URL, or head branch |
| `--repo OWNER/REPO` | another repository; URLs set their own repository |
| `merge` | also merge pull requests that reach the passing state without auto-merge |
| `approve` | also approve each listed passing pull request as the user; needs explicit numbers or URLs, refuse it with `all` or filters |
| `report`, `status` | read-only |

Run a fresh inventory at the start of every turn. Do not rely on a list from a
previous turn.

```sh
git remote get-url origin
gh repo view --json nameWithOwner,defaultBranchRef,url
gh api user --jq .login
gh pr list --state open --limit 100 --author @me --json number,title,url,headRefName,headRefOid,baseRefName,author,isDraft,isCrossRepository,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision
```

Replace `--author @me` with the parsed filters. If the list reaches its limit,
raise the limit until the inventory is complete. On a GitLab remote, use the
[GitLab path](references/gitlab.md) commands. On any other remote, stop before any
mutation and name the unsupported platform. If the selection is empty, report
that and stop.

For each pull request record the number, URL, author, head branch, head SHA,
base branch, draft state, auto-merge method, merge state, review decision, and
required-check state. Refresh this record after every mutation because a new
head SHA makes earlier check results stale.

## Scope and safety

- Read the repository's `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and the CI
  documentation relevant to the failing check or changed paths. Apply the most
  specific rules that exist in the repository.
- The invocation authorizes read-only inspection, the smallest root-cause fix,
  the required local checks, a normal push, a rebase with a lease-protected
  force-push on the user's own branch, one eligible CI retry per run, a normal
  branch update on other authors' branches, and a manual merge under the rules
  in the merge section. Do not wait for the user between these actions.
- A branch is the user's own when the pull request author equals the login
  from `gh api user` and the head repository is the current repository. Only
  these branches may be rewritten. Never force-push another author's branch,
  and never force-push without `--force-with-lease=BRANCH:OBSERVED_SHA`.
- Approve only when the invocation includes `approve`. Report a policy error
  from the approve call as-is; do not retry or bypass it.
- Do not dismiss or request reviews, mark a draft ready, close a
  pull request, delete a remote branch, disable auto-merge, change branch
  protection, or bypass required checks. Do not push to a fork-owned branch.
  Report those blockers with the exact owner and next action.
- Do not edit tests, lint configuration, or CI configuration only to make a
  check pass. Fix the cause, or report the check as blocked.

## Diagnose each pull request

Use these read-only commands for each number `N`:

```sh
gh pr view N --json number,title,url,headRefName,headRefOid,baseRefName,author,isCrossRepository,headRepositoryOwner,isDraft,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision,reviewRequests,reviews
gh pr view N --comments
gh pr checks N --required --json name,state,description,link,workflow,event
```

Classify the first real blocker, then check whether another blocker also needs
attention. Handle branch state before check state: a rebase restarts CI, so a
fix pushed to a stale branch wastes a run.

- `mergeStateStatus` is `BEHIND`, or `mergeable` is `CONFLICTING`, or the
  repository requires a linear history and the branch contains merge commits:
  rebase or update per the next section.
- Required checks are pending: wait. Do not change code or rerun a running
  check.
- A check failed: open the linked run and read the failure, not only its
  summary. Use `gh run view RUN_ID --log-failed`. Treat a reproducible code
  failure as a fix. Treat a proven service or runner failure as an eligible
  one-time rerun. A second failure is a real failure.
- Review is required or changes were requested: report the missing reviewer or
  requested change. A review blocker does not stop check and branch work.
- The pull request is a draft: report that the author must mark it ready.
- The pull request is in a merge queue: report its queue state and wait.
- Permissions, policy, missing secrets, or an unknown merge state block it:
  report the exact API or check message and the owner who must act.

Do not call a pull request passing only because its visible checks are green.
Required checks, mergeability, draft state, and queue state control that.

## Rebase or update the branch

For a behind, conflicting, or nonlinear branch, read [branch-repair.md](references/branch-repair.md) before updating it. Finish stacked base PRs first.

## Fix failing checks

For a failed check, read [check-repair.md](references/check-repair.md) before fixes or retries.

## Watch while CI runs

For pending checks or queue state, read [watch.md](references/watch.md). Run one deterministic watcher pinned to the selected heads; never poll alongside it.

## GitLab path

On GitLab, read [gitlab.md](references/gitlab.md) before inventory or diagnosis; substitute its commands and field mappings throughout.

## Clean up task resources

Record which worktrees this invocation created; never remove a pre-existing
worktree. Before this invocation returns with completed, closed, or blocked
outcomes, stop task-created watchers and servers, free their ports, and close
task-created browser pages. Keep a repository watcher running while other
selected pull requests in that repository still need it.
Keep task-created worktrees while their PRs remain open, including review or
policy blockers. After merge or closure, or on explicit cleanup, move to a
surviving checkout and follow the `worktree` skill's **Remove** preservation checks.
A merge alone does not prove a changed local tip is preserved. Retain dirty,
unpushed, active, locked, or recovery worktrees and report their paths and exact
blockers. Do not delete a branch or recovery state merely to finish cleanup.
Rebase-only and code-fix paths both pass through this section before reporting.

## Merge and report

Before approval or manual merge, read [merge.md](references/merge.md). Preserve its authorization, preflight, and head-SHA checks.

End with one line per pull request: number, URL, author, state, head SHA,
blocker or completed action, and next step. State clearly when the skill is
waiting on CI, a reviewer, an author, repository policy, or the user. Include
direct pull request and check-run URLs when available. Report each removed
worktree and local branch, or its exact retention blocker.
