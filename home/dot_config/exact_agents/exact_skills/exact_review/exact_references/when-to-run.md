# When to run a review automatically

Run `review-fix` (`review --fix`, which fixes and loops) on this session's own
change once the work is complete. Every change, including each follow-up, gets a
review: light or normal, per **Choose the tier** below. The only exception is a
preview prototype.

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

## Normal-tier triggers

Use the normal tier (`reviewer`) when any of these apply:

- New features, behavior or logic changes, bug fixes, and refactors, including
  consolidation, type cleanup, and "no behavior change" edits that touch logic.
  Exception: a small logic change (see **Choose the tier**) whose changed lines
  a test that ran green in this task covers. Broad refactors are never small.
- Changes affecting security, trust boundaries, persistence, migrations,
  deletion, external writes, concurrency, crypto, or shared contracts.
- Routing, paths, parsing, validation, resource limits, error handling,
  browser workers, WASM, OPFS, service workers, and async lifecycle changes.
- Changes to checks that decide whether tests or CI passed. Classify other shell
  scripts, wrappers, CI workflows, build or packaging config, tests, documentation,
  and agent instructions by their effect.
- Manual rebase or merge conflict resolutions, and changed branches, conditions,
  or error paths without a test that ran green in this task.
- Material uncertainty remains, or the user asks for a normal, full, or deep review.
- Judge the combined implementation, including committed task changes, rather than
  each small edit in isolation.

## Choose the tier

- Use the light tier (`light-reviewer`) only when no normal-tier trigger applies
  and the combined diff is either:
  - prose-only, cosmetic styling that preserves interaction, or a narrow
    mechanical edit with verified equivalence: no decisions, state transitions,
    accepted inputs, error behavior, or integration assumptions change; or
  - small: at most about 40 changed lines in at most 2 files.
- Everything else gets the normal tier. When unsure, choose normal. `--light` and
  `--normal` override this choice. Name the tier in the report. The tier picks
  the reviewer role only; it does not change loop.md's full-review or fix-check passes.
- A dependency bump, config value, or test-only change is not automatically
  light. Inspect the diff and run relevant checks first. Passing tests alone
  never decide the tier.
- Prototypes built only to show through `preview` or Artifacts (`/preview`,
  `/artifacts`) skip review unless the user requests it. This section applies once
  that code moves into a change that will ship.

## Follow-ups

- A follow-up change is one made after the review's fix loop ends. Repairs inside
  the loop are not follow-ups.
- Review each follow-up change as a delta (`<last-reviewed-sha>..<new-head-sha>`)
  with surrounding context, even a one-line or prose-only edit. Pick its tier by
  **Choose the tier**, using the delta alone. This replaces the once-per-hand-off
  rule for repairs after a review.
- The fix loop ([loop.md](loop.md)) owns re-checks of the review's own repairs.
  Report unresolved findings explicitly. Do not rerun a review of the whole
  target merely to obtain a clean report after repairs.

## What review cannot replace

- A clean review never substitutes for manual verification (visible behavior still
  needs the manual check in AGENTS.md) or required repository checks. Layout, device
  behavior, runtime limits, real-data parsing, external services, and CI-only
  budgets may require evidence beyond reading the diff.
