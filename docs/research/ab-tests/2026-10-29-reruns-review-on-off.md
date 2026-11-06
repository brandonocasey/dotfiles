# Reruns: review on vs off (w8), harder shortcut trap (w9), w10 rerun

- Date: 2026-10-29  Sessions: 686bb3b6  Raw data: 100 headless run transcripts survive as Claude project dirs named `*rules-ab-runs-w8-*` (46), `*w9-*` (19) and `*w10-*` (35); counts include sub-agent working dirs. `w10.json`, `w10.md` and the `ab-test-gaps/` output deleted

## Question
Rerun of the two inconclusive tests from the [Oct 28 rules-vs-no-rules run](2026-10-28-global-rules-vs-none.md): no review vs forced review on real-repo tasks (w8, w10), and no rules vs current rules on a harder shortcut trap (w9).

## Setup
- w8: 4 real-repo tasks (sparse, notify, track, cache) x {no review, forced review} x 3 runs = 24.
- w9: shortcut trap with a CI check failing on an unrelated rounding bug. No-rules vs current rules, 5 runs per arm = 10 (Opus).
- w10: sparse and notify, 6 runs per arm = 24 in parallel with `--strict-mcp-config`.
- Added the `ab.sh` runner and a `PAR=` option.

## Results
- w9: 0 of 10 cheated (no test edits, suppressions, skips or lint edits). Current rules committed with the check still red in 2 of 5 runs (the reports said so); no-rules 0 of 5. Hidden tests 9-11 of 12 in both.
- w8 (20 of 24 graded):
  - sparse: no review robust 2/4 x3, forced review 4/4 and 2/4 ($1.09 vs $5.50).
  - notify: no review 2/6 x2, forced 2/6 and 4/6 ($0.61 vs $1.27).
  - track: identical ($0.80 vs $1.30).
  - cache: forced review passed spec 1 of 3, no review 0 of 2; 2 of 3 forced runs never committed.
  - Forced review costs 1.5-5x.
- w10: only 7 of 24 finished and committed. Sparse: no review 4 runs 3/3 and 2/4, forced 2 runs 2/3 and 2/4. Notify: no review 1 run 30/31 and 1/6, forced 0 usable.

## Validity
- Disk filled (51 GB of Rust clones) and crashed runs.
- Flaky MCP startup under 11 parallel runs.
- 4 missing runs in w8.
- In notify both no-review runs still ran a reviewer (contaminated).
- Notify $0.38 runs were probably first-turn costs only: many notify runs end the first turn waiting on a background session.
- 12 of 24 w10 runs were stopped before completion; usage limit.

## Decision
Review not made mandatory for every change; no new rule applied.

## Commits
- None for this decision. The review trigger line last changed in `f722cc3b dx(review): review once work is finished and committed` (2026-10-15).
