# Haiku delegation probes, Haiku xhigh vs Sonnet

- Date: 2026-10-30  Sessions: c974856b  Raw data: scratch deleted; 32 headless run transcripts survive as Claude project dirs named `*c974856b*` (benchmark-pilot runs and probe runs)

## Question
Haiku xhigh vs Sonnet on recall and cost across delegated read-only tasks (searches, log summaries, tracing, seeded-bug review).

## Setup
- agent-probe, 3 runs per model per task, ground truth by `rg` or planted answers.
- P1: 4 locate/aggregate tasks over skills (12 runs).
- 42 runs: tricky usage lists (re-exports, aliases, string-built lookup), log summarizing (planted test names, root cause, misleading early error), instruction compliance, call tracing, seeded-bug review.
- Review ladder L2-L8: up to 12 seeded bugs; 10 subtle security/logic; 4 bugs in about 1,000 lines.
- Public code-review benchmark pilot: 9 PRs, 18 reviews, blind Opus judge, Opus baseline added.

## Results
- P1: Haiku found every expected file in 12/12 runs, Sonnet too. Cost Haiku $0.021 vs Sonnet $0.304 (about 14x).
- The 42 runs: usage lists 3/3 vs 3/3; log summaries 3/3 vs 3/3; call tracing 3/3 vs 3/3; seeded-bug review 3/3 bugs in all runs on both (Sonnet 2 extra "no rollback" notes).
- Instruction compliance inconclusive: 6/6 clean on don't-edit and short-reply. The owned-folder task was blocked by permissions; Haiku finished 1 of 3, Sonnet 3 of 3.
- Across the 42 runs Haiku cost $0.051 vs Sonnet $0.779 (about 15x).
- Review ladder L2-L8 (21 runs per model): subtle 10/10 Haiku x3, Sonnet 10/10 x2 and 9/10 (scorer line mismatch); buried 4/4 both. Cost $0.020 vs $0.306.
- Benchmark pilot (28 reference comments): Haiku 4 matched ($0.19, 23 findings), Sonnet 3 ($0.58, 16 findings), Opus xhigh 2 ($2.20, 17 findings).
- Haiku used about 3x more turns than Sonnet at xhigh.

## Validity
- Planted-bug fixtures: textbook bugs, no hidden context, bug-hunt prompt, self-written scoring, scorer loosened mid-run.
- The first probe was an easy text match.
- The compliance probe loaded global rules that the real `cheap` role omits.
- The benchmark pilot did not separate the three models (9 PRs, 1 run each, unchecked judge).

## Decision
- Usage lists and file finds go to `cheap`; explorer moved to Haiku xhigh.
- `cheap` does first-pass failure triage.
- Workflows pass `claude-haiku-5-5` explicitly.
- Haiku routes added to the CI-server skill, ticket, session-resume, write-docs and llm-setup-audit.
- Reviewer unchanged; sub-agents still may not spawn sub-agents.

## Commits
- `61727b38 dx(claude): set per-model effort, cheap at xhigh` (baseline)
- `8eac3c48 dx(skills): stop pinning sonnet in four skills`
- `9a476e31 dx(skills): hand more read-only work to haiku agents`
- `fe308270 dx(skills): keep audit skill under size limit, fix replay count`
- `750e9971 dx(agents): lower haiku roles to medium effort`
