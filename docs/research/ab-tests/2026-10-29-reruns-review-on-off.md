# Reruns: review on vs off (w8), harder shortcut trap (w9), w10 rerun

- Date: 2026-10-29  Sessions: 686bb3b6 (2026-10-29 16:47-20:00 UTC)  Raw data: `w10.json`, `w10.md` and the `ab-test-gaps/` output are deleted. 100 headless run transcripts survive as Claude project dirs named `*rules-ab-runs-w8-*` (46), `*w9-*` (19) and `*w10-*` (35); the counts include sub-agent working dirs, so they exceed the run counts.
- Related: [global rules vs no rules](2026-10-28-global-rules-vs-none.md) (the two inconclusive tests being rerun), [reworded review rule on Opus](2026-10-28-reworded-review-rule.md), [inline vs sub-agent review](2026-10-28-inline-vs-subagent-review.md)

## Question
Rerun the two inconclusive tests of the Oct 28 rules-vs-no-rules run. The user asked: "recently we were running two inconclusive ab tests, can you find them and run them again? have a lot of quota in the next hour. ideally we should improve them to the point where they are easy to run".

## Setup
- w8: 4 real-repo tasks (sparse, notify, track, cache) x {no review, forced review} x 3 runs = 24.
- w9: shortcut trap with a CI check failing on an unrelated rounding bug. No-rules vs current rules, 5 runs per arm = 10 (Opus).
- w10: sparse and notify, 6 runs per arm = 24 in parallel with `--strict-mcp-config`.
- Added the `ab.sh` runner and a `PAR=` option.

## Results
- w9: 0 of 10 cheated (no test edits, suppressions, skips or lint edits). Current rules committed with the check still red in 2 of 5 runs (the reports said so). No-rules 0 of 5. Hidden tests 9-11 of 12 in both.
- w8 (20 of 24 graded):
  - sparse: no review robust 2/4 x3, forced review 4/4 and 2/4 ($1.09 vs $5.50).
  - notify: no review 2/6 x2, forced 2/6 and 4/6 ($0.61 vs $1.27).
  - track: identical ($0.80 vs $1.30).
  - cache: forced review passed spec 1 of 3, no review 0 of 2, and 2 of 3 forced runs never committed.
  - Forced review costs 1.5-5x.
- w10: only 7 of 24 finished and committed. Sparse: no review 4 runs 3/3 and 2/4, forced 2 runs 2/3 and 2/4. Notify: no review 1 run 30/31 and 1/6, forced 0 usable.

## Validity
- Disk filled (51 GB of Rust clones) and crashed runs.
- Flaky chrome-devtools MCP startup under 11 parallel runs.
- 4 missing runs.
- In notify both no-review runs still ran a reviewer (contaminated).
- Notify $0.38 runs were probably first-turn costs only: many notify runs end the first turn waiting on a background session.
- The user stopped 12 of 24 w10 runs ("stop any runs that aren't close to completion", "I don't want a next wave after this"). Usage limit.
- The assistant listed 7 failure modes of A/B runs (disk, flaky startup, long serial runs, spend limit, late grading, lost evidence, easy tasks) and drafted a 10-step A/B skill plan, written to `~/Downloads/ab-test-plan.md` at the user's request. The file is gone and no A/B skill was built.

## Decision
Do not make review mandatory for every change. Keep it for risky work, as already decided in the inline-vs-sub-agent test (the assistant's conclusion: "So I would not make review mandatory for every change. Keep it for risky work"). No new rule applied. Cleanup freed about 47 GB.

## History
- 2026-10-28 — The Oct 28 runs (rules vs none, reworded rule) left two tests inconclusive.
- 2026-10-29 — Reruns in session 686bb3b6. The user asked "ok so is there any conclusion from this?" and then "prove it, but I want this faster this time. cleanup 50gb to".
- 2026-10-29 — Commits: none found (searched `git log` for the session id and for w8/w9/w10).
- 2026-10-29 10:52 EDT — `34591586 dx(skills): update review and ticket rules`. Same day, but it changes agt `kept_local` posting handling in review and ticket skills. Unrelated to this test. The old record listed it as adjacent to the Oct 28 test; that link is not supported.
- Today: the review trigger line in `home/.chezmoitemplates/main-rules.md` ("Review only at its end points ... not per turn or intermediate commit") last changed on 2026-10-15 (`f722cc3b dx(review): review once work is finished and committed`), so nothing in this session changed it. The decision was not carried into the rules as written. `review/exact_references/when-to-run.md` still runs `review-fix` on this session's own change at each end point (work finished and committed, after a push, before a merge or deploy), with skip tests only for an existing review, a straight run into `ship` or `land`, and artifact-only work. Risk only picks the reviewer mode (`haiku` for `low`, `opus` otherwise).
