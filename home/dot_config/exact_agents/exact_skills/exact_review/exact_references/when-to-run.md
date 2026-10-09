# When to run a review automatically

Applies to every model. Run an independent `review` on this session's own change
once the work is complete. Review when requested or when material uncertainty
remains. Otherwise apply the triggers and narrow exceptions below.

## Timing

- Complete means implementation, relevant checks, and the manual check are done.
  Never run an automatic review mid-task: not per edit, todo, or intermediate commit.
- Review once per hand-off. A task that ends in `ship` reviews only there.
- During `ship`, start the review right after the push and MR/PR update, so CI runs
  while the review does. `ship`'s finish-scope.md owns that flow. When the MR/PR
  has auto-merge on, pause it per `shared/auto-merge-pause.md` and still push first;
  a queued one gets a new MR/PR.
  If the pause fails, that file moves the review before the push.
- During `land`, review after its step 3 rebase and checks, before the fast-forward.
- Otherwise, review just before the hand-off: a push outside `ship`, or the final
  report to the user.

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
  interaction, or a narrow mechanical edit with verified equivalence.
- No decisions, state transitions, accepted inputs, error behavior, or integration
  assumptions may change. Passing tests alone does not justify skipping.
- A dependency bump, config value, or test-only change is not automatically
  exempt. Broad refactors still require review. Inspect the diff and run relevant
  checks; visible behavior changes still need the manual check in AGENTS.md.

## Follow-ups

- Review fixes and follow-up commits as a delta (`<last-reviewed-sha>..<new-head-sha>`)
  with surrounding context when they change logic beyond a one-line local edit.
  A one-line edit still requires review if it introduces new behavior or risk.
- Without `--loop`, run one follow-up review for the repair delta; verify and test
  its fixes without an automatic convergence loop. Separate later behavior or risk
  changes start a new delta review. Report unresolved findings explicitly.
- Cosmetic CSS or prose-only follow-ups use the skip exceptions above; visible
  changes still need the rendered check. Do not rerun a full review merely to obtain
  a clean report after repairs. Explicit `--loop` requests retain their workflow.

## Second reviewer

- Run `--deep` when the change touches a trust boundary, concurrency, or
  persistence, or exceeds about 400 changed lines of hand-written logic.
- If `deep-review` is unavailable, use the available independent reviewer and
  disclose the coverage limit; never bypass tool restrictions to satisfy the count.

## What review cannot replace

- A clean review never substitutes for manual verification or required repository
  checks. Layout, device behavior, runtime limits, real-data parsing, external
  services, and CI-only budgets may require evidence beyond reading the diff.
