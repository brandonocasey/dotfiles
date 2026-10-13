## 4. Finish the requested scope

- When [when-to-run.md](../../review/references/when-to-run.md) triggers a review
  after the push, start it at once, pinned to `<COMMIT_BASE>..<HEAD_SHA>`.
- Start the CI watch at the same time, per [ci-repair.md](ci-repair.md) **Watch
  CI after shipping**, and report without waiting for it. Honor an explicit
  monitoring or repair request in the current turn, and keep the worktree until
  that work ends. Read ci-repair.md before any repair or retry; it also covers
  a CI failure the user requests or the `review` own-work rule requires (once,
  for jobs that already failed).
- Wait for the review, not CI, before the report. While it runs, make no commits
  and hold CI repairs.
- After it ends, if the CI watch reported a failure, run its repair before applying
  any review fix; keep the tree clean until the repair commit passes its checks.
  Then commit verified review fixes and run the **Manual check** of
  `shared/git-flow.md`. Push once per `ship` step 2; ship's push authorization
  covers it. Restart the CI watch at the new head. Count that push toward
  ci-repair.md's fix-push cap only when it carries a CI repair.
- Run any follow-up delta review from when-to-run.md **Follow-ups** after that push,
  while the new CI runs. Its fixes get one more push; no further review loop, unless
  the review runs `--loop`, whose passes then own the pushes.
- After every review and fix push ends, restore any paused auto-merge per
  [auto-merge-pause.md](../../shared/auto-merge-pause.md).
- With `--merge`, after that point and with no blocking finding left, read
  [merge.md](merge.md) and finish that workflow before cleanup.
