# Reworded review rule on Opus, calibration of harder tasks, real-history tasks

- Date: 2026-10-28  Sessions: 639aaece (2026-10-28 14:51-20:52 UTC)  Raw data: 24 headless run transcripts survive as Claude project dirs named `*rules-ab-runs-w7-*` (6), `*cal-*` (9) and `*cal2-*` (9). Fixtures, hidden tests and the `ab-test-gaps` results are deleted (checked with `test -e`).
- Related: [global rules vs no rules](2026-10-28-global-rules-vs-none.md) (the test this continues; same plan name `plan-a-b-tests-for-global-agent-rules`), [reruns review on/off](2026-10-29-reruns-review-on-off.md), [inline vs sub-agent review](2026-10-28-inline-vs-subagent-review.md)

## Question
Does the stronger review wording work on Opus, and do harder tasks separate the arms? The session began with "continue `plan-a-b-tests-for-global-agent-rules` and do an another ab test if necessary". The user then asked "was this run complictated enough to show actual issues" and "build the harder tasks, but wait on actually running".

## Setup
- 6 Opus runs (archive x3, refund x3) with the reworded rule.
- Then 3 harder tasks (CSV import, coupons, order edit; hidden spec and edge tests; reference solutions pass), calibrated with 9 no-rules Opus runs.
- Then 4 tasks from real repo history (a work repo's notifications feature in TypeScript, 33 files, agent-review sparse checkout and tracking worktree, agt check cache), built. Only 3 calibration runs finished.

## Results
- Reworded rule: review ran 6 of 6 (vs 6 of 24 under current rules). Every final report stated the review result.
- Refund 14/14 in 3 of 3. Archive 14/14 but robustness 0/2 in 3 of 3. The reviews missed both seeded archive bugs (overwriting an existing archive file, one unreadable file stopping the rest).
- $2.08 per run vs $0.90 for current-rules refund runs.
- Reviews fixed real edge bugs not covered by hidden tests (huge-number crash, `A1:²` input, refund drift after a tax-rate change).
- Calibration: coupons edge 8/8 x3, order edit 7/7 x3, CSV import 9/9, 8/9, 8/9. Cost $2.81 for 9 runs. Too easy.
- Real-history tasks: starting-code spec scores e.g. TS 11/31 to 31/31 on the feature, edge tests 0/6 on the feature. 12 calibration runs were approved ("approve") and stopped after 3 finished, for usage ("i think we're going to be out of usage").

## Validity
- The assistant said the tasks were "still too easy" and that no-quality-gain "does not hold up": tests could not have shown a gain.
- Hidden tests were reachable by agents.
- The 3 finished real-task runs were ungraded.
- n=3 per arm catches compliance effects (6 of 24 vs 6 of 6) but not small quality gains.

## Decision
No rule change applied in this session. The recommendation was unchanged: apply the reworded review rule to all models (+$1.20 per task) and do not auto-load code-standards (it showed no gain in 6 of 6 archive runs). The assistant asked "apply option 1, 2, both, or 3?". The user's choice is not recorded in the session (the session ended at the usage limit, with the grading command saved for a later session).

## History
- 2026-10-28 — Oct 28 rules-vs-none run (session a58ad48b) recommended the reworded rule. This session tested it on Opus.
- 2026-10-28 — Commits applying the decision: none found. Searched `git log -S` for the reworded review text and the review trigger line.
- 2026-10-29 — Session 686bb3b6 reran the two inconclusive tests (see reruns).
- 2026-11-05/06 — The code-standards auto-load idea was built later through the rule-loading probes (`f712b4a5 dx(rules): load and tighten code quality rules`, `8e376208 dx(claude): gate edits until path rules are read`).
- Today: the reworded rule was not applied. `home/.chezmoitemplates/main-rules.md` line 27 ("Before completing code/test/config/instruction changes: `review/references/when-to-run.md`. Review only at its end points ... read-only tasks need none.") last changed in `f722cc3b dx(review): review once work is finished and committed` (2026-10-15). Review compliance (6 of 24 under the old rule) was not re-measured after that. Not found: any later measurement.
