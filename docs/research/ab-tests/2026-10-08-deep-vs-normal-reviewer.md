# Deep (Opus high) vs normal (Sonnet medium) reviewer, observational

- Date: 2026-10-08 (19:53-19:58 UTC)  Sessions: 12f4279c (web-player)  Raw data: none. The paired reviews came from the compact-bench repos, whose scratch dir was deleted.
- Related: [Review misses and the deep review](../changes/2026-10-13-review-misses-deep-review.md), [Light vs normal reviewer: tier added, then removed](../changes/2026-10-14-light-vs-normal-reviewer.md), [Review experiment: Opus pairs](2026-10-13-review-experiment-opus-pairs.md), [compact-bench](2026-10-07-compact-bench-500k.md) (source of the 4 paired reviews)

## Question
The user asked: "we currently have a rule to run two review agent in parallel, feels wasteful. has it every sucessfully found anything?" and then "can we run the deep reviewer less often? was there times we shouldn't have run it, but did?"

## Setup
Not a new run. The assistant compared the 4 paired reviews (r1-r4) from the compact-bench repos: deep reviewer (Opus 5.5, high effort) against the paired normal reviewer (Sonnet 5.5, medium effort). It also checked each run against the rule's trigger (more than about 400 changed lines of logic).

## Results
Deep reviewer vs normal reviewer, per run:
- r4 (~4,800 lines): deep found a high-severity CI type-check failure in `packages/jwplayer` (fixed afterwards); normal found only small issues.
- r3 (~5,300 lines): deep found a medium issue, two license-key test pages broken (`tea.js` returns 404); normal found nothing in the table.
- r1 (~520 lines): deep found a docs build break on `declare` fields (already being fixed); normal found nothing.
- r2 (~2,800 lines): both found nothing.
- So the deep reviewer found real issues in 3 of 4. Deep reads 5-40x more input tokens and takes 6-12 min vs 1-2 min. r5 and r6 (near 7,000 lines, no deep review because helper agents were off) both missed the page break.
- All 4 runs met the size trigger, so the rule never ran when it should not have; the smallest run (r1) still found a real break.
- Inconsistency in the session's own wording: its table says the normal reviewer found nothing on r3 and only small issues on r4, but its prose says the normal reviewer added "one unique find (r4, the broken test pages)". An earlier version of this record said the normal reviewer found only the r3 page break. The table and the r3 page break (a 404 of two test pages) are the better-supported reading; the prose label is ambiguous.

## Validity
4 runs, one TypeScript migration in benchmark repos, never on real MR work. The session's options: leave the rule as is (recommended), raise the limit to ~1,000 lines (would have skipped r1 and its docs break), or lower the deep reviewer to medium effort (unverified, may miss deeper finds).

## Decision
Keep the deep reviewer on risky changes; no change made then. The assistant also said dropping the paired normal reviewer would save little (about a tenth of the deep reviewer's cost).

## History
- 2026-10-08 — Observation in 12f4279c; no commit (searched the transcript and `git log` around 2026-10-08; none found).
- 2026-10-13 — The review experiment on the claude-marketplace MR ([link](2026-10-13-review-experiment-opus-pairs.md)) found Sonnet pairing added nothing over Opus xhigh. `71ee6bb1 dx(review): use one reviewer and loop every fix` merged deep-review into one reviewer.
- 2026-10-14 — `35fb091e dx(review): review every change with opus only`: the light tier was removed; the paired deep plus normal rule no longer exists.
- Today: one `reviewer` role (Opus xhigh); there is no deep-review or normal-review role in `home/dot_config/exact_agents/exact_agents/`.
