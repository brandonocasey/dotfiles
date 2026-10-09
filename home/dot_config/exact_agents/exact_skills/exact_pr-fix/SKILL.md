---
name: pr-fix
description: "Fix CI on existing GitHub PRs or GitLab MRs until green, then approve or merge only with --approve or --merge; excludes creation and review."
---

Scope: Get existing GitHub PRs or GitLab MRs green: update or rebase the branch, fix failing checks, and watch CI. Then approve or merge only when asked. Not new PRs or review. `mr-fix` is an alias.


# Fix pull requests

Get every selected pull request to a passing state, then approve or merge it
only when asked. Otherwise report its exact blocker and next action. A pull
request is passing when it is not a draft, is up to date with its base, passes
every required check, and has no unresolved conflict. Process every pull
request independently; one blocked pull request must not stop the others. On
GitLab, "pull request" means merge request (MR); read
[gitlab.md](references/gitlab.md) before inventory or diagnosis and substitute
its commands throughout. On any other platform, stop before any mutation and
name the unsupported platform.

## Select the pull requests

The user may name pull requests in arguments or in plain words: numbers, URLs,
head branches, or a description such as "my PRs with auto-merge" or "the ones
I shipped today". Resolve a description against the inventory and state the
resolved list before the first mutation. Ask only when it matches nothing or is
ambiguous. Without a selection, take the user's open pull requests in the
current repository. Filters combine with AND.

| Argument | Selection or action |
| --- | --- |
| none | `--author @me` |
| `12 #34 !56 https://github.com/O/R/pull/56 https://gitlab.com/G/P/-/merge_requests/7 feature/x` | exactly these pull requests by number, URL, or head branch |
| `auto-merge` | pull requests with `autoMergeRequest` set (GitLab: `merge_when_pipeline_succeeds`); author default still applies |
| `all` | drop the author default |
| `--author LOGIN`, `--assignee`, `--label`, `--base`, `--head`, `--search` | passed to `gh pr list`; `--author` replaces the default |
| `--repo OWNER/REPO` | another repository; URLs set their own repository |
| `--merge` | merge each selected pull request once it is passing |
| `--approve` | approve each selected pull request when approval is its last blocker; needs pull requests named by number, URL, or branch, so refuse it with `all`, filters, or a description |
| `report`, `status` | read-only: inspect and report |

The words "merge" or "approve" in the user's own text for those pull requests
count as the flags. Never infer either. The `auto-merge` selector does not
count as `--merge`.

## Authorization

The invocation authorizes unattended work; do not pause between these actions:
read-only inspection, the smallest root-cause fix, the required local checks, a
normal push, a rebase with a lease-protected force-push on the user's own
branch, one eligible CI retry per run, a normal branch update on another
author's branch, and CI watching. When another skill such as `ship` loads this
one, skip the rebase and force-push: use a normal branch update, or report the
needed rebase. `--approve`, `--merge`, and enabled auto-merge add only what
[merge.md](references/merge.md) allows.

- Read the repository's `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and the CI
  documentation relevant to the failing check or changed paths. Apply the most
  specific rules.
- A branch is the user's own when the pull request author equals the login
  from `gh api user` and the head repository is the current repository. Only
  these branches may be rewritten. Never force-push without
  `--force-with-lease=BRANCH:OBSERVED_SHA`.
- Do not dismiss or request reviews, mark a draft ready, close a pull request,
  delete a remote branch, disable auto-merge (except the push pause in
  [auto-merge-pause.md](../shared/auto-merge-pause.md)), change branch protection, bypass
  required checks, or push to a fork-owned branch. Report those blockers with
  the exact owner and next action.
- Do not edit tests, lint configuration, or CI configuration only to make a
  check pass. Fix the cause, or report the check as blocked.

## Inventory

Run a fresh inventory at the start of every turn; do not rely on a list from a
previous turn.

```sh
git remote get-url origin
gh repo view --json nameWithOwner,defaultBranchRef,url
gh api user --jq .login
gh pr list --state open --limit 100 --author @me --json number,title,url,headRefName,headRefOid,baseRefName,author,isDraft,isCrossRepository,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision
```

Replace `--author @me` with the parsed selection. If the list reaches its
limit, raise the limit until the inventory is complete. If the selection is
empty, report that and stop.

For each pull request record the number, URL, author, head branch, head SHA,
base branch, draft state, fork state, auto-merge method, merge state, review
decision, and required-check state. Refresh this record after every mutation:
a new head SHA makes earlier check results stale.

## Diagnose and repair

Use these read-only commands for each number `N`:

```sh
gh pr view N --json number,title,url,headRefName,headRefOid,baseRefName,author,isCrossRepository,headRepositoryOwner,isDraft,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision,reviewRequests,reviews
gh pr view N --comments
gh pr checks N --required --json name,state,description,link,workflow,event
```

Classify the first real blocker, then check whether another needs attention.
Handle branch state before check state: a rebase restarts CI, so a fix pushed
to a stale branch wastes a run.

- `mergeStateStatus` is `BEHIND`, `mergeable` is `CONFLICTING`, or the
  repository requires linear history and the branch has merge commits: read
  [branch-repair.md](references/branch-repair.md). Finish stacked base pull
  requests first.
- Required checks are pending, or the pull request is in a merge queue: read
  [watch.md](references/watch.md). Do not change code or rerun a running check.
- A check failed: open the linked run and read the failure, not only its
  summary: `gh run view RUN_ID --log-failed`. Treat a reproducible code
  failure as a fix and a proven service or runner failure as an eligible
  one-time rerun. Read [check-repair.md](references/check-repair.md). A second
  failure is a real failure.
- Review is required or changes were requested: report the missing reviewer or
  requested change. A review blocker does not stop branch and check work.
- The pull request is a draft: report that the author must mark it ready.
- Permissions, policy, missing secrets, or an unknown merge state block it:
  report the exact API or check message and the owner who must act.

Do not call a pull request passing only because its visible checks are green.
Required checks, mergeability, draft state, and queue state control that.

## Approve and merge

Before starting a fix that will be pushed, pause auto-merge; restore it after the push, per
[auto-merge-pause.md](../shared/auto-merge-pause.md). Otherwise let an enabled
auto-merge finish. Before any approval or manual merge, read
[merge.md](references/merge.md). Preserve its preflight and head-SHA checks.
Never use `--admin` or `--delete-branch`. Without `--merge` or auto-merge, a
passing pull request is complete; report it as ready.

## Clean up task resources

Record which worktrees this invocation created; never remove a pre-existing
worktree. On every exit path (completed, closed, or blocked), stop
task-created watchers and servers, free their ports, and close task-created
browser pages. Keep a repository watcher running while other selected pull
requests in that repository still need it.
Keep task-created worktrees while their pull requests remain open, including
review or policy blockers. After merge or closure, or on explicit cleanup, move
to a surviving checkout and follow the `worktree` skill's **Remove**
preservation checks. A merge alone does not prove a changed local tip is
preserved. Retain dirty, unpushed, active, locked, or recovery worktrees and
report their paths and exact blockers. Do not delete a branch or recovery state
merely to finish cleanup.

## Report

End with one line per pull request: URL, author, head SHA, state, blocker or
completed action, and next step. State whether it waits on CI, a reviewer, an
author, repository policy, or the user. Include check-run URLs when available.
Report each removed worktree and local branch, or its exact retention blocker.
