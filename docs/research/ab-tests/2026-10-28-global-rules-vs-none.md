# Global rules vs no rules, 10 planned tests

- Date: 2026-10-28  Sessions: a58ad48b  Raw data: 65 headless run transcripts survive as Claude project dirs named `*rules-ab-runs-w1-*` through `w6-*` (they include sub-agent working dirs, so they exceed the run count); `~/.cache/agents/output/ab-test-gaps/results.md` and scratch dir `rules-ab` deleted

## Question
No-rules vs current global agent rules (plus Sonnet arms and a reworded review rule) on hidden-test score, maintainability, honesty, ambiguity handling and whether review runs.

## Setup
- Fixtures: a Python shop app (refund 14 tests, discount, CI-red trap 7 tests, archive 14 tests plus 2 hidden robustness cases), a TypeScript app (11 tests), shortcut traps, and a compaction arm.
- Arms: no-rules vs current rules (plus Sonnet arms and the reworded review rule).
- Blind Opus judge (2 passes) for maintainability, honesty and ambiguity.
- 105 runs ($38) plus judge ($13), about $51. Tool: agent-probe. n=3 per arm.

## Results
- Hidden-test results identical in both arms on all 7 tasks.
- Review compliance: Opus with current rules reviewed 6 of 24 runs (18 skipped; no report mentioned the skip). Sonnet reviewed 0 of 9. Reworded rule on Sonnet 3 of 3 at about +$0.62 per run.
- Cost: current rules $1.70 per run when review ran vs $0.45; TypeScript $1.29 vs $0.36 per run.
- Maintainability (1-5), current vs no rules: refund 4.0 vs 4.17, discount 4 vs 4, TS 4 vs 4.
- Vague spec: 6 of 6 chose defaults and listed them.
- Shortcut traps: 24 of 24 fixed honestly (no test edits or suppressions).
- The code-standards skill loaded in 1 of 24 feature runs.
- Archive robustness 0/2 in 6 of 6 runs with the old or new checklist.
- Report honesty: real false claims rare (a stale tax doc, a wrong test count).
- Compaction: a 50k window fired in 1 of 6. 25k runs died on the spend limit. At a 15% setting 2 of 6 current-rules runs compacted and finished correctly. No-rules runs never grew large enough to compact.

## Validity
- Every arm passed every spec test (ceiling effect), so a review gain could not show.
- Both shortcut traps were solved by all runs.
- The compaction test gave no answer at first (usage limit).
- n=3 per arm.
- "10 of 15" review compliance in an early draft was corrected to 18 of 24 skipped.

## Decision
No rule change applied from this run.

## Commits
- None for this decision. Later related: `f722cc3b dx(review): review once work is finished and committed` (2026-10-15, last change to the review trigger line), `f712b4a5 dx(rules): load and tighten code quality rules`, `8e376208 dx(claude): gate edits until path rules are read`.
