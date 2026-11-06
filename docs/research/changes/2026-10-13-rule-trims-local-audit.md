# Rule trims driven by a local audit

- Status (2026-11-06): current. The deduplicated rule files stay; the allows for `LS`, `MultiEdit` and `NotebookRead` and the two `Skill(frontend-design:frontend-design*)` denies are absent from `home/.chezmoitemplates/claude-settings-modify.sh` (`frontend-design@claude-plugins-official` is `false` there). Later audits trimmed rules again (see History).
- Topic: Incidental doc use (the change was not driven by the source)
- Related: [Orchestrator context study](2026-10-13-orchestrator-context-study.md), [Codex tester sandbox](2026-10-21-codex-tester-sandbox.md)

## Change
Duplicate rules deduped and rare paths moved out of the always-loaded rules and skills; allows for retired tools dropped; deny rules for a disabled plugin dropped. The trims were driven by a multi-round local audit, not by a doc quote.

Correction to S: S said the retired-tool allows were "redundant under bare allows". The session says the opposite for the bare `Bash` allow: the reviewer found that in auto mode Claude Code drops a bare `Bash` allow, so the narrow `Bash(...)` allows still do work. The permissions trim was therefore mostly reverted, and only the dead `LS`, `MultiEdit` and `NotebookRead` entries were removed. The two `Edit(...)` path allows were kept because a bare `Edit` could not be confirmed to cover files outside the project.

## History
- 2026-10-13 — session 15ffc530 (web-player): `/open-ended` "do i have any global rules that should probably be trimmed, or are overly verbose, or that are out of place? look at everything including agent only stuff". It stopped after round 5 of 6, before it ran dry (round 5 still found 7 small items; stopped early to save cost). A reviewer found 3 real bugs and a few lost rules; 4 lost rules were restored.
- 2026-10-13 — commit `5e950389 dx(agents): dedupe rules and move rare paths out`: 76 files, +751 -886 lines, of rules, skills and role templates. It also saved an unsaved `--loop` edit from another session into `roles.md`.
- 2026-10-13 — commit `1f3461c4 dx(claude): drop allows for retired tools`: removes `LS`, `MultiEdit` and `NotebookRead` from the allow list, reorders the Atlassian MCP allows, and drops a dead commit reference from the `prune-agent-dirs.sh` comment.
- 2026-10-13 — session 66da602a (web-player): the same audit prompt, a larger run (round 7 found 35 new items, round 8 followed); 74 of 77 trim items and 8 of 9 design changes were applied. This is also the orchestrator study (see [orchestrator context study](2026-10-13-orchestrator-context-study.md)).
- 2026-10-13 — commit `d813f42b dx(agents): trim rules and cap agent result size`: "Drop repeated, rationale-only, and stale lines across always-loaded rules, role files, and skills. Merge the review fix references and inline ship's writing reference. Keep the main session's context small on multi-agent runs: agents write long results to a named file, bulk checks go to a fresh agent, and every phase saves a checkpoint." 62 files. An identical earlier commit `94a473d1` (same subject and time, 222 versus 223 insertions) is not reachable from main; S named `94a473d1`.
- 2026-10-13 — commit `7f68382c dx(claude): drop deny rules for a disabled plugin`: removes the two `frontend-design` skill denies (item 13). The settings script held another session's unsaved edits, so only the two lines were staged.
- 2026-10-24 — commit `3301fe10 dx(agents): cut duplicate rules and fix conflicts`: a later trim from an `llm-setup-audit` run (session 446ca2ba): "Remove rules repeated across AGENTS.md, the main rules, role files, and skills, and resolve conflicts". Behavior changes listed in its message include: roles search with rg first, waits state their expected duration, sub-agents wake every 4.5 minutes.
- 2026-11-06 — status check: all four commits' effects present in the current files.

## Results
No A/B measurement of the trims. Reported counts: 5e950389 removed 886 lines and added 751 across 76 files; d813f42b removed 327 and added 223 across 62 files (commit stats). The session did not measure the token effect of either. The 66da602a ledger applied 74 of 77 trim items; items 13-14 and the hooks-and-settings change (D8) waited because the settings script held another session's unsaved edits. D8 was later built and removed (see the "Not adopted" doc).

Problems seen: the first trim dropped rules by mistake (3 bugs and 4 lost rules in 15ffc530; a dropped "existing child MR/PR keeps its target" rule restored in 66da602a after a rebase). The permissions-trim claim in S was wrong (see Correction above).

## Sources
Claude Code permission and settings docs were fetched (URLs not preserved), but the trims were driven by a local multi-round audit. The "retired tool allows" finding came from the audit ledger, not from a doc quote.

## Evidence
Incidental. Sessions 15ffc530 and 66da602a (2026-10-13). The doc pages were fetched by sub-agents and summarized; no URLs or quotes were kept.
