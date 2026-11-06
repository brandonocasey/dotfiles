# Haiku delegation probes, Haiku xhigh vs Sonnet

- Date: 2026-10-30  Sessions: c974856b (2026-10-30 04:31-05:56 UTC)  Raw data: scratch deleted by the assistant. 32 headless run transcripts survive as Claude project dirs named `*c974856b*` (aacr-runs and probe runs).
- Related: [review replays vs Opus](2026-10-30-review-replays-vs-opus.md) (continued from this session the same day), [effort trials](2026-11-02-effort-trials.md) (later lowered Haiku roles to medium), [Haiku tester probes](2026-11-03-tester-haiku-vs-sonnet.md), [Not adopted](../changes/not-adopted.md) (benchmarks surveyed)

## Question
Which tasks can go to Haiku to save cost, and where does Haiku break?

## Setup
- The user opened with "are there more tasks we can pass off to haiku? really looking for cost savings" and chose "1-3 on haiku xhigh with probe", then "run all".
- agent-probe, 3 runs per model per task, ground truth by `rg` or planted answers.
- P1: 4 locate/aggregate tasks over skills (12 runs).
- Then 42 runs: tricky usage lists (re-exports, aliases, string-built lookup), log summarizing (planted test names, root cause, misleading early error), instruction compliance, call tracing, seeded-bug review.
- Review ladder L2-L8: up to 12 seeded bugs; 10 subtle security/logic; 4 bugs in about 1,000 lines.
- AACR-Bench pilot: 9 PRs, 18 reviews, blind Opus judge, Opus baseline added (the user asked "is there a benchmark for this?" and "run opus").

## Results
- P1: Haiku found every expected file in 12/12 runs, Sonnet too. Cost Haiku $0.021 vs Sonnet $0.304 (about 14x).
- The 42 runs: usage lists 3/3 vs 3/3. Log summaries 3/3 vs 3/3. Call tracing 3/3 vs 3/3. Seeded-bug review 3/3 bugs in all runs on both (Sonnet 2 extra "no rollback" notes).
- Instruction compliance was inconclusive: 6/6 clean on don't-edit and short-reply. The owned-folder task was blocked by permissions. Haiku finished 1 of 3, Sonnet 3 of 3.
- Across the 42 runs Haiku cost $0.051 vs Sonnet $0.779 (about 15x).
- Review ladder L2-L8 (21 runs per model): no recall gap. Subtle: 10/10 Haiku x3, Sonnet 10/10 x2 and 9/10 (scorer line mismatch). Buried 4/4 both. Cost $0.020 vs $0.306.
- AACR pilot (28 reference comments): Haiku 4 matched ($0.19, 23 findings), Sonnet 3 ($0.58, 16 findings), Opus xhigh 2 ($2.20, 17 findings).
- Haiku used about 3x more turns than Sonnet at xhigh.

## Validity
- Planted-bug fixtures cannot find Haiku's limit. The assistant said: textbook bugs, no hidden context, bug-hunt prompt, lenient self-written scoring, scorer loosened mid-run. The user asked "are the planted bugs the issue?".
- The first probe was an easy text match.
- The compliance probe loaded global rules that the real `cheap` role omits.
- The AACR benchmark could not separate the three models (all near floor): 9 PRs, 1 run each, unchecked judge.
- Benchmarks surveyed are listed in [Not adopted](../changes/not-adopted.md).

## Decision
- Usage lists and file finds go to `cheap`. Explorer moved to Haiku xhigh.
- `cheap` does first-pass failure triage (worker diagnoses).
- Workflows pass `claude-haiku-5-5` explicitly.
- Haiku routes added to the CI-server skill, ticket, session-resume, write-docs and llm-setup-audit.
- Reviewer unchanged. The nested sub-agents ban was kept (option 1; the user asked "should we let agents spawn sub agents cheaper than them?" and "whats the risk?", then chose 1).

## History
- 2026-10-14 — `61727b38 dx(claude): set per-model effort, cheap at xhigh`. Earlier baseline: cheap on Haiku at xhigh, explorer on Sonnet medium.
- 2026-10-30 — Probes run in session c974856b.
- 2026-10-30 13:29 — `8eac3c48 dx(skills): stop pinning sonnet in four skills`. A pinned model switches the session model and rewrites the prompt cache. Four skills (disk-cleanup, issue-tracker versions, land, worktree-cleanup) lost their Sonnet pin.
- 2026-10-30 13:43 — `9a476e31 dx(skills): hand more read-only work to haiku agents`. Explorer from Sonnet medium to Haiku xhigh. `cheap` triage routing, a "confirm with one broader `rg`" step for explorer lists, `claude-haiku-5-5` for workflow `cheap` and `explorer` agents, and cheap-agent steps in the CI-server skill, ticket, session-resume, write-docs and llm-setup-audit. The `roles.md` lines "explorer matched Sonnet on usage lists and call traces" and "Haiku matched Sonnet on log triage" start here.
- 2026-10-30 13:49 — `fe308270 dx(skills): keep audit skill under size limit, fix replay count`. Housekeeping after the replay count changed (the review replay, see that test).
- 2026-11-02 — `750e9971 dx(agents): lower haiku roles to medium effort`. Explorer and cheap dropped from xhigh to medium after a 20-of-20 trial (see effort trials).
- Today: `explorer` and `cheap` are `claude-haiku-5-5`, effort `medium`. `roles.md` keeps the triage line and "Probe: Haiku matched Sonnet on log triage". `workflows.md` still says "For `cheap` and `explorer` agents always pass `claude-haiku-5-5`". `sub-agents/SKILL.md`: "Sub-agents never spawn sub-agents." The Haiku routes in the CI-server skill, ticket, session-resume and write-docs are present.
