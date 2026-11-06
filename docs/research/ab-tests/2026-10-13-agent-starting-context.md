# Agent starting context: first-call input tokens, with and without `omitClaudeMd`

- Date: 2026-10-13  Sessions: 8be7c9b7  Raw data: none

## Question
First-call input tokens per agent role, and the change in tokens for `worker` and `manual-tester` with `omitClaudeMd: true` vs without.

## Setup
1. First-call input tokens (total input on the first call) read from sub-agent transcripts of the last 14 days.
2. 11 agents run with a trivial prompt in one session; first-call input tokens read from their transcripts.
3. `worker` and `manual-tester` re-measured in a new session after setting `omitClaudeMd: true`.

## Results
- Transcript medians (runs in last 14 days): explorer 4.2k (15 runs, haiku), reviewer 5.8k (208), deep-review 5.8k (22, opus), manual-tester 6.9k (5), consult 13.3k (3), hard-review 13.5k (7), worker 14.8k (153), general-purpose 22.7k (2), claude-code-guide 23.6k (13), cheap 30.7k (11; latest run 5.2k), claude 47.1k (1, opus), tester no runs.
- Fresh test runs: 5 agents above 10k (claude-code-guide, claude about 47k, general-purpose, worker 14.2k, manual-tester 11.8k); cheap about 30k.
- Instruction files: global `CLAUDE.md` about 1.2k tokens, `AGENTS.md` about 1.4k, `AGENTS_PROJECT.md` about 2.3k; about 5k in repos with `AGENTS.md`/`AGENTS_PROJECT.md`, about 1.2k otherwise.
- Estimated breakdown (from character counts): worker 14.2k = base 4.5k + instruction files 5k + extra tools 2.8k + skills list 0.9k + deferred tool names 1k. Reviewer 5.3k with `omitClaudeMd` on.
- With `omitClaudeMd: true`: manual-tester 11,803 to 4,746 (-7.1k, 60%); worker 14,238 to 6,661 (-7.6k, 53%). Estimates were about 6.5k and 9k.
- Skills list still costs worker about 0.9k.
- Agent definition files: 0.9-1.8 KB each, about 250-450 tokens.

## Validity
- One measurement per agent.
- The live session cached old agent settings, so the effect showed only in a new session; "before" numbers came from earlier runs in the original session.
- Part sizes are character-count estimates.
- `claude`, `general-purpose` and `claude-code-guide` are built in and were not configurable.
- With `omitClaudeMd`, worker no longer receives repo rules on lint, platform support or commit format.

## Decision
`omitClaudeMd: true` on `worker` and `manual-tester`; a safety line (no pushes, external posts, credential use or deletion unless the prompt allows) and a scratch-folder rule added to the role files.

## Commits
- `16feba2c dx(agents): give worker roles scratch and push rules`
- `88bea57e dx(agents): cut prompt cache rewrites` (touched `omitClaudeMd` in a transient long-worker role)
- `f8736d67 dx(agents): keep waiting subagents warm, hand off after 20 min` (same)
- `f0943031 dx(review): test with a tester before review` (deleted the `manual-tester` role file)
