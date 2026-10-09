## 4. Finish the requested scope

- When [when-to-run.md](../../review/references/when-to-run.md) triggers a review
  after the push, start it at once, pinned to `<COMMIT_BASE>..<HEAD_SHA>`. Start
  the CI watch from the monitoring bullet below at the same time, when it applies.
- Wait for the review, not CI, before the report. While it runs, make no commits
  and hold CI repairs.
- After it ends, if the CI watch reported a failure, run its repair before applying
  any review fix; keep the tree clean until the repair commit passes its checks.
  Then commit verified review fixes and run the **Manual check** of
  `shared/git-flow.md`. Push once per `ship` step 2; ship's push authorization
  covers it. Restart the CI watch at the new head.
  Count that push toward monitoring.md's fix-push cap only when it carries a CI repair.
- Run any follow-up delta review from when-to-run.md **Follow-ups** after that push,
  while the new CI runs. Its fixes get one more push; no further review loop.
- After every review and fix push ends, restore any paused auto-merge per
  [auto-merge-pause.md](../../shared/auto-merge-pause.md) **Restore**. It stays off
  while a blocking finding or failed repair remains.
- With `--merge`, after that point and with no blocking finding left, read
  [merge.md](merge.md) and finish that workflow before cleanup. It supports GitHub and GitLab through `pr-fix`.
- Honor an explicit monitoring or repair request in the current turn. Keep the
  worktree until that work ends. Without one, start the CI watch in
  [monitoring.md](../../sub-agents/references/monitoring.md) **Watch CI after shipping**
  and report without waiting for it.
- Handle CI when the user requests it, once for jobs that already
  failed when the `review` skill's own-work rule requires it, or when the
  CI watch reports a failure, under its limits in monitoring.md.
  Before repairs or retries, read [ci-repair.md](ci-repair.md).
