# Global rules vs no rules, 10 planned tests

- Date: 2026-10-28  Sessions: a58ad48b (2026-10-28 05:09-11:06 UTC)  Raw data: `~/.cache/agents/output/ab-test-gaps/results.md` and the scratch dir `rules-ab` are deleted (checked with `test -e`). 65 headless run transcripts survive as Claude project dirs named `*rules-ab-runs-w1-*` through `w6-*` (w1 21, w2 20, w4 5, w5 7, w6 12; they include sub-agent working dirs, so they exceed the run count).
- Related: [reworded review rule on Opus](2026-10-28-reworded-review-rule.md), [reruns review on/off](2026-10-29-reruns-review-on-off.md), [inline vs sub-agent review](2026-10-28-inline-vs-subagent-review.md), [rule-loading probes](2026-11-05-rule-loading-probes.md)

## Question
Do the global agent rules improve unattended quality and maintainability, and does review run? The user asked: "are there any other ab tests we should run to determine if our current global agent rules are as ideal as possible for automatic unattended quality and maintainability?" and then set the goal "run all ab tests and collect results".

## Setup
- Fixtures: a Python shop app (refund 14 tests, discount, CI-red trap 7 tests, archive 14 tests plus 2 hidden robustness cases), a TypeScript app (11 tests), shortcut traps, and a compaction arm.
- Arms: no-rules vs current rules (plus Sonnet arms and the reworded review rule).
- Blind Opus judge (2 passes) for maintainability, honesty and ambiguity.
- 105 runs ($38) plus judge ($13), about $51. Tool: agent-probe. n=3 per arm.

## Results
- Same hidden-test results in both arms on all 7 tasks.
- Review compliance: Opus with current rules reviewed 6 of 24 runs (skipped 18; no report mentioned the skip). Sonnet reviewed 0 of 9. The reworded rule on Sonnet 3 of 3 at about +$0.62 per run.
- Cost: current rules $1.70 per run when review ran vs $0.45. TypeScript $1.29 vs $0.36 per run.
- Maintainability (1-5): about 4 in both arms (refund 4.0 vs 4.17, discount 4 vs 4, TS 4 vs 4).
- Vague spec: 6 of 6 chose defaults and listed them.
- Shortcut traps: 24 of 24 fixed honestly (no test edits or suppressions).
- The code-standards skill loaded in 1 of 24 feature runs.
- Archive robustness failed 0/2 in 6 of 6 runs with the old or new checklist.
- Report honesty: real false claims rare (a stale tax doc, a wrong test count).
- Compaction: a 50k window fired in 1 of 6. 25k runs died on the spend limit (not a result). At a 15% setting 2 of 6 current-rules runs compacted and finished correctly. No-rules runs never grew large enough to compact.

## Validity
- Every arm passed every spec test (ceiling), so the review gain could not show.
- Both shortcut traps were too easy.
- The compaction test gave no answer at first (usage limit).
- The assistant corrected "10 of 15" to 18 of 24.

## Decision
The assistant recommended two fixes and applied neither: (1) apply the reworded review rule to all models and require the report to say when review was skipped (about $1.25 more per reviewed task); (2) auto-load code-standards before code changes (value unproven). The user's decision is not recorded in this session. The final user turns were "ok".

## History
- 2026-10-28 — Ten tests run in session a58ad48b.
- 2026-10-28 — Commits applying either fix at the time: none found. `34591586 dx(skills): update review and ticket rules` (2026-10-29) and `e3ee004f dx(skills): cheaper review modes for small changes` (2026-10-30) were listed as adjacent in the old record. 34591586 is about agt `kept_local` posting, unrelated. e3ee004f adds a small-change review mode and was not shown to be caused by this test (session not located).
- 2026-10-28 — Session 639aaece tested the reworded rule on Opus and calibrated harder tasks.
- 2026-10-29 — Session 686bb3b6 reran the inconclusive tests.
- 2026-11-05/06 — Fix 2 (auto-load code standards) was built through the rule-loading probes: `f712b4a5 dx(rules): load and tighten code quality rules`, `8e376208 dx(claude): gate edits until path rules are read`.
- Today: fix 1 (reworded review rule) is not in the rules. The review trigger line in `home/.chezmoitemplates/main-rules.md` last changed on 2026-10-15 (`f722cc3b dx(review): review once work is finished and committed`). Fix 2 is live as path-scoped rules plus the `rule-gate.py` hook.
