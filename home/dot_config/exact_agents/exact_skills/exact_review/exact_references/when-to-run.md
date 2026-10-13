# When to run a review automatically

Run an independent `review` on this session's own change
once the work is complete. Review when requested or when material uncertainty
remains. Otherwise apply the triggers and narrow exceptions below.

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

## Triggers

- New features, behavior or logic changes, bug fixes, and broad refactors trigger
  review regardless of line count or caller count. This includes consolidation,
  type cleanup, and "no behavior change" edits that touch logic.
- Review changes affecting security, trust boundaries, persistence, migrations,
  deletion, external writes, concurrency, crypto, or shared contracts.
- Include routing, paths, parsing, validation, resource limits, error handling,
  browser workers, WASM, OPFS, service workers, and async lifecycle changes.
- Classify shell scripts, wrappers, CI workflows, build or packaging config, tests,
  documentation, and agent instructions by their effect. Changes to checks that
  decide whether tests or CI passed require review.
- Review manual rebase or merge conflict resolutions and changed branches,
  conditions, or error paths without a test that ran green in this task.
- Review the combined implementation, including committed task changes, rather than
  assessing each small edit in isolation.

## Skip exceptions

- Prototypes built only to show through `preview` or Artifacts (`/preview`,
  `/artifacts`) skip review unless the user requests it. The triggers apply once
  that code moves into a change that will ship.
- Otherwise, skip only when the user did not request review, no material uncertainty remains,
  and every change is a prose-only correction, cosmetic styling that preserves
  interaction, or a narrow mechanical edit with verified equivalence: no decisions,
  state transitions, accepted inputs, error behavior, or integration assumptions
  change. Passing tests alone does not justify skipping.
- A dependency bump, config value, or test-only change is not automatically
  exempt. Broad refactors still require review. Inspect the diff and run relevant
  checks.

## Follow-ups

- Review fixes and follow-up commits as a delta (`<last-reviewed-sha>..<new-head-sha>`)
  with surrounding context when they change logic beyond a one-line local edit
  or a one-line edit that introduces new behavior or risk. This replaces the
  once-per-hand-off rule for repairs after a review.
- When **Second reviewer** requires two reviewers, run the review with `--loop`
  unless the user set `--no-loop`; [loop.md](loop.md) then owns the follow-ups.
- Otherwise run one follow-up review for the repair delta; verify and test
  its fixes without an automatic convergence loop. Separate later behavior or risk
  changes start a new delta review. Report unresolved findings explicitly.
- Cosmetic CSS or prose-only follow-ups use the skip exceptions above. Do not rerun
  a full review merely to obtain a clean report after repairs. Explicit `--loop`
  requests retain their workflow.

## Second reviewer

- Use one reviewer for narrow configuration fixes to already exposed services.
  Require two (`--loop` runs both) when changing access controls, exposing
  additional services, or weakening security checks.
- For other changes, require two when touching a trust boundary, concurrency,
  or persistence, or exceeding about 400 changed lines of hand-written logic.
- If `deep-review` is unavailable, use the available independent reviewer and
  disclose the coverage limit; never bypass tool restrictions to satisfy the count.

## What review cannot replace

- A clean review never substitutes for manual verification (visible behavior still
  needs the manual check in AGENTS.md) or required repository checks. Layout, device
  behavior, runtime limits, real-data parsing, external services, and CI-only
  budgets may require evidence beyond reading the diff.
