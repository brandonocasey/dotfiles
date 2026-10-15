# When to run a review automatically

Run `review-fix` (`review --fix`, which fixes and loops) on this session's own
change at task end points, not per iteration turn. A change that never reaches
an end point stays unreviewed, and each report says so (**Timing**). The only
exception is a preview prototype (**Scope**).

## Timing

- Review only at an end point:
  - the user says the task is done, or asks for a review;
  - a commit the user asked for, or `investigate` step 7's fix commit. Routine
    per-turn commits (git-policy's commit before reporting) do not count;
  - right after a push outside `ship`, while its CI runs; push the fixes after;
  - just before integrating the change into another branch (merge, cherry-pick,
    or fast-forwarding a shared branch to include it) outside `land`, or
    deploying it. Rebasing the task branch to sync it does not count;
  - just before triggering an automated build or test run on another system,
    such as a Jenkins build. A push's CI counts as the push. Local checks and
    person-run device tests do not count.
  - during `ship` or `land`, at the points below.
- A turn-end report is not an end point. While the user iterates, never review
  per edit, todo, turn, or intermediate commit. Put this line just above any
  `Next:` line, or last when there is none:
  `⚠ Not reviewed yet: reviews at done, commit, push, integrate, deploy, land, or remote test run.`
- At an end point, review the combined diff since the last review (or the task's
  recorded starting revision), committed and uncommitted alike. A clean tree does
  not mean nothing to review. Finish the implementation and the checks and manual
  check that can run before the end point. Checks that only run remotely or need
  a device or person may follow the review; report them as pending.
- When the task goes straight on to `ship` or `land` in the same turn, skip
  earlier end points and review only there.
- During `ship`, review after the push per ship's finish-scope.md.
- During `land`, review after its step 3 rebase and checks, before the fast-forward.
- Wait for the independent result, verify findings, apply confirmed in-scope fixes,
  and rerun affected checks before reporting completion. Pushes and changes outside
  the intended behavior keep their existing authorization rules. Report the
  verified outcome, including defects fixed, never relabeling it clean after repairs.
  Disclose any inline fallback ([delegation.md](delegation.md)).

## Scope

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
  the loop are not follow-ups.
- Follow-ups wait for the next end point (**Timing**). Then review them together
  as one delta (`<last-reviewed-sha>..<new-head-sha>`) with surrounding context,
  even a one-line or prose-only edit.
- The fix loop ([loop.md](loop.md)) owns re-checks of the review's own repairs.
  Report unresolved findings explicitly. Do not rerun a review of the whole
  target merely to obtain a clean report after repairs.

## What review cannot replace

- A clean review never substitutes for manual verification (visible behavior still
  needs the manual check in AGENTS.md) or required repository checks. Layout, device
  behavior, runtime limits, real-data parsing, external services, and CI-only
  budgets may require evidence beyond reading the diff.
