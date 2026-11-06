# Concise style A/B: output-style wording and per-turn reminder

- Date: 2026-10-14  Sessions: 6cf86035  Raw data: deleted (`~/.cache/agents/scratch/concise-ab/ab/` removed; 2 `concise-ab` run transcript dirs survive as Claude project data)

## Question
Reply length and facts kept across 5 style variants, and whether a per-turn "be concise" reminder changes length.

## Setup
5 arms x 8 prompts x 3 runs = 120 headless runs, file contents inlined, no tools:
- current style
- current plus a Concise reminder
- merged (current plus 6 rules paraphrased from a third-party style repo) plus the reminder
- third-party "Spartan" style
- built-in Concise

Scored by script (length, fact regex hits, first-line words, "offers more"); no LLM judge. Cost $2.19 for 120 runs.

## Results
| Arm | Median words | Facts kept | Audit-reply words | First-line words |
|---|---|---|---|---|
| current | 77 | 92% | 431 | 28 |
| current + reminder | 85 | 92% | 433 | 28 |
| merged + reminder | 80 | 94% | 362 | 20 |
| Spartan | 111 | 90% | 410 | 16 |
| built-in Concise | 88 | 94% | 400 | 27 |

- Spartan: 2 runs ended offering more. Built-in Concise: 2 offers.
- All arms ignored the 10-row table cap (11-15 of 16 rows).
- After excluding 4 broken runs, median words: current without reminder 75, mixed 79, reminder version 85.
- Mixed won on the security-check reply (335 vs 431 words, 2 valid runs) and the status update (69 vs 91).
- Depth ("really explain") prompts: every version answered at about the same length.

## Validity
- An independent review found 4 method flaws: 3 depth-prompt runs scored valid were cut-off 2-turn runs; 1 run was a raw Write tool call scored as valid; scorer regexes could not see the dropped `/copy` line; 3 runs per cell. 4 broken runs were excluded.
- Single-turn tests only; long chats, tool use and multi-turn reminder effect untested.
- The review found 3 rule conflicts in the merged text, fixed before adoption: the clean-text rule dropped the `Run /copy` line (2 of 2 completed retest runs kept it after the fix; a third stalled and timed out); "blocking question goes last" vs ending on `Next:`; "bold every risk" vs "bold sparingly".
- An early-run 595k-token anomaly was traced to ToolSearch being off (see [ToolSearch-off cost probe](2026-10-14-toolsearch-off-cost.md)).

## Decision
Merged rules (after the three conflict fixes) added, and a per-turn reminder hook: "Be concise: lead with the result, skip preamble and narration, keep only what the user needs." The hook was later removed.

## Commits
- `4f496d8d dx(agents): adopt concise replies and quiet waits` (before the test)
- `43e2978c dx(agents): add concise rules from style a/b test`
- `7819604f dx(claude): repeat concise reminder each prompt`
- `345ba6eb dx(agents): compact rules and skill descriptions`
- `8bbad79d dx(agents): share writing rules with sub-agents`
- `5548fbb0 dx(claude): drop the per-prompt concise reminder`
