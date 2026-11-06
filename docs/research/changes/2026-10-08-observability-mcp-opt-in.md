# Observability MCP loaded only via a separate launcher

- Status (2026-11-06): removed. The `claude` fish function, the separate launcher function and the per-session deny were deleted on 2026-10-12 (`71b04d5c`). The observability connector's tool names are now hidden by the `context-lean` plugin (`home/dot_claude/local-mods/context-lean`), which defers connector tools so Claude finds them with ToolSearch. The settings template has no observability deny.
- Topic: Settings, permissions and security
- Related: [Pin Claude Code 2.1.296](2026-10-27-pin-claude-code-2-1-296.md) (context-lean only runs on 2.1.296)

## Change
The observability vendor's claude.ai connector offers about 400 tools, and their names cost about 13k tokens in every session. The 2026-10-06 deny `mcp__claude_ai_<observability>` in settings blocked calls but, per the session (stated as unverified), may not have stopped the server's tool list and instructions from loading. The change removed that deny and added two fish functions: `claude` runs `command claude --settings '{"deniedMcpServers":[{"serverName":"claude.ai <observability>"}]}'`, and a separate launcher function runs the same as `claude-two` (`CLAUDE_CONFIG_DIR=~/.claude-two`) without the deny, so the observability connector loads only when that launcher is used.

## History
- 2026-10-06 — commit `df47a964 dx(claude): hide unused <observability> MCP tools`: first attempt, a `mcp__claude_ai_<observability>` entry in `permissions.deny`.
- 2026-10-08 — session cf8d0588 (work repo): user after a `/mcp` reconnect: "any way to make it only available on demand? the observability connector was using 13k tokens a session". The assistant explained the block stops use, not the tool list; it offered a user-settings deny (hard to turn back on because the safety check blocks editing that file) and a per-session override. The user asked "is there any cli override we can add to override denied mcp servers for one session?". Docs say deny lists from every source combine, so `--settings` can add a deny but nothing can lift one. The wrapper was the result.
- 2026-10-08 — commit `525098eb` (subject names the vendor and the launcher; reworded here): removes the observability deny from the settings template; adds `claude.fish` and one launcher function file.
- 2026-10-12 — session b662b920 (personal repo): user: "can we add the observability connector to defer-tools mod to prevent having the whole alias thing we have right now", then "could we have another claude mod to do this for all of the connectors i'm not using". The assistant built a `hide-connectors` plugin and merged it with defer-tools into `context-lean`. Commit subjects for the plugin work list files only (for example `42f117c7`, `487d4bbf`, `172ecd2c`, `ae2d1c25`).
- 2026-10-12 — commit `71b04d5c Update .chezmoitemplates/claude-settings-modify.sh Remove .claude/local-mods/defer-tools/.claude-plugin/marketplace.json Remove .config/fish/functions/claude.fish` (real subject is a file list, shortened here): deletes both fish functions, enables `hide-connectors@local-mods`, and points the marketplace at the shared `local-mods` directory.
- 2026-11-06 — status check: no launcher function, `claude.fish` or observability deny in `home`; context-lean README still describes the observability connector being hidden and found through ToolSearch.

## Results
No A/B measurement of the wrapper. What was seen:
- The deny alone did not remove the cost: the observability connector still cost about 13k tokens per session (user's observation, cf8d0588).
- With the block in place the connector did not appear in `claude mcp list`, i.e. not connected. The assistant said "Unverified: whether this keeps the connector's tool names out of context, or only blocks calls... Check with `/context` in a new session." No `/context` check result was found in the session.
- Tested: the connector shows as connected under the launcher.
- The replacement was measured by the context-lean README (2026-10-13, 2.1.296, two runs): last request 13,015-13,052 tokens with the mod against 37,336-37,406 without, about 24,300 fewer, mostly from claude.ai connectors. In a test, a subagent saw no observability or mail tool names; Claude found the observability connector for "any error logs for a work service?" without being told the connector name. Loading a hidden tool costs one ToolSearch call.
- The alias approach was replaced after four days because it needed a separate command to start sessions with the connector and covered only one connector.

## Sources
- [Claude Code managed MCP](https://code.claude.com/docs/en/managed-mcp.md) — deny lists from every source are combined, so a per-session deny can be added but one cannot be lifted.
- [Claude Code settings](https://code.claude.com/docs/en/settings.md) — same; also `--settings` cannot set managed keys, so it can add a deny but not remove one.

## Evidence
Cited in the reply ("the docs say deny lists from every source are combined"); the result was tested (the connector shows connected under the launcher). The page text was read through WebFetch summaries. Sessions cf8d0588 (2026-10-08, work repo) and b662b920 (2026-10-12, personal repo, the replacement).
