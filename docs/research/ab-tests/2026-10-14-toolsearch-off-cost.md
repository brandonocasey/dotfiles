# ToolSearch-off cost probe: ToolSearch present vs absent, agents-md plugin on vs off

- Date: 2026-10-14  Sessions: b7f40d27 (investigation); the costly runs came from 6cf86035  Raw data: none (free startup-event checks and local recording-server captures were not kept)

## Question
Cause of the roughly 595k-token calls ($4.83 for one reply) seen in the concise-style A/B: the agents-md plugin on vs off, and ToolSearch present vs absent.

## Setup
1. Session logs and plugin code read. The plugin loads only `AGENTS.md` and `CLAUDE.md` from a read file's folder up to the project root; none existed on the test path.
2. Free startup-event checks: `claude` run against a dead API address so no model call goes through; the startup event's tool list read while varying `--strict-mcp-config` and `--tools`.
3. Real headless checks against a local recording server that captures the request Claude Code builds and then refuses it.

## Results
- Plugin on vs off, project settings: 50,403 tokens in both. Only the run with user settings jumped to 588k.
- ToolSearch missing: about 595-617 connector tools sent inline, about 600k tokens per call. In the real request without ToolSearch, all 617 connector tools (1.57M characters) were sent in full from the first request.
- Connector tool definitions total: 595 tools, 2.08M characters; the largest single connector is 1.36M characters.
- Costly or probe runs and what turned tool search off:
  - Oct 14 concise-style A/B ($4.83 run, 595k-601k tokens): `--tools Read` left out ToolSearch ("ToolSearchTool is not available" logged).
  - Oct 12 probe in a personal repo (602,951 tokens written): a deliberate `ENABLE_TOOL_SEARCH=false` test.
  - Oct 13 home-dir probe (603,224): ran through a local relay set as `ANTHROPIC_BASE_URL`; Claude Code's built-in docs say tool search is off by default with a custom base URL.
- Short headless runs finished before connectors connected and stayed small (about 50k); longer runs had all tools added in full.
- `--strict-mcp-config` removes all 617 connector tools. `--tools Read` drops ToolSearch. `--tools Read,ToolSearch` keeps it.
- With ToolSearch present the context-lean mod deferred 2 tools (Agent and Skill); without it 0 (after the fix).
- Agent roles: `worker`, `manual-tester` and `cheap` have ToolSearch. `reviewer`, `light-reviewer`, `consult`, `explorer` and `tester` do not, but have no MCP tools, so only WebFetch and WebSearch go in full (a few thousand characters, unverified).

## Validity
- Single runs; no repeated measurement.
- Review of the fix found a bug (ToolSearch disabled through the settings file bypassed the guard), fixed with a per-variant free startup check.
- All 68 context-lean mod tests pass; none cover the no-ToolSearch path.
- Managed settings on this machine make Claude Code skip the mod's prompt-attachment hooks, so only the deferral change applied.
- Unverified: the "late tool(s) go inline from this request on" debug path.

## Decision
`agent-probe` guards headless variants against ToolSearch-off; a global rule says to use `agent-probe` or keep `ToolSearch` in `--tools` and add `--strict-mcp-config` when tool search is off; context-lean stops deferring when ToolSearch is absent.

## Commits
- `28d3f07b dx(agents): guard headless probes from inline tools`
- `ad467669 dx(claude): keep context notes without tool search`
- `d3b8861f dx(claude): block three wasteful bash patterns`
- `9926b953 dx(bash-guard): fix bad commands, not block them`
- `b49290a2 dx(context-lean): defer local MCP tools and notes`
