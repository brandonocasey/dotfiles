---
name: real-safari
description: "Run visible real Safari for FairPlay or Safari-only checks; confirm unless already requested."
---

Scope: Use real Safari for FairPlay DRM or Safari-only checks via safaridriver. It is visible and needs user confirmation, unless the user asked for a real-Safari run.


Real Safari exists only on macOS. On Linux, Windows, or WSL, report that real
Safari is unavailable; the `safari` MCP there is Playwright WebKit, not Safari.

Prefer the `safari-native` MCP (Apple's, Safari 27+) when `uname` is `Darwin`
and `/usr/bin/safaridriver --help` lists `--mcp`. Never enable it otherwise.
Enable it for one session: Claude Code needs a restart with
`claude --mcp-config ~/.config/agents/mcp/safari-native.json`; Codex uses
`codex -c mcp_servers.safari-native.enabled=true`. It needs Safari > Settings >
Developer > "Allow remote automation and external agents"; if tool calls fail,
ask the user to turn that on.

Without `--mcp`, use the WebDriver flow below: start
`safaridriver -p <open port>` and drive it with the W3C WebDriver REST API via
curl. Every endpoint below is relative to `http://localhost:<port>`.

Remote automation must be enabled once per machine, or `POST /session` fails. If it
does, tell the user to run `safaridriver --enable` — it asks for their password, so
do not run it yourself. Steps:

1. Create the session: `POST /session` with
   `{"capabilities":{"alwaysMatch":{"browserName":"safari"}}}`. Read the session id from
   `.value.sessionId` in the response.
2. Navigate and script with `/session/<id>/url`, `/session/<id>/execute/sync`, etc.

Constraints:

- One session at a time system-wide. `DELETE` the session and kill `safaridriver`
  when done.
- Media autoplay needs the `webkit:alwaysAllowAutoplay` capability in `alwaysMatch`,
  or a real gesture via `POST /session/<id>/element/<element-id>/click`.
- It is always headed and visible. A user request to test or run in real Safari
  is the confirmation. Otherwise, confirm with the user before starting.
- Never bring the window to the foreground yourself.
- Main session only. Sub-agents never start real Safari.
