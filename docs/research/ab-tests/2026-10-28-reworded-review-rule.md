# Reworded review rule on Opus, calibration of harder tasks, real-history tasks

- Date: 2026-10-28  Sessions: 639aaece  Raw data: 24 headless run transcripts survive as Claude project dirs named `*rules-ab-runs-w7-*` (6), `*cal-*` (9) and `*cal2-*` (9); fixtures, hidden tests and the `ab-test-gaps` results are deleted

## Question
Review rate and hidden-test score with the reworded review rule vs the current rules on Opus, and whether harder tasks separate the arms.

## Setup
- 6 Opus runs (archive x3, refund x3) with the reworded rule, compared with earlier current-rules runs (see [global rules vs no rules](2026-10-28-global-rules-vs-none.md)).
- 3 harder tasks (CSV import, coupons, order edit; hidden spec and edge tests; reference solutions pass), calibrated with 9 no-rules Opus runs.
- 4 tasks from real repo history (a work repo's notifications feature in TypeScript, 33 files, a sparse-checkout and tracking-worktree task, a cache-check task), built; 12 calibration runs planned, 3 finished (usage limit).

## Results
- Reworded rule: review ran 6 of 6 (vs 6 of 24 under current rules). Every final report stated the review result.
- Refund 14/14 in 3 of 3. Archive 14/14 but robustness 0/2 in 3 of 3; the reviews missed both seeded archive bugs (overwriting an existing archive file, one unreadable file stopping the rest).
- $2.08 per run vs $0.90 for current-rules refund runs.
- Reviews fixed edge bugs not covered by hidden tests (huge-number crash, `A1:²` input, refund drift after a tax-rate change).
- Calibration (no rules): coupons edge 8/8 x3, order edit 7/7 x3, CSV import 9/9, 8/9, 8/9. Cost $2.81 for 9 runs.
- Real-history tasks: starting-code spec scores e.g. TS 11/31 to 31/31 on the feature; edge tests 0/6 on the feature.

## Validity
- Calibration tasks were solved by all or nearly all runs (ceiling effect), so quality gains could not show.
- Hidden tests were reachable by agents.
- The 3 finished real-task runs were ungraded.
- n=3 per arm.

## Decision
No rule change applied from this run.

## Commits
- None for this decision. Later related: `f722cc3b dx(review): review once work is finished and committed` (2026-10-15, last change to the review trigger line), `f712b4a5 dx(rules): load and tighten code quality rules`, `8e376208 dx(claude): gate edits until path rules are read`.
