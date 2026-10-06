# CI failures and conflicts

Use this reference for remote review status and authorized repairs.
Apply the repository's instructions and the review target's existing push rules.
Load `code-standards` before changes, `worktree` before branch work, and `commit`
before commits. Load `sub-agents` before CI monitoring or delegation.

## Inspect the target

Record the MR/PR URL, source repository, source branch, source SHA, target branch,
CI results, and mergeability. Use `gh` for GitHub and `glab` for GitLab.
Keep self-hosted GitLab commands scoped to the parsed host.

Read the failed job's full log and the relevant workflow, code, and CI guidance.
Associate each result with the current source SHA or its tested merge commit.
Do not apply failures from an older source revision to the current one.
For GitHub, use `gh pr view`, `gh pr checks`, and `gh run view --log-failed`.
For GitLab, inspect the MR's head pipeline, jobs, and job traces through `glab`
or its API. Verify available commands with local help before using them.

Without `--fix` or own work under review's **Fix authorization**, inspect and
report only. Do not edit, update branches, push, or retry CI.

## Compare with the target branch

For each failed job, find the same job in the latest finished target-branch pipeline:

- GitHub: `gh run list --branch <target> --workflow <workflow> --limit 5`, then `gh run view <run-id>`.
- GitLab: `glab ci list --ref <target> --scope finished`, then
  `glab api "projects/<enc-path>/pipelines/<pipeline-id>/jobs"`.

Label each failure `also fails on <target>` or `new in this change`. Give both job URLs.
If the target branch has no run of that job, label the failure `new in this change`.
Retry or fix only `new in this change` failures. Report the others as target-branch failures.

## Repair CI

`--fix` includes the target's CI failures, even when no code-review finding survives.
Reproduce code failures locally when possible and fix their root cause.
Run affected checks and every repository-required check for the changed paths.
Do not skip or weaken tests, lint, type checks, or required CI checks.
Do not change check configuration merely to make a failure disappear.

A proven runner or service failure permits one retry of the failed jobs per run.
Record the failure evidence and run URL before retrying.
Do not retry deterministic code failures or jobs that are already running.
If the retry fails again, diagnose it or report the concrete external blocker.
Missing credentials, secrets, permissions, or service access require the named
owner to act; do not bypass them.

For local targets, fix reproducible local check failures.
Inspect remote CI only when an associated MR/PR or pipeline is part of the target.
Do not create an MR/PR or push a local review without authorization.

## Resolve conflicts

Fetch the MR/PR's actual target branch from its base repository.
Use that branch, not an assumed default branch, as the conflict base.
Check the source SHA again before mutation. If it moved, fetch the new source
and reassess the diff, findings, and failed checks before continuing.

Resolve conflicts in the review worktree while preserving both sides' intended behavior.
Prefer merging the current target branch into the source branch.
This preserves published history and permits a normal source-branch push.
Do not use blanket `ours` or `theirs` resolutions.
Regenerate generated files with their owning tool after resolving source changes.
Run the checks needed for the merged result, including affected manual cases
unless manual testing was skipped.

For an existing merge or rebase, resolve clear conflicts and continue that operation.
For local reviews, do not start a branch update without an explicit target or request.
If the intended result is ambiguous, name the conflicting paths and ask one diagnostic question.
If repository rules require a rebase that rewrites published commits, get
authorization before rebasing or force-pushing. Report the blocker if unavailable.

Before pushing, make sure the destination source branch still matches the
observed SHA. If it moved, reconcile its new commits and rerun affected checks.
Never force-push to overcome a non-fast-forward rejection.
Use the review skill's fork destination rules; do not change remotes or Git settings.
This authorization does not include merging the MR/PR, approving reviews, bypassing
branch policy, publishing releases, or writing to production.

## Finish

After each repair push or CI retry, refresh the source SHA and status once.
Earlier check results do not establish success for a new source revision.
Continue fixing completed failures when the cause is actionable and authorized.
Stop retrying the same external failure after its one eligible retry.
Report unresolved permissions, ambiguous conflicts, and other external blockers
with the exact evidence and next action.

Do not wait for pending CI unless the user asks to watch or wait.
For requested monitoring, follow `sub-agents`; a watcher observes status only.
The main session owns fixes and checks new failures against the tracked SHA.
Report repairs, remaining blockers, pending checks, source SHA, and MR/PR or job links.
Finish worktree cleanup through the review skill.
