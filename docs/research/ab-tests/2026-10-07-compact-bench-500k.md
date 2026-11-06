# compact-bench: auto-compact at 500k vs default

- Date: 2026-10-07 (17:21-21:57 UTC)  Sessions: 990ee95c; reviewer sub-sessions a51e3f2c and 12f4279c  Raw data: scratch dir `~/.cache/agents/scratch/compact-bench/` was deleted at the user's request (13 GB; `test -e` fails). 2 `compact-bench` run transcript dirs still survive as Claude project data (the session recorded 7 at the time; Claude Code deletes them after 30 days by default; the earlier record said 6).
- Related: [Auto-compact at 400k](../changes/2026-10-14-auto-compact-400k.md), [Auto-compact at 500k: the question](../changes/2026-10-07-auto-compact-500k-question.md), [Deep vs normal reviewer](2026-10-08-deep-vs-normal-reviewer.md) (used these repos)

## Question
Does `autoCompactWindow` at 500k change cost, time or quality on a big migration? The user had asked whether compacting at 500k instead of about 1M would be worth it; the assistant first estimated a saving of roughly $10-15 (about 20%) for a very long session and none for sessions that never reach 500k.

## Setup
3 rounds, 2 headless Opus 5.5 1M sessions per round (500k window vs default), in isolated copies of web-player, with a macOS sandbox hiding the other arm.
- R1: convert `src/js/related/` (27 files).
- R2: convert all folders under `src/js/` (88 files).
- R3: the same 88 files with helper agents and workflows disabled.

Scored by tsc, lint, build, unit tests, a count of `any`/ts-ignore/`!`/`as unknown as`, and blind reviewers (R3 only). n=1 per arm per round.

## Results
500k vs default:
- R1: peak context 255k vs 304k, 0 compactions both, $8.92 vs $12.94, 21 vs 26 min, all checks pass, 27/27 files.
- R2: peak main context 200k vs 241k, 0 compactions, $23.41 vs $21.08, 33 vs 32 min. Full CI lint passed vs failed (a type error in `packages/jwplayer`; run-to-run variation, not compaction).
- R3 (agents off): 500k compacted once at 466k down to 15k, $29.67, 68 min, 655 calls, 117 file-reads, average context per call 242k. Default peaked at 753k with 0 compactions, $34.05, 59 min, 572 calls, 94 reads, average context 407k. The 500k setting fires early (about 466k) because Claude Code leaves a buffer.
- R3 checks: build and unit tests pass for both (3,361 of 3,365); both fail the same full lint (`packages/jwplayer` type check). `as unknown as` / `!` counts: 12 / 324 (500k) vs 3 / 320 (default).
- Blind review: 2 minor vs 1 minor issues. The extra 500k issue is two broken test pages, which the default session also has; its reviewer did not report it. The IE-only error path issue is identical in both.
- Total about $135 for 6 sessions, the harness check and 2 reviewers. Compaction cut cost 13% but the session took 15% longer (more calls and file re-reads after compacting). Quality about equal.

## Validity
- R1 and R2 never reached 500k, so they tested nothing about compaction.
- R3 is n=1, and R1 showed a $4 gap between two non-compacting runs, so the 13% saving "could be noise".
- With normal helper-agent use, main context peaked at 200-304k, so a 500k trigger would rarely fire in the user's setup.
- One R2 default session wrote comparison files outside its own copy; its partner never read them, so results stand.
- The assistant deleted `~/.cache/agents/scratch/rv/` by mistake during cleanup (reviewer scratch, 6 files, 830 KB, partly another task's Jira request log); no backup.

## Decision
No setting change attributable to this run. The assistant concluded a 500k trigger would rarely fire in the user's setup. Later compaction commits set 400k and then 433k and are not tied to this test in any transcript.

## History
- 2026-10-07 — Benchmark run in 990ee95c; scratch dir deleted at the user's request.
- 2026-10-14 — `77cc26cc dx(agents): compact subagents at 400k tokens` and `a0a1ba46 dx(claude): auto-compact all sessions at 400k` (adds `"autoCompactWindow": 400000` to `claude-settings-modify.sh`). Bodies are empty; no transcript ties them to this test (searched `git log --grep=compact` and the transcripts).
- 2026-10-14 — `cb0c8a45 dx(claude): auto-compact at 400k, not 367k`: the diff changes `autoCompactWindow` from 400000 to 433000 (the subject says 400k, not 367k, so the 33k difference is presumably the trigger buffer; not confirmed in a transcript).
- 2026-10-16 — `2145d42a dx(claude): trim output and compaction window`: set the window to 200000. `ce9f9ea6 dx(claude): keep the 433k compaction window` put it back to 433000. Both have empty bodies.
- Today: `claude-settings-modify.sh` sets `"autoCompactWindow": 433000` and `"idleCompaction": true`.
