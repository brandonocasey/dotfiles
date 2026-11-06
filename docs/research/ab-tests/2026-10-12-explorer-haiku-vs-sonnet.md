# Explorer routing: Haiku vs Sonnet on 5 search tasks

- Date: 2026-10-12  Sessions: f3be5936 (tasks ran in a work repo)  Raw data: none

## Question
Haiku vs Sonnet on 5 search tasks of rising difficulty, on answer correctness and cost.

## Setup
5 tasks in a work repo: usage listing, config lookup, test selection, loading-path trace, public-API call trace. One Haiku and one Sonnet agent each (10 agents), graded against exact answers prepared by the main session. Haiku cost as a share of Sonnet is estimated from each agent's reported token count at list prices.

## Results
| Task | Haiku | Sonnet | Haiku cost vs Sonnet |
|---|---|---|---|
| Config default | correct, more complete | correct; cited one wrong line (238 vs 244) | about 55% |
| List all usages of an event | all 10 files (also flagged a borderline 11th) | all 10 files | about 37% |
| Trace a public API call to the underlying element | missed the first hop (the public API wrapper that also gates the call in a restricted edition) | complete | about 75%, 2.4x slower |
| Trace a loading path | exact lines; missed that some builds bundle that code | complete; a few line numbers off | about 57% |
| Pick tests for a changed file | missed one test folder | found it; made up the import line it cited | about 45% |

- On hard traces Haiku made 2-3x more tool calls.
- Sonnet invented one fact; Haiku invented none.

## Validity
- n=1 per cell, graded against the main session's own answers.
- Costs are estimates; unverified whether the token count includes cached input.

## Decision
Usage lists and test selection (when only picking tests) go to Haiku; tracing and test work that mixes selection with reading failures stay on Sonnet. A rule added to check only the claims acted on from any Haiku run, in one batched command. Codex unchanged. Superseded by [Haiku delegation probes](2026-10-30-haiku-delegation-probes.md).

## Commits
- `047c756c Update .config/agents/skills/sub-agents/references/roles.md Add .config/agents/skills/frontend-design/.keep Update .config/agents/AGENTS.md` (auto-commit from `chezmoi re-add`)
- `5ff57cb2 Update .chezmoitemplates/agents/cheap.md Update .chezmoitemplates/agents/consult.md ...` (auto-commit; explorer role file pinned to `claude-sonnet-5-5`)
- `9a476e31 dx(skills): hand more read-only work to haiku agents` (explorer to Haiku xhigh)
- `750e9971 dx(agents): lower haiku roles to medium effort` (explorer Haiku at medium)
