---
name: real-safari
description: >
  Drive real Safari (FairPlay DRM playback, Safari-only bugs) via safaridriver and the
  W3C WebDriver REST API — no MCP exists for it. Always headed and visible, so confirm
  with the user first. Load before any task that needs real Safari.
---

Real Safari has no MCP. Start `safaridriver -p <open port>` and drive it with the
W3C WebDriver REST API via curl. Every endpoint below is relative to
`http://localhost:<port>`:

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
