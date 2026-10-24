## Watch while CI runs

This needs `agt` 0.10.0 or newer ([agt.md](../../shared/agt.md)).

When checks are pending, run one deterministic watcher for all selected pull
requests. Pin each observed head SHA:

```sh
agt ci wait OWNER/REPO#NUMBER@HEAD_SHA --timeout 3600
agt ci wait 'GROUP/PROJECT!IID@HEAD_SHA' --timeout 3600
```

Use the second form for GitLab; quote it because shells expand `!`. Pass more
targets for more pull requests. Monitor that one process per
[monitoring.md](../../sub-agents/references/monitoring.md) and capture its
complete output; do not poll the same pull requests separately.

The watcher is read-only and rejects a changed head SHA. It never pushes,
retries, comments, changes pull request state, or merges.
`required_checks_passed` describes check state only; apply the preflight in
[merge.md](merge.md) before any merge. Exit 0 is passed or merged, 1 needs action,
2 a usage or query error, 3 the `--timeout`.

Decide by the final `reason`, not the exit code: `action_required` exits 1, or 2 when a query
error is among the blocked targets.

When the watcher reports `action_required`, inspect the reported state in the
main session and apply the SKILL.md **Diagnose and repair** section under the
invocation's authorization. Start a new `agt ci wait` with the refreshed head SHA after a mutation.
