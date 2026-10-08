## 4. Finish the requested scope

- With `--merge`, read [merge.md](merge.md) and finish that workflow
  before cleanup. It supports GitHub and GitLab through `pr-fix`.
- Honor an explicit monitoring or repair request in the current turn. Keep the
  worktree until that work ends. Without one, start the CI watch in
  [monitoring.md](../../sub-agents/references/monitoring.md) **Watch CI after shipping**
  and report without waiting for it.
- Handle CI when the user requests it, once for jobs that already
  failed when the `review` skill's own-work rule requires it, or when the
  CI watch reports a failure, under its limits in monitoring.md.
  Before repairs or retries, read [ci-repair.md](ci-repair.md).
