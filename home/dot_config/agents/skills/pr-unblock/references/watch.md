## Watch while CI runs

When checks are pending, run one deterministic watcher for all selected pull
requests. Pin each observed head SHA:

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

The watcher uses read-only `gh` or `glab` queries and rejects a changed head
SHA. It reports the initial state, state changes, and one final result. It stops
on check success, merge, close, head change, failure, missing data, permission
error, cancellation, or deadline. It never pushes, retries, comments, changes
pull request state, or merges. `required_checks_passed` describes check state
only; apply the full passing criteria in this skill.

When the watcher reports `action_required`, inspect the reported state in the
main session and apply [branch-repair.md](branch-repair.md) and [check-repair.md](check-repair.md) under the standing
authorization. Start a new watcher with the refreshed head SHA after a mutation.
