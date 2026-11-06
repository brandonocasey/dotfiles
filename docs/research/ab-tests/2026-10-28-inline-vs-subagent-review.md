# Inline review vs sub-agent review: toy rounds and a real-bug round

- Date: 2026-10-28  Sessions: e93ffbb5 (R1-R3), 2a73f606 (verification and R4)  Raw data: answer keys at `~/.local/state/agents/answer-keys/review-inline-ab4/keys-real/r01..r25.json`; 87 headless run transcripts survive as Claude project dirs named `*review-inline-ab*`; `results.md` deleted

## Question
Review by a reviewer sub-agent (`today`) vs inline review in the main session (one appended rule): bugs caught, cost and time.

## Setup
- Variants: `today` (reviewer and tester sub-agents) vs `inline`, through agent-probe.
- R1: small CSV task, 5 runs per arm, 49 hidden cases.
- R2: same code with 11 planted bugs, 6 runs per arm.
- R3: semver-range task graded on 2,726 generated cases, 6 runs per arm.
- R4: 7 hard real-bug cases (r10, r11, r12, r13, r14, r20, r25 of the 25 from the [Oct 14 reviewer A/B](2026-10-14-reviewer-model-opus-vs-sonnet.md)), 1 run per case per arm, blind Opus judge with answer key.

## Results
Sub-agent vs inline:

| Round | Score | Cost per run | Time | Notes |
|---|---|---|---|---|
| R1 | 49/49 in 5/5 both | $2.26 vs $0.79 | 9.0 vs 2.5 min | sub-agent found 1 real bug in 3 of 5 runs, inline in 0; 1 of 5 inline runs shipped a `""` row skip |
| R2 | 11/11 in 6/6 both | $2.43 vs $0.62 | 11.2 vs 2.2 min | |
| R3 | 2,726/2,726 in 6/6 both | $2.34 vs $0.93 | 10.0 vs 3.1 min | low-severity extra bugs: sub-agent 5 across 3 of 6 runs, inline 2 across 2 of 6 |
| R4 | caught 3 (r10, r11, r20) vs 1 (r20) | $2.60 ($1.14-4.29) vs $0.68 ($0.23-1.61) per task | n/a | r12, r13, r14, r25 missed by both; no bug caught by inline only |

## Validity
- R1-R3 ceilinged (perfect scores).
- The inline arm also dropped the tester and used Opus where the sub-agent review used Sonnet fix checks. The sub-agent reviewer was Opus xhigh.
- R2 reviewer saw code it had not written.
- R3 had 9 runs rerun after the spend limit.
- Hidden tests deleted (the R4 keys survive).
- R4 first attempt (v1, 11 runs, about $30) invalid: sessions reworked the draft before committing (9 of 10 first commits differed). Second attempt had only 2 of 7 valid. Third attempt had harness bugs (cloning outside the run dir, sessions ending while helpers ran, the sub-agent arm sometimes skipping the reviewer), fixed and rerun.
- r10 and r25 sub-agent runs skipped the tester. The r25 inline run ended oddly.
- R4 spend about $23 valid plus about $30 invalid.
- n=1 per case in R4.

## Decision
Reviewer sub-agent kept.

## Commits
- `35fb091e dx(review): review every change with opus only` (baseline for the `today` arm)
- `e3ee004f dx(skills): cheaper review modes for small changes` (added an `inline` mode for tiny docs-only changes)
- `212863cd dx(skills): drop inline review mode, send low tier to haiku` (see [review replays vs Opus](2026-10-30-review-replays-vs-opus.md))
