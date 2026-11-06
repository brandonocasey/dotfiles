# Tester on Haiku vs Sonnet probes

- Date: 2026-11-03  Sessions: f4347fce  Raw data: `~/.cache/agents/output/tester-haiku-probe/results.md` (probe 2 only); probe 1 data and scratch repos deleted

## Question
Haiku vs Sonnet in the tester role at high effort: planted bugs found, false claims rejected, tokens and time, including browser checks.

## Setup
- Probe 1: a small Node repo with 6 planted bugs (5 independent causes) and a false author claim. 2 Sonnet and 2 Haiku tester runs, tester role at high effort, scored against the key.
- Probe 2: a real UI focus bug in a work repo on a pre-fix build (a probe worktree) with headless browser checks, 2 Sonnet and 2 Haiku. Answer key: the fix's browser specs run on the pre-fix build (10 failed, 11 passed, all 10 from one cause, a label-handling case).

## Results
- Probe 1: all 4 runs found all 6 bugs and rejected the author's claim. Sonnet about 13k tokens (13.5k, 13.3k; about 34 s). Haiku 27-31k tokens (27.5k; about 68 s).
- Probe 2: main bug found by Sonnet 2 of 2 and Haiku 2 of 2 (two adjacent lines of one file). Author's claim rejected and unit-test gap named in 4 of 4.
- Tokens: Sonnet 83k and 140k, Haiku 150k and 178k. Time: Sonnet 8.6 and 9.9 min, Haiku 9.0 and 11.1 min.
- False positives: Sonnet-1 (a focus-return case where the fix's own spec expects a different control), Haiku-2 (a fast-keypress race, self-marked unverified).
- Extra likely-true finds: Haiku-1 (a legacy-browser fallback, unverified on a real legacy device), Haiku-2 (a focus-loss edge case).
- Rule breaks: Sonnet-1 left 4 polling loops running; Haiku-1 left part of its test matrix unfinished.
- Haiku used about 1.3-2x the tokens.

## Validity
- Both Haiku runs used the role's high effort (xhigh not tested).
- n=2 per arm.
- Probe 1 was a small task with planted bugs; probe 2's bug was localized to one cause.

## Decision
The tester role runs on Haiku (high effort) for all testing, including browser checks.

## Commits
- `f0943031 dx(review): test with a tester before review` (tester role on Sonnet)
- `d3d2dfb9 dx(agents): raise worker and tester effort, consult on opus`
- `23539612 dx(agents): run tester on haiku after probes`
