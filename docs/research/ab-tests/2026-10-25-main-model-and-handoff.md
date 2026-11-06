# Main-session model and effort, and handoff A/B

- Date: 2026-10-25  Sessions: da2716d2  Raw data: 102 headless run transcripts survive as Claude project dirs named `*main-model-ab*`; no results file found in `~/.cache/agents/output/`

## Question
Cost, hidden-test score and review rate for Sonnet (medium, high) and Opus (low, medium, high, xhigh) as the main session, and handoff to a background session vs inline.

## Setup
- A stock app fixture with a question, a bug fix, a hard 2-bug task (22 hidden tests) and a 22-file feature (40 tests).
- Variants: Sonnet med/high and Opus low/med/high/xhigh.
- Pilot 20 runs, second round 15 hard plus 10 handoff runs.
- Real rules, so the QA tester and the Opus xhigh reviewer ran.
- Cost about $104 (pilot $42, round 2 $62).

## Results
Cost for question / bug fix / hard bug / feature, and how often the full review ran:

| Variant | Question | Bug fix | Hard bug | Feature | Full review ran |
|---|---|---|---|---|---|
| Sonnet med | $0.10 | $0.64 | $0.17 | $1.58 | 2 of 11 |
| Sonnet high | $0.13 | $0.73 | $1.03 | $3.27 | 6 of 8 |
| Opus low | $0.17 | $0.51 | $0.32 | $2.72 | 1 of 8 |
| Opus med | $0.22 | $1.30 | $1.53 | $4.92 | 11 of 11 |
| Opus high | $0.30 | $1.44 | - | $6.97 | 2 of 2 |
| Opus xhigh | $0.41 | $2.12 | $2.52 | $7.66 | 8 of 8 |

- All 54 coding runs passed every hidden test.
- Sonnet med skipped review in 7 of 11 runs, Opus low in 4 of 8. The QA tester was skipped in 3 of 14 pilot runs.
- Handoff vs inline: Opus med $4.92 inline vs $3.31 handoff (-33%). Sonnet med $1.58 vs $2.35 (+49%). All 6 handoffs 40/40.
- The 15-file rule did not fire in 2 free-choice runs (22 files).
- After the rule edit ("count files first"): handed off 3 of 3 feature runs (40/40) and 0 of 3 small fixes.
- A guard-less version nested handoffs (3-21 nested sessions, $6.66 outlier, 51 min) and was reverted.
- With the guard (`AGENT_HANDOFF=1` blocks `claude -p`): 4 of 4 live runs handed off exactly once.

## Validity
- The first hard task leaked both bugs in a commit message; rebuilt, and only rebuilt runs count.
- No task separated models on quality (all hidden tests passed).
- 5 of 6 handoff costs are estimates (transcript pricing x1.25).
- Question and bug-fix cells are n=1.
- Some background sessions hit the usage limit.

## Decision
Opus medium as the main session. Handoff rule changed to count files early. Nested handoff sessions blocked. Handoff sessions record review.

## Commits
- `62f15c64 dx(agents): count files early so handoff fires`
- `1d31fa4c revert(agents): undo handoff rule that nests`
- `1aa4319c dx(agents): block nested handoff sessions`
- `65e51bcb dx(agents): count files early so handoff fires`
- `2e2e177a test(agents): cover a backgrounded nested handoff`
- `3985f4bd fix(agents): make handoff sessions record review`
- `b8a3a6ab fix(agents): catch more headless flag forms`
- `e4a6c07c dx(agents): stop loops on no progress, richer handoff`
- `d33b4b01 fix(agents): stop handoff killing its reviewer`
