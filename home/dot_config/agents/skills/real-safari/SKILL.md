---
name: real-safari
description: >
  Use real Safari for FairPlay DRM or Safari-only checks via safaridriver. It
  is visible and needs user confirmation before starting.
---

Check `safaridriver --help` for the installed driver's transports; some versions
support `--mcp`. The configured `safari` MCP uses Playwright WebKit. For the
WebDriver flow below, start `safaridriver -p <open port>` and drive it with the
W3C WebDriver REST API via curl. Every endpoint below is relative to
`http://localhost:<port>`.

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
- It is always headed and visible: confirm with the user before starting, and never
  bring the window to the foreground yourself.
