---
name: pr-unblock
description: >
  Get open GitHub pull requests passing and merged: watch checks, fix failing
  checks, rebase onto the base branch, retry infrastructure failures, and
  report each remaining blocker. Use whenever the user asks to watch, babysit,
  unblock, rebase, fix CI on, or get their pull requests green or merged, with
  or without auto-merge. Defaults to the user's own open pull requests; accepts
  auto-merge, a list, or any pull request filter. Not for creating pull
  requests or general code review.
---

# Unblock pull requests

Get every selected open pull request to a passing state, or report its exact
blocker and next action. A pull request is passing when it is not a draft, is
up to date with its base, passes every required check, and has no unresolved
conflict. Process every pull request independently. One blocked pull request
must not stop work on the others.

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
| `auto-merge` | pull requests with `autoMergeRequest` set; author default still applies |
| `all` | drop the author default |
| `--author LOGIN`, `--assignee`, `--label`, `--base`, `--head`, `--search` | passed to `gh pr list`; `--author` replaces the default |
| `12 #34 https://github.com/O/R/pull/56 feature/x` | exactly these pull requests by number, URL, or head branch |
| `--repo OWNER/REPO` | another repository; URLs set their own repository |
| `merge` | also merge pull requests that reach the passing state without auto-merge |
| `report`, `status` | read-only |

`auto-merge all` reproduces the old auto-merge-only watch across all authors.

Run a fresh inventory at the start of every turn. Do not rely on a list from a
previous turn.

```sh
git remote get-url origin
gh repo view --json nameWithOwner,defaultBranchRef,url
gh api user --jq .login
gh pr list --state open --limit 100 --author @me --json number,title,url,headRefName,headRefOid,baseRefName,author,isDraft,isCrossRepository,autoMergeRequest,mergeStateStatus,mergeable,reviewDecision
```

Replace `--author @me` with the parsed filters. If the list reaches its limit,
raise the limit until the inventory is complete. If the remote is not GitHub,
stop and report that this skill supports GitHub pull requests only. If the
selection is empty, report that and stop.

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
- Do not approve, dismiss, or request reviews, mark a draft ready, close a
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
  one-time rerun. A second failure is a real failure. Use `ci-investigate`
  only when the user invokes it.
- Review is required or changes were requested: report the missing reviewer or
  requested change. A review blocker does not stop check and branch work.
- The pull request is a draft: report that the author must mark it ready.
- The pull request is in a merge queue: report its queue state and wait.
- Permissions, policy, missing secrets, or an unknown merge state block it:
  report the exact API or check message and the owner who must act.

Do not call a pull request passing only because its visible checks are green.
Required checks, mergeability, draft state, and queue state control that.

## Rebase or update the branch

For a stacked pull request whose base is another open pull request's branch,
rebase onto that branch, not the default branch, and finish the base pull
request first.

For the user's own branch:

1. Load the `worktree` skill and create a dedicated worktree for the head
   branch. Never switch the main checkout.
2. Fetch the head branch and verify that its fetched SHA and the worktree
   HEAD equal the observed SHA. If either differs, preserve local work,
   refresh the inventory, and reconcile it before proceeding. Fetch the base
   explicitly with `git fetch origin refs/heads/BASE`, then immediately record
   `git rev-parse FETCH_HEAD` as `BASE_SHA`; a restricted fetch refspec may
   leave `origin/BASE` absent or stale.
3. Run `git rebase BASE_SHA`. Resolve conflicts when the combined result is
   clear; keep both sides' intent. Stop and report the conflicting files when
   the intended result is ambiguous.
4. Run the repository's targeted checks for the touched paths.
5. Push with `git push --force-with-lease=BRANCH:OBSERVED_SHA origin HEAD:BRANCH`.
   A rejected lease means someone else pushed; refresh and start over.
6. Refresh the inventory and record the new head SHA.

For another author's branch, use `gh pr update-branch N` only when the
repository permits a merge update. If linear history requires rebasing,
report that the author must rebase; do not rewrite another author's branch
through `--rebase`. If the update reports conflicts, report them to the author.

## Fix failing checks

Unless the invocation is read-only, use this order for each pull request with
a failing check on the user's own non-fork branch:

1. Capture the head SHA, the failing check, and the run URL.
2. Load the `worktree` skill and reuse or create the worktree for the head
   branch. Rebase first when the branch is behind, so the fix runs on the
   current base.
3. Read the relevant code and the full failing log. Make the smallest
   root-cause fix. Preserve input validation, error handling, security
   controls, accessibility behavior, and repository output-parity rules.
4. Run the repository's targeted checks, then any required formatting, lint,
   type, or test commands documented for the changed paths. Never skip or
   weaken a check.
5. Load the `commit` skill, commit only the intended files, and push with a
   normal push. Use the lease-protected force-push only when a rebase happened
   in this pass.
6. Refresh the inventory and record the new head SHA and the started checks.
   Keep the worktree while local work is needed; use the cleanup section on
   every completed or blocked outcome.

For an eligible infrastructure failure, capture the run URL and failure reason,
then run `gh run rerun RUN_ID --failed` at most once per run. Do not rerun a
code failure or repeatedly rerun a flaky check. After the retry, refresh the
inventory and classify the new result.

For a fork-owned or another author's branch with a code failure, report the
failure, the cause, and the fix the author needs.

## Watch while CI runs

When checks are pending, load the `sub-agents` skill and start one `cheap`
background watcher per repository. Give it the pull request numbers, head SHAs,
and URLs. It must:

- use read-only `gh pr view` and `gh pr checks` snapshots;
- report only state changes, new failures, merges, closures, or permission
  errors, and reject results for a head SHA it was not given;
- stop when every tracked pull request is passing or merged or closed, or when
  it finds a new blocker that needs the main session;
- never push, rerun checks, post reviews or comments, change pull request
  state, or merge.

Do not poll the same pull request in the main session while the watcher runs.
When the watcher reports a new failure or a branch that fell behind, apply the
rebase and fix sections under the standing authorization.

## Clean up task resources

Record which worktrees this invocation created; never remove a pre-existing
worktree. Before this invocation returns with completed, closed, or blocked
outcomes, stop task-created watchers and servers, free their ports, and close
task-created browser pages. Keep a repository watcher running while other
selected pull requests in that repository still need it.
For each task-created worktree, move to a surviving checkout first. If its
work is fully committed and pushed, use the `worktree` skill's **Remove after
push** checks and cleanup even when a review or policy blocker remains.
A merge alone does not prove a changed local tip is preserved. Retain dirty,
unpushed, active, locked, or recovery worktrees and report their paths and exact
blockers. Do not delete a branch or recovery state merely to finish cleanup.
Rebase-only and code-fix paths both pass through this section before reporting.

## Merge and report

Let an enabled auto-merge complete. Merge manually only when the pull request
has auto-merge enabled but auto-merge cannot complete, or when the invocation
includes `merge`. Before a manual merge, run a final read-only preflight: open,
not a draft, mergeable, approved, and passing every required check. Then use
the configured merge method or the repository default with
`gh pr merge N --match-head-commit HEAD_SHA`. Never use `--admin` or
`--delete-branch`. Do not merge a pull request that still has a review,
required check, conflict, queue, policy, or permission blocker. Without
`merge` or auto-merge, a passing pull request is complete; report it as ready.

End with one line per pull request: number, URL, author, state, head SHA,
blocker or completed action, and next step. State clearly when the skill is
waiting on CI, a reviewer, an author, repository policy, or the user. Include
direct pull request and check-run URLs when available. Report each removed
worktree and local branch, or its exact retention blocker.
