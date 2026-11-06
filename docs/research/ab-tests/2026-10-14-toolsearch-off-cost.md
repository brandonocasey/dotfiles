# ToolSearch-off cost probe: agents-md plugin vs connector tools

- Date: 2026-10-14  Sessions: b7f40d27 (investigation); the costly runs came from 6cf86035 (concise-style A/B, 2026-10-14 01:48 UTC)  Raw data: none. Free startup-event checks and local recording-server captures were not kept.
- Related: [Bash guard fixes commands, not blocks them](../changes/2026-10-28-bash-guard-updated-input.md), [Concise style A/B](2026-10-14-concise-style.md) (where the anomaly first showed), [Reviewer model A/B](2026-10-14-reviewer-model-opus-vs-sonnet.md) (reviewer ToolSearch sub-probe)

## Question
What caused the roughly 595k-token calls ($4.83 for one reply) seen in the output-style A/B? The earlier session had blamed the agents-md plugin.

## Setup
1. Read the session logs and the plugin code. The plugin only loads `AGENTS.md` and `CLAUDE.md` from a read file's folder up to the project root; none existed on the test path.
2. Free startup-event checks: run `claude` with a dead API address so no model call goes through, and read which tools the startup event lists. Vary `--strict-mcp-config` and `--tools`.
3. Real headless checks against a local recording server that captures the request Claude Code builds and then refuses it.

## Results
- Root cause: ToolSearch was missing, so about 595-617 connector tools were sent inline, about 600k tokens per call. The agents-md plugin was not the cause. In the concise-style session, plugin on and off both used 50,403 tokens with project settings; only the run with user settings jumped to 588k.
- The three costly or probe runs and what turned tool search off:
  - Oct 14 output-style A/B (the $4.83 run, 595k-601k tokens): `--tools Read` left out ToolSearch. Claude Code logs "ToolSearchTool is not available".
  - Oct 12 probe in a personal repo (602,951 tokens written): a deliberate `ENABLE_TOOL_SEARCH=false` test.
  - Oct 13 home-dir probe (603,224): ran through a local relay set as `ANTHROPIC_BASE_URL`. Claude Code's built-in docs say tool search is off by default with a custom base URL.
- Size: 595 connector tools, 2.08M characters. One observability connector alone is 1.36M, a notes connector about 270k, a mail or issue-tracker connector about 80k.
- Why the A/B numbers looked random: connectors connect a few seconds after a headless run starts. Short runs finished first and stayed small (about 50k). Longer runs had all the tools added in full.
- `--strict-mcp-config` removes all 617 connector tools. `--tools Read` drops ToolSearch. `--tools Read,ToolSearch` keeps it. context-lean does not disable ToolSearch, and Claude Code defers MCP tools by default.
- With ToolSearch present the context-lean mod deferred 2 tools (Agent and Skill); without it 0 (after the fix). In the real request without ToolSearch, all 617 connector tools (1.57M characters) were sent in full from the first request.
- Agent roles checked: `worker`, `manual-tester` and `cheap` have ToolSearch. `reviewer`, `light-reviewer`, `consult`, `explorer` and `tester` do not, but have no MCP tools, so only WebFetch and WebSearch go in full (a few thousand characters, unverified).

## Validity
- A review of the fix found a real bug: ToolSearch disabled through the settings file bypassed the guard. It was fixed with a per-variant free startup check. The review also raised 3 questions, all fixed (no doubled server notes after resume, Artifact rule kept, agent listing still shortened, a failed tool-list check retried).
- All 68 context-lean mod tests pass but none cover the no-ToolSearch path; two real runs are the only check.
- On this machine, managed settings make Claude Code skip the mod's prompt-attachment hooks, so only the deferral change applies here.
- Unverified: the "late tool(s) go inline from this request on" debug path; it looks tied to remote sessions and setting the flag the code checks made no difference.

## Decision
`agent-probe` guards headless variants against ToolSearch-off, and a global rule says to use `agent-probe` or keep `ToolSearch` in `--tools` and add `--strict-mcp-config` when tool search is off. context-lean stops deferring when ToolSearch is absent. The session chose not to build a separate tool-finder tool, because without ToolSearch every definition is already in the request.

## History
- 2026-10-14 — Investigation in b7f40d27.
- 2026-10-14 — `28d3f07b dx(agents): guard headless probes from inline tools`: `agent-probe` checks each variant with a free startup check; added the rule to `private_AGENTS.md`: "Use `agent-probe` for headless usage or A/B probes. In other `claude -p` runs, keep `ToolSearch` in any `--tools` list. When tool search is off ... add `--strict-mcp-config`."
- 2026-10-14 — `ad467669 dx(claude): keep context notes without tool search`: context-lean 0.7.1 stops deferring without ToolSearch.
- 2026-10-18 — `d3b8861f dx(claude): block three wasteful bash patterns` (body mentions headless `claude --tools` without ToolSearch): the bash guard blocks a `--tools` list without ToolSearch.
- 2026-10-28 — `9926b953 dx(bash-guard): fix bad commands, not block them`: the guard now adds ToolSearch to `--tools` itself.
- 2026-10-30 — `b49290a2 dx(context-lean): defer local MCP tools and notes`: later context-lean change.
- Today: the rule is in `private_AGENTS.md`; `bash-guard.py` still adds `ToolSearch` to a headless `--tools` list ("sends every connector tool in full (about 600k tokens per call)").
