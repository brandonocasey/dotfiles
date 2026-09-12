---
name: auto-merge-watch
description: >
  Watch and unblock existing GitHub auto-merge pull requests until merged or
  blocked. Use for autonomous monitoring or repair requests, not new PR
  creation or general review.
---

# Auto-merge watch

Get every open pull request with auto-merge enabled to `merged`, or report its
exact blocker and next action. Process every pull request independently. One
blocked pull request must not stop work on the others.

The user has authorized unattended operation for this skill. Do not pause for
confirmation before an action inside the safe scope below. If the user narrows
the request to status or report-only work, follow that narrower instruction.

## Scope and safety

- Work on the current repository's GitHub remote. Run `git remote get-url
  origin` and use `gh`; if the remote is not GitHub, stop and report that this
  skill supports GitHub pull requests only.
- Read the repository's `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and CI
  documentation relevant to the failing check or changed paths. Apply the most
  specific rules that exist in the repository.
- A request to `watch`, `wait`, `fix`, or `unblock` authorizes read-only
  inspection, the smallest root-cause fix, required local checks, one normal
  push, one eligible CI retry, a normal branch update, and a manual merge when
  the final preflight is clean. Do not wait for the user between these actions.
- This standing authorization does not include review approval, branch-policy
  changes, force-pushes, or actions that change another person's ownership or
  intent. Report those blockers with the exact owner and next action.
- Never disable auto-merge, dismiss reviews, approve a pull request on the
  user's behalf, mark a draft ready, close a pull request, delete a remote
  branch, or bypass required checks. Do not push to a fork-owned branch unless
  the user explicitly authorizes work on that fork and credentials permit it.
- Do not edit tests, lint configuration, branch protection, or CI configuration
  only to make a check pass. Fix the cause, or report the check as blocked.

## Inventory

Run a fresh inventory at the start of every turn. Do not rely on a list from a
previous turn.

```sh
git remote get-url origin
gh repo view --json nameWithOwner,defaultBranchRef,url
gh pr list --state open --limit 100 --json number,title,url,headRefName,headRefOid,baseRefName,author,isDraft,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision,reviewRequests
```

Keep only entries whose `autoMergeRequest` is not `null`. If there are none,
report that no open auto-merge pull requests exist and stop.

If the list reaches its limit, increase the limit until the inventory is complete
before filtering or reporting that no eligible pull requests exist.

For each entry, record the pull request number, URL, source branch, source SHA,
base branch, draft state, auto-merge method, merge state, review decision, and
required-check state. Refresh this record after every mutation because a new
source SHA makes earlier check results stale.

## Diagnose each pull request

Use these read-only commands for each number `N`:

```sh
gh pr view N --json number,title,url,headRefName,headRefOid,baseRefName,author,isCrossRepository,headRepository,headRepositoryOwner,isDraft,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision,reviewRequests,reviews
gh pr view N --comments
gh pr checks N --required --json name,state,description,link,workflow,event
```

Classify the first real blocker, then check whether another blocker also needs
attention:

- Required checks are pending: wait. Do not change code or rerun a running
  check.
- A check failed: open the linked run and read the failure, not only its
  summary. Use `gh run view RUN_ID --log-failed` when a run ID is available.
  Treat a reproducible code failure as a fix. Treat a proven service or runner
  failure as an eligible one-time rerun. A second failure is a real failure.
- Review is required or changes were requested: report the missing reviewer or
  requested change. Do not approve, dismiss, or fabricate a review.
- The pull request is a draft: report that the author must mark it ready unless
  the user explicitly asks for that transition.
- The source branch conflicts with or lags the base branch: report the exact
  merge state. Use `gh pr update-branch N` for a normal merge update, or
  `gh pr update-branch N --rebase` only when repository rules require rebasing.
  Resolve any conflicts in a worktree; never force-push.
- The pull request is in a merge queue: report its queue state and wait. Do not
  remove it from the queue or change its merge method.
- Permissions, policy, missing secrets, or an unknown merge state block it:
  report the exact API or check message and the owner who must act.

Do not call a pull request ready only because its visible checks are green.
Required reviews, draft state, mergeability, queue state, and branch policy
also control the merge.

## Resolve authorized blockers

Unless the user requested report-only work, use this order for each eligible
pull request:

1. Capture the current head SHA and the failing check or review requirement.
2. If the source branch is in the current repository and the user can push to
   it, load the `worktree` skill and create a dedicated worktree for that
   branch. Never switch the main checkout. For a fork-owned pull request,
   stop unless the user explicitly authorizes work on that fork.
3. Read the relevant code and the full failing log. Make the smallest root-cause
   fix. Preserve input validation, error handling, security controls,
   accessibility behavior, and repository output-parity rules.
4. Run the repository's targeted checks, then any required formatting, lint,
   type, or test commands documented for the changed paths. Never skip or
   weaken a check.
5. Load the `commit` skill, commit only the intended files, and push the fix to
   the pull request's source branch with a normal push. Never force-push.
6. Re-run the inventory and report the new head SHA, checks started, and pull
   request URL. Remove the temporary worktree only after it is clean.

For an eligible infrastructure failure, first capture the run URL and failure
reason. Retry only the failed jobs with `gh run rerun RUN_ID --failed`, at most
once per run. Do not rerun a code failure or repeatedly rerun a flaky check.
After the retry, return to the inventory and classify the new result.

## Watch while CI runs

When checks are pending and the user asks to watch, load the `delegate` and
`sub-agents` skills and start one cheapest-tier, low-effort background watcher
for the repository. Give it the current pull request numbers, source SHAs, and
URLs. It must:

- use read-only `gh pr view` and `gh pr checks` snapshots;
- report only state changes, new failures, merges, closures, or permission
  errors;
- stop when every tracked pull request is merged or closed, or when it finds a
  new blocker that needs the main session;
- never push, rerun checks, post reviews or comments, change pull request state,
  or merge.

Do not poll the same pull request in the main session while the watcher runs.
If a watcher reports a new failure, inspect it in the main session and apply the
resolve section under the standing autonomy authorization. Start at most one
watcher per repository and include the observed head SHA so stale results are
rejected.

## Merge and report

Prefer the already-enabled auto-merge path. When the user explicitly asks for a
manual merge, or when auto-merge cannot complete but the user authorized
unattended operation, run a final read-only preflight. It must show that the
pull request is open, not a draft, mergeable, approved, and passing every
required check. Then use its configured merge method with
`--match-head-commit HEAD_SHA`. Never use `--admin`, `--delete-branch`, or a
different head SHA. Do not merge a pull request that still has a review,
required check, conflict, queue, policy, or permission blocker.

End with one line per pull request containing its number, URL, current state,
head SHA, blocker or completed action, and next step. State clearly when the
skill is waiting on CI, a reviewer, a fork owner, repository policy, or the
user. Include direct pull request and check-run URLs when available.
