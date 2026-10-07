## 4. Finish the requested scope

- With `--merge`, read [merge.md](merge.md) and finish that workflow
  before cleanup. It supports GitHub and GitLab through `pr-fix`.
- Honor an explicit monitoring or repair request in the current turn. Keep the
  worktree until that work ends. Without one, report the pipeline URL without waiting.
- Handle CI when the user requests it, or once for jobs that already
  failed when the `review` skill's own-work rule requires it.
  Before repairs or retries, read [ci-repair.md](ci-repair.md).
