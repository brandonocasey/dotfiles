## Watch while CI runs

When checks are pending, run one deterministic watcher for all selected pull
requests. Pin each observed head SHA:

```sh
agt watch --target OWNER/REPO#NUMBER@HEAD_SHA --deadline-seconds 3600
agt watch --target 'GROUP/PROJECT!IID@HEAD_SHA' --deadline-seconds 3600
```

Use the second form for GitLab; quote it because shells expand `!`. Repeat
`--target` for more pull requests. Monitor that one process per
[monitoring.md](../../sub-agents/references/monitoring.md) and capture its
complete output; do not poll the same pull requests separately.

The watcher is read-only and rejects a changed head SHA. It never pushes,
retries, comments, changes pull request state, or merges.
`required_checks_passed` describes check state only; apply the preflight in
[merge.md](merge.md) before any merge.

When the watcher reports `action_required`, inspect the reported state in the
main session and apply the SKILL.md **Diagnose and repair** section under the
invocation's authorization. Start a new watcher with the refreshed head SHA after a mutation.
