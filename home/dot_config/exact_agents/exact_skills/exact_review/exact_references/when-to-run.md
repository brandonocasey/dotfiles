# When to run a review automatically

Run `review-fix` (`review --fix`, which fixes and loops) on this session's own
change once the work is finished and committed, and at the other end points
below, not per edit, turn, or commit. A change that never reaches an end point
stays unreviewed, and each report says so (**Timing**). The only exception is a
preview prototype (**Scope**).

## Timing

- Review only at an end point:
  - the user asks for a review;
  - the work is finished and its commits are made: right after the last commit
    of the batch (git-policy's commit before reporting done, a commit the user
    asked for, or `investigate`'s fix commit, section 5, item 7). Review the
    whole batch once, not each commit. Commit the review's fixes per git-policy.
    When more changes are later committed on top, review again (**Follow-ups**).
    Commits of fixes made inside any review's fix loop never trigger another
    review;
  - right after a push outside `ship`, while its CI runs; push the fixes after;
  - just before integrating the change into another branch (merge, cherry-pick,
    or fast-forwarding a shared branch to include it) outside `land`, or
    deploying it. Rebasing the task branch to sync it does not count;
  - just before triggering an automated build or test run on another system,
    such as a Jenkins build. A push's CI counts as the push. Local checks and
    person-run device tests do not count.
  - during `ship` or `land`, at the points below.
- A turn-end report is not an end point, nor is a done report with the work left
  uncommitted. While the user iterates, never review per edit, todo, turn, or
  intermediate commit: one made while work continues in the same turn. The
  commit before a done report is not intermediate, even when more requests may
  follow. When unreviewed changes remain, put this line just above
  any `Next:` line, or last when there is none:
  `⚠ Not reviewed yet: reviews at finish with commits, push, integrate, deploy, land, or remote test run.`
- At an end point, review the combined diff since the last review (or the task's
  recorded starting revision), committed and uncommitted alike. A clean tree does
  not mean nothing to review. Finish the implementation; the review's testing stage
  ([testing.md](testing.md)) runs the checks and the manual and UX check. Checks that
  only run remotely or need a device or person may follow the review; report them
  as pending.
- Each review run records its reviewed range in the `agt review` store
  ([store.md](store.md)). Skip the review only when `agt review status` reports
  `reviewed: true` and an empty `unreviewed_commits`, plus `worktree.reviewed: true`
  when the tree is dirty; report it as `✓ already reviewed at <head-sha>`. Otherwise
  review `<review_from>..HEAD` from `status`, or from the task's starting revision
  when `review_from` is null, plus uncommitted work.
- Before the final review of this session's own work, inspect already-finished CI
  failures of any existing task-branch push, once, per
  [ci-and-conflicts.md](ci-and-conflicts.md), and fix them. Never wait for CI or
  push solely to obtain it. During `ship`, skip this when the push starts a new
  pipeline. Without push authorization, review locally.
- When the task goes straight on to `ship` or `land` in the same turn, skip
  earlier end points and review only there.
- During `ship`, review after the push per ship's finish-scope.md.
- During `land`, review after its step 3 rebase and checks, before the fast-forward.
  Check `agt review status` first, so a rebase alone triggers no second review.
- Wait for the independent result, verify findings, apply confirmed in-scope fixes,
  and retest them ([testing.md](testing.md) **Retest**) before reporting completion. Pushes and changes outside
  the intended behavior keep their existing authorization rules. Report the
  verified outcome, including defects fixed, never relabeling it clean after repairs.
  Disclose any inline fallback ([delegation.md](delegation.md)).

## Scope

- A change made through a [pipeline](../../sub-agents/references/pipeline.md)
  handoff is reviewed by its orchestrator. Review it again only when that review
  did not run or the checks fail.
- Fixing an existing PR/MR (`pr-fix`, CI or comment repairs): review only the
  fix, `<base>..<new-head>`, not the whole PR/MR, unless the user asks for a
  full review. `<base>` is the local HEAD just before the first fix commit,
  after any rebase, so upstream and rebased commits stay out. When the rebase
  had conflicts, also review the resolutions, even with no fix commit:
  `git range-diff --creation-factor=100 <old-base>..<old-head> <new-base>..<base>`.
- Review the combined implementation, including committed task changes, rather
  than each small edit in isolation. This covers code, tests, config, dependency
  bumps, shell scripts, CI workflows, build config, documentation, and agent
  instructions. Passing tests never replace the review.
- Prototypes built only to show through `preview` or Artifacts (`/preview`,
  `/artifacts`) skip review unless the user requests it. Review applies once
  that code moves into a change that will ship.

## Follow-ups

- A follow-up change is one made after the review's fix loop ends. Repairs inside
  the loop, and their commits, are not follow-ups. Fixes for the review's own
  findings, including held questions the user decides later, are repairs, not
  follow-ups. The fix loop's rules apply: only a major finding's fix gets a
  re-check, by the same reviewer.
- Follow-ups wait for the next end point (**Timing**), such as their own finished
  commit. Then review them together as one delta
  (`<last-reviewed-sha>..<new-head-sha>`) with surrounding context, even a
  one-line or prose-only edit. End the run with `agt review run end` after the
  last fix commit, so `status` counts the fix commits as reviewed.
- The fix loop ([loop.md](loop.md)) owns re-checks of the review's own repairs.
  Report unresolved findings explicitly. Do not rerun a review of the whole
  target merely to obtain a clean report after repairs.

## What review cannot replace

- A clean review never substitutes for manual verification (visible behavior still
  needs the manual check in AGENTS.md) or required repository checks. Layout, device
  behavior, runtime limits, real-data parsing, external services, and CI-only
  budgets may require evidence beyond reading the diff.
