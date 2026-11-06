# Concise style A/B: output-style wording and per-turn reminder

- Date: 2026-10-14 (00:21-03:34 UTC; commits are dated 2026-10-13 local)  Sessions: 6cf86035  Raw data: `~/.cache/agents/scratch/concise-ab/ab/` is deleted (`test -e` fails). 2 `concise-ab` run transcript dirs survive as Claude project data.
- Related: [Output-style rules](../changes/2026-10-12-output-style-rules.md), [Copy output](../changes/2026-10-13-copy-output.md), [ToolSearch-off cost probe](2026-10-14-toolsearch-off-cost.md) (explains the 595k-token anomaly in the early runs)

## Question
Which style variant gives the shortest replies without losing facts, and does a per-turn "be concise" reminder help? The user also asked "does output style normally have per turn reminder?" and "use the exact concise reminder, does it cost tokens?" (session 6cf86035, 2026-10-14 01:45 UTC).

## Setup
5 arms x 8 prompts x 3 runs = 120 headless runs, with file contents inlined and no tools:
- current style
- current plus a Concise reminder
- merged (current plus 6 rules paraphrased from the attention-span repo) plus the reminder
- attention-span "Spartan"
- built-in Concise

Scored by script (length, fact regex hits, first-line words, "offers more"), no LLM judge. Cost $2.19 for 120 runs.

## Results
Median words / facts kept / audit-reply words / first-line words:
- current: 77 / 92% / 431 / 28
- current + reminder: 85 / 92% / 433 / 28
- merged + reminder: 80 / 94% / 362 / 20
- Spartan: 111 / 90% / 410 / 16 (2 runs ended offering more)
- built-in Concise: 88 / 94% / 400 / 27 (2 offers)

All arms ignored the 10-row table cap (11-15 of 16 rows).

After review corrections, the session's final numbers: the current style without the reminder was shortest (median 75 vs 79 for mixed vs 85 for the reminder version). The only clear wins for mixed were the security-check reply (335 vs 431 words, 2 valid runs) and the status update (69 vs 91). The depth ("really explain") prompts showed no gain; every version answered at about the same length.

## Validity
- An independent review found 4 method flaws. Depth-prompt counts are artifacts: 3 runs scored valid were cut-off 2-turn runs. 1 run was a raw Write tool call scored as valid. Scorer regexes could not see the dropped `/copy` line. 3 runs per cell is too few. The assistant excluded the 4 broken runs and retracted "mixed is shortest".
- The reminder showed no effect in single-turn tests. Long chats, tool use and the reminder's effect over many turns were untested.
- The review also found 3 rule conflicts in the merged text, all fixed: the clean-text rule dropped the `Run /copy` line (2 of 2 completed retest runs kept it; a third stalled and timed out); "blocking question goes last" clashed with ending on `Next:`; "bold every risk" clashed with "bold sparingly". Two lines close to the AGPL source were reworded.
- The assistant skipped its own extra review of the first merge, citing 24 runs of the same text; the independent review it then ran found the conflicts above.
- An early-run 595k-token anomaly was traced to ToolSearch being off (see the linked probe).

## Decision
Add the merged rules (after the three conflict fixes) and keep a per-turn reminder hook: "Be concise: lead with the result, skip preamble and narration, keep only what the user needs."

## History
- 2026-10-13 — `4f496d8d dx(agents): adopt concise replies and quiet waits` (same session, before the test): first concise-reply rules and quieter monitoring text.
- 2026-10-13 — `43e2978c dx(agents): add concise rules from style a/b test`: added to `main-rules.md`: "Answers stop once the point lands", the bare-draft rule keeping the `Run /copy` line, "Short means fewer words, not fewer points", exact numbers and scoped conditions, blank lines and no paragraph over about 40 words, a blocking question goes in the `Next:` line; and "bold the main fact and each risk".
- 2026-10-13 — `7819604f dx(claude): repeat concise reminder each prompt`: UserPromptSubmit hook in `claude-settings-modify.sh` echoing the reminder.
- 2026-10-14 — `345ba6eb dx(agents): compact rules and skill descriptions`: compacted these rules (the "Answers stop once the point lands", "Never write a paragraph over" and "Put a question that blocks you" strings last appear here).
- 2026-10-15 — `8bbad79d dx(agents): share writing rules with sub-agents`: moved the writing rules from `main-rules.md` into `writing-rules.md`, so sub-agents get them too.
- 2026-10-16 — `5548fbb0 dx(claude): drop the per-prompt concise reminder`: removed the hook; no body. The reason was not found (searched transcripts and `agt sessions search` for the reminder text and "reminder"; the only hit was 6cf86035 itself).
- Today: the merged rules live in `home/.chezmoitemplates/writing-rules.md` ("Short means fewer words, not fewer points", paragraphs under about 40 words, blank lines). The per-prompt reminder hook is gone.
