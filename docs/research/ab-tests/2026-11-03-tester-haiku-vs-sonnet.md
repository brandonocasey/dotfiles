# Tester on Haiku vs Sonnet probes

- Date: 2026-11-03  Sessions: f4347fce (2026-11-03 22:09-23:05 UTC, web-player)  Raw data: `~/.cache/agents/output/tester-haiku-probe/results.md` survives (probe 2 only; checked with `test -e`). Probe 1 data and the scratch repos are deleted.
- Related: [tester value analysis](2026-11-05-tester-value-analysis.md), [effort trials](2026-11-02-effort-trials.md) (lowered Haiku roles the day before), [Haiku delegation probes](2026-10-30-haiku-delegation-probes.md)

## Question
Can Haiku fill the tester role, including browser checks?

## Setup
- The user asked: "is it possible that haiku could fill the tester role, instead of sonnet?" and then "do an test to see if haiku could do it".
- Probe 1: a small Node repo with 6 planted bugs (5 independent causes) and a false author claim. 2 Sonnet and 2 Haiku tester runs, tester role at high effort, scored against the key.
- Probe 2: a real web-player focus bug on a pre-fix build (worktree `probe-tester-haiku-focus`) with headless browser checks, 2 Sonnet and 2 Haiku. The answer key was the fix's Playwright specs on the pre-fix build: 10 failed, 11 passed, all 10 from one cause (custom or French labels).

## Results
- Probe 1: all 4 runs found all 6 bugs and rejected the author's claim. Sonnet used about 13k tokens (13.5k, 13.3k; about 34 s). Haiku used 27-31k tokens (27.5k; about 68 s).
- Probe 2: main bug found by Sonnet 2 of 2 and Haiku 2 of 2 (settings-menu.js:529 and :531). Author's claim rejected and unit-test gap named in 4 of 4.
- False positives: Sonnet-1 (API-opened Share should refocus Share; the fix's own spec expects the gear) and Haiku-2 (instant-Escape race, self-marked unverified).
- Extra likely-true finds: Haiku-1 (old-browser ariaLabel fallback, unverified on a real old TV) and Haiku-2 (captions-only focus loss to the page body).
- Tokens: Sonnet 83k and 140k, Haiku 150k and 178k. Time: Sonnet 8.6 and 9.9 min, Haiku 9.0 and 11.1 min.
- Rule breaks: Sonnet-1 left 4 polling loops running, Haiku-1 left part of its test matrix unfinished.
- Haiku used about 1.3-2x the tokens.

## Validity
- Both Haiku runs used the role's high effort. The user remarked "we probably should have used haiku at xhigh, but let's see the results first". The assistant judged xhigh unneeded since Haiku already matched at high.
- n=2 per arm.
- Probe 1 was a small task with planted bugs. The probe 2 key came from the real fix's specs.
- Haiku ran the real browser checks, but the bug was localized to one cause.

## Decision
The tester role runs on Haiku (high effort) for all testing, including browser checks. The user's last turn was "sync those too", which led to the commit below.

## History
- 2026-10-21 — `f0943031 dx(review): test with a tester before review`. The tester role (Sonnet) was added to the review flow.
- 2026-10-30 — `d3d2dfb9 dx(agents): raise worker and tester effort, consult on opus`. Tester set to Sonnet high by user instruction (no test).
- 2026-11-03 — Probes run in session f4347fce.
- 2026-11-03 — `23539612 dx(agents): run tester on haiku after probes`. Changes `tester.md.tmpl` from `claude-sonnet-5-5` to `claude-haiku-5-5` and adds the probe numbers to `roles.md`.
- Today: `home/dot_config/exact_agents/exact_agents/tester.md.tmpl` has `model: claude-haiku-5-5`, `effort: high`. `roles.md` still cites "on a 3-file Node change both models found 6 of 6 planted bugs; on a localized focus-return bug ... both found it in 2 of 2 runs; Haiku used about 1.3-2x the tokens". No later commit changed the tester model. The Codex tester (`gpt-6.1-sol`, high) was not part of this probe.
