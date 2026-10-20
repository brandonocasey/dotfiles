# agt availability

`agt` is the single CLI for the review store, tasks, session search, CI waiting and triage,
worktrees, live agents, and issues (`agt review`, `agt task`, `agt sessions`, `agt ci`,
`agt worktree`, `agt ps`, `agt issue`). The skill that points here names
the minimum version.

From 0.13.0 it also covers PRs/MRs on GitHub and GitLab (`agt pr view|list|create|update|merge|auto-merge`),
branch push and landing checks (`agt branch check [--checks pushed,landable]`), a secret scan that never prints
values (`agt secrets [PATH...] [--staged]`), a read-only setup check (`agt doctor`), and blocked-session
events (`agt ps --watch`). Each command's `--help` documents its JSON fields and exit codes.

Run `agt --version` once per run. When it fails or prints an older version than the
stated minimum, run `mise install github:brandonocasey/agt` (it reads the
GitHub token of `gh`), then check again. When it still fails, stop and report:
`agt <minimum> missing: run gh auth login, then mise install; Windows is not supported`.

A skill that works without `agt` says so and skips the install above. It uses its
own fallback instead.

From 0.10.0, `agt issue` and `agt review` reads first sync from GitHub or GitLab when
the local copy is over 5 minutes old. When that sync fails, agt prints
`agt: sync skipped (<reason>); showing local data` on stderr. Treat that data as
possibly stale. After a failed sync, agt makes no forge call and prints nothing for the next
5 minutes, so a missing line does not prove the data is fresh. `--offline` skips the sync. Run an
explicit `sync` when a step needs fresh data or its errors.
