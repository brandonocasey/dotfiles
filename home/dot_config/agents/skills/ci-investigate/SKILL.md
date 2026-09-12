---
name: ci-investigate
description: >
  Diagnose GitHub Actions failures, queue delays, and cache or job bottlenecks.
  Use only when the user invokes ci-investigate.
disable-model-invocation: true
---

# Investigate CI

Start only on the user's explicit invocation. A reference from another skill
does not authorize starting this workflow. Diagnose the requested PRs or runs;
apply fixes when the user's task includes them.

## Establish the target

Read the repository's CI guide and the workflows for the affected checks.
Resolve the repository with `git remote get-url origin`. Record each PR's current head
SHA, run ID, run attempt, workflow, and event. A rerun or a new commit can make
earlier observations stale.

Use `gh pr checks <PR>` to find checks and `gh run view <RUN_ID>` to inspect a
run. For external check providers, report the provider and details URL; use
their tools only when that investigation is in scope.

## Find the cause

For failures, use `gh run view <RUN_ID> --log-failed`. If the run is still
active and its aggregate log is unavailable, fetch the completed job's log with
`gh api repos/<OWNER>/<REPO>/actions/jobs/<JOB_ID>/logs`. Keep the first causal
error and the setup context that explains it. Avoid dumping whole logs or
credentials into the conversation.

Compare failures across the requested PRs by error, job, and workflow revision.
Separate a shared failure from independent code failures before editing several
branches. Check whether a failure reproduces locally with that job's inputs and
toolchain. A passing retry alone does not establish an infrastructure failure.

For slowness, collect run and job timestamps with `gh api --paginate` against
the repository's Actions runs and jobs endpoints. Compare equivalent events,
changed paths, runner types, and cache conditions. Separate time before a job
starts from its execution time. Do not call all pre-start time runner queue
delay: dependencies, environment approvals, and concurrency rules also delay it.

Trace workflow `needs`, matrix expansion, concurrency groups, and path filters.
Find the dependency chain that controls completion; adding every job duration
does not measure elapsed CI time. Check cache restore/save logs and the Actions
caches endpoint for misses, incompatible keys, eviction, and upload costs. A
cache hit is useful only when the work it saves exceeds transfer overhead.

## Resolve and report

Rank changes by measured impact and the affected checks. Preserve the check
coverage when changing job grouping, filters, caching, or concurrency. Compare
equivalent runs after an authorized fix and distinguish measurements from
estimates. If the evidence is incomplete, name the missing log or timestamp.

Use the installed `worktree` and `commit` skills for code changes. Use `review`
under the existing review rules, and `ship` only when the user authorized a
push and PR/MR workflow. For explicitly requested monitoring of auto-merge PRs,
continue through `auto-merge-watch`. Diagnosis alone does not start a watcher.

Report the cause, supporting run/job URLs and head SHAs, the fix or next action,
and the observed effect. Reuse those observations in the calling workflow.
