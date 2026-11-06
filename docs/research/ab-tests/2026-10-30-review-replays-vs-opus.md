# Haiku and Sonnet review replays against Opus and verified findings

- Date: 2026-10-30  Sessions: 80b76ea2  Raw data: review store `~/.local/state/agents/reviews` exists; `~/.cache/agents/output/haiku-review-replay/` deleted; 21 headless replay run transcripts survive as Claude project dirs named `*80b76ea2*replay*`

## Question
Findings matched, verified and cost for Haiku xhigh and Sonnet (medium, xhigh) reviewing low and medium changes, against stored Opus xhigh findings.

## Setup
- Replay of past stored reviews (`~/.local/state/agents/reviews`: 41 full reviews, 32 with verified fixed findings, 137 verified and 10 killed). Every stored reviewer run was Opus xhigh.
- Replay 1: 21 mixed changes, 86 labeled fixed findings.
- Low-tier replay: 12 docs/test commits (8 docs-only, 4 test-only) against Opus findings.
- Sonnet rerun at xhigh on all cases (the first runs used medium by mistake).
- Medium replay: 6 commits of 81-296 lines.
- Sonnet judged matches; Sonnet at high verified extras.

## Results
- Replay 1 (Haiku xhigh vs Sonnet medium): all 86 findings 13 (15%) vs 8 (9%); medium/high 0 of 16 vs 2 of 16; cost $2.00 vs $3.28. After dropping an invalid working-tree case: 76 findings 13 (17%) vs 8 (11%), medium/high 0 of 14 vs 2 of 14.
- Low tier (51 Opus findings, 26 medium/high): Haiku 29 (17 medium/high) $0.52; Sonnet medium 18 (13) $1.44; Opus $6.27.
- Sonnet xhigh rerun (mixed 18 cases / 68 findings; low 12 / 51), Haiku / Sonnet medium / Sonnet xhigh:

| Set | Haiku | Sonnet medium | Sonnet xhigh |
|---|---|---|---|
| Mixed, all | 11 | 8 | 16 |
| Mixed, medium/high (13) | 0 | 2 | 3 |
| Low, all | 29 | 18 | 30 |
| Low, medium/high (26) | 17 | 13 | 19 |

- Sonnet xhigh low tier cost $3.32, about 2x medium. Rerun total $11.20 (cap $9).
- Verification: of Haiku's 28 unmatched low-tier findings Sonnet confirmed 14, rejected 11, 3 unclear ($0.95). Haiku valid 43 of 55 (78%) vs Sonnet xhigh about 35 of 42 (85%). Review cost $0.52 vs $3.32.
- Medium (6 commits, 17 Opus findings, 11 medium): Haiku 7 (6 medium) $0.35, 15 of 19 valid; Sonnet xhigh 10 (9 medium) $2.10, 14 of 15 valid; Opus $4.09.
- Session total about $37.

## Validity
- Labels are circular: Opus findings, unverified in the low and medium replays.
- Replay 1 had 13-16 medium/high findings.
- One run each. Sonnet's first run was at the wrong effort.
- Spend overran estimates ($27-37 vs $5-15).
- One invalid low-tier working-tree case.
- Replay 1 and the medium replay conflict for Sonnet (3 of 13 vs 9 of 11 medium).

## Decision
- Low tier to Haiku xhigh; inline mode removed.
- Sonnet review mode removed: medium and up go to Opus xhigh; Sonnet xhigh kept for fresh fix checks only.
- Worker and tester raised to Sonnet high and consult to Opus xhigh (set directly, not from this test).

## Commits
- `23662f0c dx(review): use sonnet for low-risk and fix checks` (setup replayed)
- `10da7d14 dx(skills): review low-tier changes with haiku`
- `fe308270 dx(skills): keep audit skill under size limit, fix replay count`
- `212863cd dx(skills): drop inline review mode, send low tier to haiku`
- `fd673112 dx(skills): review medium changes with opus, keep sonnet for fix checks`
- `d3d2dfb9 dx(agents): raise worker and tester effort, consult on opus`
- `23539612 dx(agents): run tester on haiku after probes`
