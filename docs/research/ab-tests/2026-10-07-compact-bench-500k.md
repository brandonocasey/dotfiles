# compact-bench: auto-compact at 500k vs default

- Date: 2026-10-07  Sessions: 990ee95c; reviewer sub-sessions a51e3f2c and 12f4279c  Raw data: deleted (2 `compact-bench` run transcript dirs survive as Claude project data)

## Question
`autoCompactWindow` at 500k vs the default (about 1M) on cost, time and quality for a large migration.

## Setup
3 rounds, 2 headless Opus 5.5 1M sessions per round (500k window vs default), in isolated copies of a work repo, with a macOS sandbox hiding the other arm.
- R1: convert one source folder (27 files).
- R2: convert all folders under the source tree (88 files).
- R3: the same 88 files with helper agents and workflows disabled.

Scored by tsc, lint, build, unit tests, a count of `any`/ts-ignore/`!`/`as unknown as`, and blind reviewers (R3 only). n=1 per arm per round.

## Results
500k vs default:

| Round | Peak context | Compactions | Cost | Time | Checks |
|---|---|---|---|---|---|
| R1 | 255k vs 304k | 0 vs 0 | $8.92 vs $12.94 | 21 vs 26 min | all pass, 27/27 files |
| R2 | 200k vs 241k (main) | 0 vs 0 | $23.41 vs $21.08 | 33 vs 32 min | full CI lint pass vs fail (type error in one package) |
| R3 (agents off) | 466k then 15k vs 753k | 1 vs 0 | $29.67 vs $34.05 | 68 vs 59 min | build and unit tests pass both (3,361 of 3,365); both fail the same full lint |

- R3 calls: 655 vs 572; file reads 117 vs 94; average context per call 242k vs 407k.
- The 500k setting fired at about 466k.
- R3 `as unknown as` / `!` counts: 12 / 324 (500k) vs 3 / 320 (default).
- Blind review: 2 minor vs 1 minor issues. The extra 500k issue is two broken test pages, which the default session also has; its reviewer did not report it. The legacy-browser-only error path issue is identical in both.
- R3 compaction cost change: -13%; time +15%.
- Total about $135 for 6 sessions, the harness check and 2 reviewers.

## Validity
- R1 and R2 never reached 500k, so they did not exercise compaction.
- R3 is n=1; R1 showed a $4 gap between two non-compacting runs.
- One R2 default session wrote comparison files outside its own copy; its partner never read them.

## Decision
No setting change attributable to this run; later compaction commits are not tied to this test in any transcript.

## Commits
- `77cc26cc dx(agents): compact subagents at 400k tokens`
- `a0a1ba46 dx(claude): auto-compact all sessions at 400k`
- `cb0c8a45 dx(claude): auto-compact at 400k, not 367k` (400000 to 433000)
- `2145d42a dx(claude): trim output and compaction window` (window 200000)
- `ce9f9ea6 dx(claude): keep the 433k compaction window` (window back to 433000)
