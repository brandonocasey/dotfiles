# When to run a review automatically

Run `review-fix` (`review --fix`, which fixes and loops) on this session's own
change once the work is complete. Every change, including each follow-up, gets a
review. The only exception is a preview prototype (**Scope**).

## Timing

- Complete means implementation, relevant checks, and the manual check are done.
  Never run an automatic review mid-task: not per edit, todo, or intermediate commit.
- Review the combined task diff once per hand-off, committed and uncommitted
  changes alike (a clean tree does not mean nothing to review), from the task's
  recorded starting revision. A task that ends in `ship` reviews only there.
- During `ship`, review after the push per ship's finish-scope.md.
- During `land`, review after its step 3 rebase and checks, before the fast-forward.
- Otherwise, review just before the hand-off: a push outside `ship`, or the final
  report to the user.
- Wait for the independent result, verify findings, apply confirmed in-scope fixes,
  and rerun affected checks before reporting completion. Pushes and changes outside
  the intended behavior keep their existing authorization rules. Report the
  verified outcome, including defects fixed, never relabeling it clean after repairs.
  Disclose any inline fallback ([delegation.md](delegation.md)).

## Scope

- Review the combined implementation, including committed task changes, rather
  than each small edit in isolation. This covers code, tests, config, dependency
  bumps, shell scripts, CI workflows, build config, documentation, and agent
  instructions. Passing tests never replace the review.
- Prototypes built only to show through `preview` or Artifacts (`/preview`,
  `/artifacts`) skip review unless the user requests it. Review applies once
  that code moves into a change that will ship.

## Follow-ups

- A follow-up change is one made after the review's fix loop ends. Repairs inside
  the loop are not follow-ups.
- Review each follow-up change as a delta (`<last-reviewed-sha>..<new-head-sha>`)
  with surrounding context, even a one-line or prose-only edit. This replaces the
  once-per-hand-off rule for repairs after a review.
- The fix loop ([loop.md](loop.md)) owns re-checks of the review's own repairs.
  Report unresolved findings explicitly. Do not rerun a review of the whole
  target merely to obtain a clean report after repairs.

## What review cannot replace

- A clean review never substitutes for manual verification (visible behavior still
  needs the manual check in AGENTS.md) or required repository checks. Layout, device
  behavior, runtime limits, real-data parsing, external services, and CI-only
  budgets may require evidence beyond reading the diff.
