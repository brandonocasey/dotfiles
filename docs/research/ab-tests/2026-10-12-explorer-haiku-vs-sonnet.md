# Explorer routing: Haiku vs Sonnet on 5 search tasks

- Date: 2026-10-12 (15:55-16:12 UTC)  Sessions: f3be5936 (borg repo; the tasks ran in web-player)  Raw data: none.
- Related: [Haiku delegation probes](2026-10-30-haiku-delegation-probes.md) (later superseded the explorer routing), [Effort trials](2026-11-02-effort-trials.md)

## Question
Can searches move from Sonnet to Haiku?

## Setup
5 tasks of rising difficulty in web-player: usage listing, config lookup, test selection, ad-loading trace, `play()` trace. One Haiku and one Sonnet agent each (10 agents), graded by the assistant against its own exact answers.

## Results
Per task (Haiku vs Sonnet; Haiku cost as a share of Sonnet, estimated from each agent's reported token count at list prices):
- Config default: Haiku correct and more complete; Sonnet correct but cited one wrong line (238 vs 244). About 55%.
- List all usages of an event: both found all 10 files (Haiku also flagged a borderline 11th). About 37%.
- Trace `play()` to the video element: Haiku missed the first hop (the public API wrapper that also blocks play in the free edition); Sonnet complete. About 75%, and 2.4x slower.
- Trace how VAST ads load: Haiku gave exact lines but missed that some builds bundle the ad code; Sonnet complete with a few line numbers off. About 57%.
- Pick tests for a changed file: Haiku missed one test folder; Sonnet found it but made up the import line it cited. About 45%.
- On hard traces Haiku made 2-3x more tool calls, so the savings shrank. Sonnet invented one fact; Haiku invented none.
- Correction to the earlier record: it said no per-arm cost figures were reported and called Haiku test selection "strong". The session's final table gave the cost estimates above and said Haiku missed one test folder.

## Validity
n=1 per cell, self-graded. Costs are estimates; unverified whether the token count includes cached input. The assistant also estimated that checking Haiku's key claims in the main session costs about as much as one or two Haiku runs (unverified), and that Opus agents would still need checking.

## Decision
Usage lists and test selection (when only picking tests) go to Haiku; tracing and test work that mixes selection with reading failures stay on Sonnet. A new line says to check only the claims acted on from any Haiku run, in one batched command. Codex unchanged. Later superseded by the Oct 30 Haiku delegation probes, which moved the explorer to Haiku.

## History
- 2026-10-12 — Test and rule change in f3be5936.
- 2026-10-12 — `047c756c Update .config/agents/skills/sub-agents/references/roles.md Add .config/agents/skills/frontend-design/.keep Update .config/agents/AGENTS.md` (auto-commit from `chezmoi re-add`; the message is the tool's): roles table "explorer ... sonnet, medium; pass `model: haiku` for usage lists" and tester "pass `model: haiku` for test selection only", plus "Verify the key claims of any `haiku` run before acting on them" and a main-session delegation rule in `AGENTS.md`. It also added an empty `frontend-design/.keep` placeholder the assistant had flagged.
- 2026-10-13 — `5ff57cb2 Update .chezmoitemplates/agents/cheap.md Update .chezmoitemplates/agents/consult.md ...` (auto-commit): the explorer role file pinned to `claude-sonnet-5-5`.
- 2026-10-30 — `9a476e31 dx(skills): hand more read-only work to haiku agents`: explorer role changed from `claude-sonnet-5-5` medium to `claude-haiku-5-5` xhigh.
- 2026-11-02 — `750e9971 dx(agents): lower haiku roles to medium effort` (body: "Trial: medium matched xhigh on 20 of 20 cheap and explorer tasks and ran 40% faster (6.6 s vs 11.1 s)."): explorer now Haiku at medium.
- Today: `explorer.md.tmpl` has `model: claude-haiku-5-5`, `effort: medium`.
