---
name: browser
description: >
  Use before browser MCP automation: page checks, screenshots, DOM/network
  inspection, or playback. For real Safari, use real-safari.
---

Never foreground a browser or steal focus. Never play audible sound unless the
task checks the audio itself.

## Pick the MCP

| Engine | Server | Default |
| --- | --- | --- |
| Chrome | `chrome-devtools` | enabled, headless |
| Chrome | `chrome-headed` | disabled |
| Firefox | `firefox-devtools`, `firefox-headed` | disabled |
| WebKit | `safari`, `safari-headed` | disabled |

Enable one disabled server for a Codex session with
`codex -c mcp_servers.<name>.enabled=true`. A repository can instead put the
same setting in `.codex/config.toml`. Do not enable extra engines globally;
each enabled server adds startup work to every session.

Use headed mode only for DRM, fullscreen, picture-in-picture, a real user gesture,
or when the user asks to watch.
The `safari` MCP uses Playwright WebKit; it has no FairPlay DRM.
For real Safari or Safari-only bugs, follow `real-safari` for driver selection and approval before starting the visible browser.

Only `chrome-headed` starts muted (`--mute-audio`). Mute other headed pages before playback.

Close pages and connections you opened when the task ends. Free ports you took.
