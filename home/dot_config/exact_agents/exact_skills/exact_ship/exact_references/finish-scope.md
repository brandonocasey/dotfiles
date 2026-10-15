## 4. Finish the requested scope

- When [when-to-run.md](../../review/references/when-to-run.md) triggers a review
  after the push, start it at once as `review --fix` (what `review-fix` runs),
  pinned to `<COMMIT_BASE>..<HEAD_SHA>`. With `--approve` or `--merge`, always run it.
- Start the CI watch at the same time, per [ci-repair.md](ci-repair.md) **Watch
  CI after shipping**, and report without waiting for it. Honor an explicit
  monitoring or repair request in the current turn, and keep the worktree until
  that work ends. Read ci-repair.md before any repair or retry; it also covers
  a CI failure the user requests or the own-work rule in
  [when-to-run.md](../../review/references/when-to-run.md) **Timing** requires (once,
  for jobs that already failed).
- Wait for the review, not CI, before the report. While it runs, make no commits
  and hold CI repairs.
- After it ends, if the CI watch reported a failure, run its repair before applying
  any review fix; keep the tree clean until the repair commit passes its checks.
  Then commit verified review fixes and run the **Manual check** of
  `shared/git-flow.md`. Push once per `ship` step 2; ship's push authorization
  covers it. Restart the CI watch at the new head. Count that push toward
  ci-repair.md's fix-push cap only when it carries a CI repair.
- The review's fix loop ([loop.md](../../review/references/loop.md)) decides when
  to re-check, while the new CI runs. Push each later fix pass the same way.
- After every review and fix push ends, and the loop's step 5 list is empty or
  the user's answer resolves or accepts every item, restore any paused auto-merge
  per [auto-merge-pause.md](../../shared/auto-merge-pause.md).
- With `--approve` or `--merge`, under that same condition and with no blocking
  finding left,
  follow [merge.md](merge.md) at the last `HEAD_SHA` before cleanup: **Approve**
  only with `--approve`; **Inspect**, **Enable auto-merge**, and **Watch** only
  with `--merge`.
