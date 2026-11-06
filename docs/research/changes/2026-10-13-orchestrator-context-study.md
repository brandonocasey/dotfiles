# Orchestrator context study: agent result cap, checkpoints, bulk checks

- Status (2026-11-06): current for the result cap and checkpoint wording. D8 (settings and hooks) was never committed. Live wording: `home/.chezmoitemplates/agents/explorer.md` and `worker.md`: "If the result exceeds ~40 lines and the prompt names a result path, write it there and return at most 5 lines: path, counts, status." `exact_sub-agents/exact_references/workflows.md` line 36: "At each phase boundary of a multi-agent run, record a checkpoint with `agt task` ..." `exact_sub-agents/SKILL.md` line 41: "Give bulk checking to a fresh agent that writes a verdict file; read only its failed or unverified lines." The output-style exception (proposal 5) was applied then replaced the same day.
- Topic: Sub-agents and orchestration
- Related: [auto-compact 400k](2026-10-14-auto-compact-400k.md), [review loop](2026-10-13-review-loop.md), [not adopted](not-adopted.md), [agent starting context](../ab-tests/2026-10-13-agent-starting-context.md)

## Change
The research session (no edits of its own) produced a 102-item ledger and 9 proposals for keeping the orchestrator session small. Session 66da602a applied 8 of 9 as `d813f42b`. Wording now in agent roles: agents write results over about 40 lines to a file and return at most 5 lines (path, counts, status). Other adopted items: bulk checking by a fresh verifier agent instead of "Re-validate every result", a shared brief file with a spot-check for open-ended work ("Spot-check high-risk items yourself against the cited code or data"), and a checkpoint at every phase of a multi-agent run.

The nine proposals as listed by 66da602a: D1 result cap; D2 fresh agent checks bulk results (replaces "re-validate every result"); D3 open-ended shared brief and spot-check (replaces "verify each item yourself"); D4 progress saved at every phase; D5 full tables go to a file during agent-heavy runs (an exception to "show data in full"); D6 relay only phase, failure and done updates; D7 cheap agents fetch diffs, logs and browser evidence everywhere; D8 settings and hooks (re-inject the ledger path after `/clear` or compaction, save state at about 30% context, consider turning auto-compact off and lowering the MCP output cap); D9 hand web-page reads to a sub-agent.

## History
- 2026-10-13 — Research session acb7f610 (15:44Z to 17:29Z, started with the `open-ended` skill; 4 of 6 rounds, 11 sub-agents). The only human turn after launch: "can you send these changes to global-rules-trim so that hey can be combined". It sent the 9 proposals to the session doing a rules trim.
- 2026-10-13 — Session 66da602a (work repo, 15:46Z to 17:57Z). It first logged 77 trim items and the 9 proposals, applied none, and asked which to apply. The user answered "both in one pass". Another session had unsaved edits in the settings script, so items 13-14 and D8 waited. Applied: 74 of 77 trim items plus 8 of 9 design changes.
- 2026-10-13 — The user on D8: "I think we shouldn't do any of that and just have the statusline warnings". D8 was removed before any commit ("D8 is fully removed... Auto-compact is back on").
- 2026-10-13 — Commits made by 66da602a: `d813f42b dx(agents): trim rules and cap agent result size` (13:42 local) and `7f68382c dx(claude): drop deny rules for a disabled plugin` (13:57). `94a473d1` has the same subject and the same author time as `d813f42b` (13:42:26) but a different parent and is not in the history of HEAD; it looks like a pre-rebase copy. Flagged, not cited as a change.
- 2026-10-13 — `d813f42b` applied D5: the output-style line became "Show data in full ... During multi-agent runs, write full tables to a file and show a summary plus the path". Later the same day (20:53 local) `4f496d8d dx(agents): adopt concise replies and quiet waits` replaced that line with "Show data simplified ... Up to 10 rows, show every row. Past 10, write the full set to a file; show at most 10 rows, highest risk first, plus the hidden count and the path."
- 2026-10-13 — `d813f42b` also removed the "Re-validate every result" rule (`git log -S` finds the removal in this commit) and "Verify each item yourself against the cited code or data" in the open-ended skill.
- 2026-11-06 — Status checked in the repo as in the Status line.

## Results
No test and no measurement of the changes. The study was an evidence survey: fetched pages cited in a ledger of 102 items, 13 items rejected, none tested live. The session said: "Not checked: Jules, Google ADK compaction page, Cursor beyond search results. No hook was tested live."

The three rules the session flagged as conflicting were all changed: "Re-validate every result" and "Verify each item yourself" were removed by `d813f42b`; the output-style "Show data in full" was edited by `d813f42b` and replaced by `4f496d8d`. The apply session found the proposals' own cost: auditing the 77 items by hand was "exactly the main-session cost those three proposals target". No later complaint about the 40-line cap was searched for.

## Sources
Sub-agents did WebFetch; the final reply listed these 7:
- [Claude Code workflows](https://code.claude.com/docs/en/workflows) — "Claude's context holds only the final answer"; script variables hold intermediate results.
- [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) — role and spawn prompt result handling.
- [Claude Code hooks](https://code.claude.com/docs/en/hooks) — hooks cannot trim background agent results; SessionStart reload.
- [Building a C compiler (Anthropic)](https://www.anthropic.com/engineering/building-c-compiler) — headless loop pattern, but it runs with `--dangerously-skip-permissions` (the session said do not copy that).
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — state on disk.
- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — sub-agents write to files and return references.
- [Run long-horizon tasks with Codex](https://developers.openai.com/blog/run-long-horizon-tasks-with-codex) — plan and ledger files for Codex (fetched .md).
- Also fetched but not in the final list: effective-context-engineering, context-window, settings-reference, env-vars, costs, headless, goal, cross-session-messaging, agent-teams, agent-sdk/subagents, ADK context, Letta MemGPT, Magentic-One, Cursor background agents, HF paper 2606.11213, primeintellect RLM blog, vantaige.io sub-agents blog, codex.danielvaughan.com context-window post.

## Evidence
Fetched pages cited in a ledger of 102 items; 13 items rejected; none tested live. The session said: "Not checked: Jules, Google ADK compaction page, Cursor beyond search results. No hook was tested live." Research session acb7f610 (2026-10-13, open-ended skill, 4 of 6 rounds, 11 sub-agents); applied by session 66da602a (2026-10-13).
