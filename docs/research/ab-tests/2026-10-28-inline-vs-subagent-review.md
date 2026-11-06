# Inline review vs sub-agent review: toy rounds and a real-bug round

- Date: 2026-10-28  Sessions: e93ffbb5 (R1-R3; session spans 2026-10-28 04:54-14:46 UTC, hive), 2a73f606 (verification and R4, 2026-10-28 14:52-21:45 UTC)  Raw data: answer keys at `~/.local/state/agents/answer-keys/review-inline-ab4/keys-real/r01..r25.json` (25 files, checked with `test -e`). 87 headless run transcripts survive as Claude project dirs named `*review-inline-ab*`. `results.md` is deleted.
- Related: [Oct 14 Opus vs Sonnet reviewer](2026-10-14-reviewer-model-opus-vs-sonnet.md) (source of the 25 real-bug cases), [review replays vs Opus](2026-10-30-review-replays-vs-opus.md) (later dropped the inline mode), [global rules vs no rules](2026-10-28-global-rules-vs-none.md), [light vs normal reviewer](../changes/2026-10-14-light-vs-normal-reviewer.md)

## Question
Can the main session review its own diff (inline) instead of using a reviewer sub-agent? The user started with: "i want to ab test doing a review inline and fixing vs not doing a review in line like we do now". After R1 the user said "we need to run more complicated bug tests to verify this". In the second session: "find the inline vs sub agent review ab test and verify that it was conducted correctly. I'm still trying to decide if we need a sub agent or not".

## Setup
- Variants: `today` (reviewer and tester sub-agents) vs `inline` (one appended rule), through agent-probe.
- R1: small CSV task, 5 runs per arm, 49 hidden cases.
- R2: same code with 11 planted bugs, 6 runs per arm.
- R3: semver-range task graded on 2,726 generated cases, 6 runs per arm.
- R4: 7 hard real-bug cases (r10, r11, r12, r13, r14, r20, r25 of the 25 from the Oct 14 reviewer A/B), 1 run per case per arm, blind Opus judge with answer key.

## Results
- R1: both 49/49 in 5/5. Cost $2.26 vs $0.79 per run (sub-agent vs inline). 9.0 vs 2.5 min. The sub-agent found 1 real bug in 3 of 5 runs, inline in 0. 1 of 5 inline runs shipped a `""` row skip.
- R2: 11/11 planted bugs in 6/6 for both. $2.43 vs $0.62. 11.2 vs 2.2 min.
- R3: 2,726/2,726 in 6/6 for both. $2.34 vs $0.93. 10.0 vs 3.1 min. Low-severity extra bugs found: sub-agent 5 across 3 of 6 runs, inline 2 across 2 of 6.
- R4: the sub-agent caught 3 (r10, r11, r20), inline caught 1 (r20). r12, r13, r14, r25 both missed. No bug was caught by inline only. Cost: sub-agent $2.60 per task ($1.14-4.29), inline $0.68 ($0.23-1.61).

## Validity
- R1-R3 ceilinged (perfect scores).
- The inline arm also dropped the tester and used Opus where the sub-agent review used Sonnet fix checks. The first claim that the sub-agent reviewer was Sonnet was wrong; it was Opus xhigh.
- R2 reviewer saw code it had not written.
- R3 had 9 runs rerun after the spend limit.
- Hidden tests and answer keys were deleted (the R4 keys survive, see above).
- R4 first attempt (v1, 11 runs, about $30) was invalid: sessions reworked the draft before committing (9 of 10 first commits differed). The second attempt had only 2 of 7 valid. The third attempt had harness bugs (cloning outside the run dir, sessions ending while helpers ran, the sub-agent arm sometimes skipping the reviewer), which were fixed and rerun.
- r10 and r25 sub-agent runs skipped the tester. The r25 inline run ended oddly.
- R4 spend about $23 valid plus about $30 invalid.
- A process check missed the Python-run probe, so runs continued about 25 min after "stop". Usage-limit stops ("stop for now, need to save some quota", "running low on usage").
- n=1 per case in R4.

## Decision
Keep the reviewer sub-agent ("keep for risky changes"). Doing both inline and sub-agent is not worth +26% (the user asked "would it make sense to do inline and sub agent?").

## History
- 2026-10-14 — `35fb091e dx(review): review every change with opus only`. Review is Opus-only. Baseline for the "today" arm.
- 2026-10-28 — R1-R3 run in session e93ffbb5. R4 and verification in session 2a73f606.
- 2026-10-28 — Commits applying the decision: none found (the sub-agent reviewer was kept, so no change was needed).
- 2026-10-30 00:29 EDT — `e3ee004f dx(skills): cheaper review modes for small changes`. Adds an `inline` mode for tiny docs-only changes. Not verified as caused by this test (session not located).
- 2026-10-30 14:26 EDT — `212863cd dx(skills): drop inline review mode, send low tier to haiku`. Removes inline mode (no reviewer, no tester, report marked "inline review: not independent") after the Haiku replay. See [review replays vs Opus](2026-10-30-review-replays-vs-opus.md).
- Today: no inline review mode. `review/references/setup.md` has modes `haiku` (tier `low`) and `opus` (everything else). `reviewer-steps.md` is read "only for an inline fallback" when no sub-agent tool exists, and `roles.md` says "Without a sub-agent tool, work inline and identify any review that is not independent."
