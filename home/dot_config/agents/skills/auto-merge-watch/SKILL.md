---
name: auto-merge-watch
description: "Watch and repair existing auto-merge PRs/MRs until merged or blocked; excludes creation and general review."
---

Scope: Watch and unblock existing GitHub auto-merge PRs or GitLab auto-merge MRs until merged or blocked. Use for autonomous monitoring or repair requests, not new PR creation or general review.


# Auto-merge watch

Get each selected auto-merge pull request to merged, or report its blocker and
next action. The user authorizes read-only inspection, the smallest root-cause
fix, required local checks, one normal push, one eligible CI retry, a normal
branch update, and a manual merge after a clean preflight. Do not approve,
dismiss reviews, mark drafts ready, change branch policy, force-push, close pull
requests, delete branches, or push to forks. On GitLab, "pull request" means
merge request (MR). On any other platform, stop before any mutation and name
the unsupported platform.

Inventory open pull requests by any author, unless the caller limits the
scope. On GitHub, use `gh pr list` and keep entries with a non-null
`autoMergeRequest`. On GitLab, use `glab mr list -F json -P 100 -p 1` and fetch
the next pages until one has fewer than 100 rows. Keep entries with
`merge_when_pipeline_succeeds` true, and read each with `glab mr view N -F json`. Prefix `GITLAB_HOST=HOST` for a self-hosted GitLab.
Map its fields with the
[pr-unblock GitLab path](../pr-unblock/SKILL.md#gitlab-path). Record the
repository, number, URL, head SHA, author, fork state, draft state, merge
state, reviews, and required checks. Refresh this
record after each mutation. A new head SHA invalidates earlier check results.

Diagnose the first blocker. Update a stale branch normally. For a failed check,
read its complete log and distinguish a code failure from a proven service or
runner failure. Retry a failed infrastructure run once: `gh run rerun RUN_ID
--failed` or `glab ci retry JOB_ID`. For a code failure on
the user's non-fork branch, use the `worktree`, `code-standards`, and `commit`
skills and the push rules to make and test the smallest root-cause fix. Report review, draft,
policy, permission, conflict, fork, and ambiguous blockers to their owner.

## Watch pending checks

Run one deterministic watcher for all pending pull requests. Pin each observed
head SHA:

```sh
agent-watch --target OWNER/REPO#NUMBER@HEAD_SHA --deadline-seconds 3600
agent-watch --target 'GROUP/PROJECT!IID@HEAD_SHA' --deadline-seconds 3600
```

Use the second form for GitLab; quote it because shells expand `!`. Repeat
`--target` for more pull requests. Monitor that one process through the
harness completion or Monitor mechanism and capture its complete output. Do
not poll the same pull requests separately. Use a `cheap` background agent only
when the process must remain monitored across turns; the agent runs and reports
the process output without issuing its own GitHub or GitLab polls.

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
`--match-head-commit HEAD_SHA`. Never use `--admin` or `--delete-branch`. On
GitLab, use the GitLab command in ship's
[merge reference](../ship/references/merge.md#enable-auto-merge) with
`--sha HEAD_SHA`. Never pass `--auto-merge=false`.

Report one line per pull request with its URL, author, head SHA, state, blocker
or completed action, and next step. Include check-run URLs when available.
