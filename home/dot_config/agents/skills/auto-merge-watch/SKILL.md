---
name: auto-merge-watch
description: >
  Watch and unblock existing GitHub auto-merge pull requests until merged or
  blocked. Use for autonomous monitoring or repair requests, not new PR
  creation or general review.
---

# Auto-merge watch

Get each selected auto-merge pull request to merged, or report its blocker and
next action. The user authorizes read-only inspection, the smallest root-cause
fix, required local checks, one normal push, one eligible CI retry, a normal
branch update, and a manual merge after a clean preflight. Do not approve,
dismiss reviews, mark drafts ready, change branch policy, force-push, close pull
requests, delete branches, or push to forks.

Inventory open pull requests with `gh pr list`. Keep entries with a non-null
`autoMergeRequest`. Record the repository, number, URL, head SHA, author, fork
state, draft state, merge state, reviews, and required checks. Refresh this
record after each mutation. A new head SHA invalidates earlier check results.

Diagnose the first blocker. Update a stale branch normally. For a failed check,
read its complete log and distinguish a code failure from a proven service or
runner failure. Retry a failed infrastructure run once. For a code failure on
the user's non-fork branch, use the repository worktree, code, commit, and push
rules to make and test the smallest root-cause fix. Report review, draft,
policy, permission, conflict, fork, and ambiguous blockers to their owner.

## Watch pending checks

Run one deterministic watcher for all pending pull requests. Pin each observed
head SHA:

```sh
agent-watch --target OWNER/REPO#NUMBER@HEAD_SHA --deadline-seconds 3600
```

Repeat `--target` for more pull requests. Monitor that one process through the
harness completion or Monitor mechanism and capture its complete output. Do
not poll the same pull requests separately. Use a `cheap` background agent only
when the process must remain monitored across turns; the agent runs and reports
the process output without issuing its own GitHub polls.

The watcher makes read-only queries. It stops on check success, merge, close,
head change, failure, missing data, permission error, cancellation, or deadline.
`required_checks_passed` means only that required checks passed. It does not
mean that reviews, mergeability, draft state, or policy permit a merge.

When output reports `action_required`, inspect that state in the main session
and apply the authorized fix workflow. Start a new watcher with the refreshed
head SHA after any mutation. Never ask the watcher to push, retry, merge, or
change pull request state.

Let enabled auto-merge finish. Before any manual merge, check that the pull
request is open, not a draft, mergeable, approved, and passing every required
check at the recorded head SHA. Use its configured method and
`--match-head-commit HEAD_SHA`. Never use `--admin` or `--delete-branch`.

Report one line per pull request with its URL, author, head SHA, state, blocker
or completed action, and next step. Include check-run URLs when available.
