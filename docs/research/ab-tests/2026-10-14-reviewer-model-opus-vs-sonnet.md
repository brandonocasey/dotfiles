# Reviewer model A/B: Opus xhigh vs Sonnet xhigh, with Sonnet max and Opus high

- Date: 2026-10-14  Sessions: bc200b0a (sub-agents of that session built the cases)  Raw data: `~/.local/state/agents/answer-keys/review-inline-ab4/keys-real/r01.json` to `r25.json` (real-bug keys); scratch dir `~/.cache/agents/scratch/review-ab/` deleted, 39 `review-ab` run transcript dirs survive as Claude project data

## Question
Opus xhigh vs Sonnet xhigh (plus Sonnet max and Opus high) as reviewer, on known bugs found per review and cost.

## Setup
Reviewer role runs, graded by a blind Opus grader.
- Pilot: 1 diff with 4 known findings, 3 arms.
- Planted: 10 real commits (8 with 2 planted bugs each, 2 clean controls) plus 1 more diff, 5 rounds.
- Real: 25 bug-introducing commits found by SZZ from 1,158 fix-message commits (62 read, 25 accepted), with the later fix as the answer key, 1 run per case.
- Opus high added later on the same 25 real cases.

## Results
| Test | Opus xhigh | Sonnet xhigh | Other |
|---|---|---|---|
| Pilot (4 findings) | 4/4, $0.82, 2.8 min | 3/4, $0.40, 1.7 min | Sonnet max 4/4, $1.86, 11.1 min (57 turns; wrote 8 empty files into the results dir) |
| Planted, first 44 runs (11 diffs x 2) | 31/40, $0.94, 2.9 min | 32/40, $0.49, 2.8 min | only Opus caught a rule-text contradiction |
| Planted, 5 rounds | 61/68 (89.7%), $0.97 per review, 0 wrong | 63/70 (90.0%), $0.46, 1 wrong | |
| Real bugs (25 cases, 27 bugs) | 24.5/27 (91%), $1.14 per review, $1.16 per bug | 20/27 (74%), $0.61 per review, $0.76 per bug, 1 wrong | Opus high 21.5/27 (80%), $0.55 per review, $0.64 per bug, 1 wrong |

- Real bugs: Opus xhigh caught 4 bugs Sonnet xhigh missed; Sonnet caught 0 that Opus missed. Opus high missed 3 that xhigh caught and caught none xhigh missed.
- By diff size (Sonnet vs Opus): up to 100 lines 8/9 vs 9/9; 101-200 lines 7/8 vs 8/8; over 200 lines 5/10 vs 7.5/10.
- Opus output tokens 9.3k at high vs 21.2k at xhigh; all runs reported claude-opus-5-5.
- Cost: test about $121 plus the Opus-high run; whole study about $152 ($31 + $121 + the Opus-high run).
- Sub-probe, reviewer runs with ToolSearch vs connectors (2 runs per setup): connectors off, no ToolSearch 8,349 tokens per request ($0.067 cold, $0.021 warm); connectors off plus ToolSearch 8,230; ToolSearch plus context-lean with 10 connectors 11,401 ($0.091 cold, $0.047 warm).

## Validity
- Planted bugs were written by Opus; two planted bugs were not bugs.
- Real-bug test ran each case once.
- In 3 cases reviewers looked up the real upstream fix online (2 of them Opus), so it was not fully blind.
- One Opus run's review text was lost.
- Opus-high cost is slightly understated (connectors were off for that run).
- Sonnet medium effort was not tested.

## Decision
Opus xhigh is the only reviewer; the Sonnet light-reviewer tier added the same day was removed. Opus high not adopted. Reviewers run with connectors off.

## Commits
- `13c6a0e2 dx(review): add light-reviewer tier`
- `35fb091e dx(review): review every change with opus only` (body: "A real-bug A/B test caught 91% of bugs with Opus xhigh, 80% with Opus high, and 74% with Sonnet xhigh, so the light Sonnet tier is removed.")
- `57bf3f9a dx(codex): prune removed agent roles on apply`
- `3b98281a dx(codex): align subagent model tiers`
- `345ba6eb dx(agents): compact rules and skill descriptions`
- `027f85c9 dx(review): hand review setup to a haiku helper`
- `23662f0c dx(review): use sonnet for low-risk and fix checks`
- `e3ee004f dx(skills): cheaper review modes for small changes`
- `10da7d14 dx(skills): review low-tier changes with haiku`
- `212863cd dx(skills): drop inline review mode, send low tier to haiku`
- `fd673112 dx(skills): review medium changes with opus, keep sonnet for fix checks`
- `8a029ed0 dx(agents): lower opus reviewer to high effort` (body: "Trial: high found 6 of 11 high/medium bugs against 5 of 10 at xhigh, at half the cost and time.")
- `569767d2 revert(agents): put opus reviewer back at xhigh` (body: "A larger trial on 27 paired changes found 20 of 31 known high/medium bugs at xhigh against 17 at high, so high likely misses about 1 in 10 serious bugs.")
- `d6823e44 dx(agents): keep non-opus reviewers at xhigh` (reverted by `569767d2`)
