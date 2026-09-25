---
name: browser
description: >
  Use before browser MCP automation: page checks, screenshots, DOM/network
  inspection, or playback. For real Safari, use real-safari.
---

Never foreground a browser or steal focus. Never play audible sound unless the
task checks the audio itself.

## Pick the MCP

| Engine | Headless default | Headed |
| --- | --- | --- |
| Chrome | `chrome-devtools` | `chrome-headed` |
| Firefox | `firefox-devtools` | `firefox-headed` |
| WebKit | `safari` | `safari-headed` |

Use headed mode only for DRM, fullscreen, picture-in-picture, a real user gesture,
or when the user asks to watch.
The `safari` MCP uses Playwright WebKit; it has no FairPlay DRM.
For real Safari or Safari-only bugs, follow `real-safari` for driver selection and approval before starting the visible browser.

Only `chrome-headed` starts muted (`--mute-audio`). Mute other headed pages before playback.

Close pages and connections you opened when the task ends. Free ports you took.
