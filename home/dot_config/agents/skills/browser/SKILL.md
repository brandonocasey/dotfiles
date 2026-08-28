---
name: browser
description: >
  Pick and drive a browser MCP for any web task: page checks, DOM or network
  inspection, screenshots, media playback checks, DevTools traces. Owns the
  headless-vs-headed choice, the mute rules, and the no-focus-stealing rule.
  Load before the first browser MCP call. For real Safari use the real-safari
  skill instead.
---

# Browser automation

## Never interrupt the user

- Never bring a browser window to the foreground.
- Never play audible sound.
- Never steal focus from the user's active window.

## Pick the MCP

Default to the headless MCPs:

| Engine  | Headless (default) | Headed (only when needed) |
| ------- | ------------------ | ------------------------- |
| Chrome  | `chrome-devtools`  | `chrome-headed`           |
| Firefox | `firefox-devtools` | `firefox-headed`          |
| WebKit  | `safari`           | `safari-headed`           |

The `safari` MCP is Playwright WebKit, not real Safari. It has no FairPlay DRM.

Use a headed MCP only when the task needs one of these:

- DRM playback
- fullscreen
- picture-in-picture
- a real user gesture
- the user asks to watch

## Mute the audio

Only `chrome-headed` starts muted (`--mute-audio`). In every other headed MCP,
mute the page yourself before playback starts.

When you check playback, keep the player muted. The one exception is a task
about the audio itself.

## Clean up

Close the pages and connections you opened when the task ends. Free any port
you took.

## Real Safari

Real Safari (FairPlay DRM, Safari-only bugs) has no MCP. It is always headed
and visible, so confirm with the user first, then follow the `real-safari`
skill.
