# Agent starting-context audit

- Date: 2026-10-13 (17:59-18:22 UTC)  Sessions: 8be7c9b7 (work repo)  Raw data: none.
- Related: [Reviewer model A/B](2026-10-14-reviewer-model-opus-vs-sonnet.md) (first-request context of every role, a day later), [Agents.md without CLAUDE.md probe](2026-10-15-agents-md-without-claude-md.md), [Output-style rules](../changes/2026-10-12-output-style-rules.md) (sub-agents skip CLAUDE.md with `omitClaudeMd`)

## Question
How many tokens does each agent start with, and what can be trimmed?

## Setup
1. First call input tokens read from sub-agent transcripts of the last 14 days ("Start" is total input on the first call).
2. 11 agents run with a trivial prompt in this session, first-call input tokens read from their transcripts.
3. Re-measured in a new session after setting `omitClaudeMd: true` on `worker` and `manual-tester`.

## Results
- Transcript medians, runs in last 14 days: explorer 4.2k (15 runs, haiku), reviewer 5.8k (208), deep-review 5.8k (22, opus), manual-tester 6.9k (5), consult 13.3k (3), hard-review 13.5k (7, no longer a current agent), worker 14.8k (153), general-purpose 22.7k (2), claude-code-guide 23.6k (13), cheap 30.7k (11; latest run 5.2k, cause not found), claude 47.1k (1, opus), tester no runs.
- Fresh test runs: 5 agents above 10k (claude-code-guide, claude about 47k, general-purpose, worker 14.2k, manual-tester 11.8k); cheap about 30k.
- Biggest item: instruction files (global `CLAUDE.md` about 1.2k tokens, `AGENTS.md` about 1.4k, `AGENTS_PROJECT.md` about 2.3k), about 5k in repos with `AGENTS.md`/`AGENTS_PROJECT.md` and about 1.2k otherwise. Not the MCP tool names: the assistant corrected an early claim; only names load at start.
- Breakdown (estimated from character counts): worker 14.2k = base 4.5k + instruction files 5k + extra tools 2.8k + skills list 0.9k + deferred tool names 1k. Reviewer 5.3k is lean because `omitClaudeMd` is on.
- After the change, in a new session: manual-tester 11,803 to 4,746 (-7.1k, 60%); worker 14,238 to 6,661 (-7.6k, 53%). Both beat the estimates of about 6.5k and 9k. The skills list still costs worker about 0.9k, kept because worker needs `code-standards`.
- Agent definition files are small: 0.9-1.8 KB each, about 250-450 tokens.

## Validity
- A single measurement per agent.
- The live session cached old agent settings, so the effect showed only in new sessions; the "before" numbers came from the earlier runs in the same session.
- Part sizes are character-count estimates that add up to the measured totals.
- `claude`, `general-purpose` and `claude-code-guide` are built in, so they cannot be reconfigured; the fix is to use named roles.
- Risk accepted: worker no longer sees repo rules on lint, platform support rules or commit format, so each spawn prompt must pass them.

## Decision
Add `omitClaudeMd: true` to `worker` and `manual-tester`. The review found that worker lost its safety rules along with the instruction files and had no scratch-folder rule, so a safety line (no pushes, external posts, credential use or deletion unless the prompt allows) and the scratch rule were added to the role files. Original files were backed up before the edit.

## History
- 2026-10-13 — Audit in 8be7c9b7.
- 2026-10-13 — `16feba2c dx(agents): give worker roles scratch and push rules`: added `omitClaudeMd: true` to `worker.md.tmpl` and `manual-tester.md.tmpl`, the push/external-post rule to `agents/worker.md` and the scratch template to both. (The earlier version of this record called the commit "likely"; its diff shows the match.)
- 2026-10-16 — `88bea57e dx(agents): cut prompt cache rewrites` and `f8736d67 dx(agents): keep waiting subagents warm, hand off after 20 min` touched `omitClaudeMd` in a transient long-worker role (added then removed).
- 2026-10-21 — `f0943031 dx(review): test with a tester before review` deleted the `manual-tester` role file (and its Codex file); `tester.md.tmpl` changed in the same commit.
- Today: `omitClaudeMd: true` is set on cheap, consult, explorer, reviewer, tester and worker in `home/dot_config/exact_agents/exact_agents/*.md.tmpl`. Starting sizes were not re-measured after 2026-10-14.
