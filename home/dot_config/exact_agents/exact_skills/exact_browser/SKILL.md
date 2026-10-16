---
name: browser
description: "Before browser MCP automation or browser test runs: page checks, screenshots, DOM/network inspection, playback. Real Safari: real-safari."
---

Never foreground a browser or steal focus. Never play audible sound unless the
task checks the audio itself.

## Test runners

- Run every browser test runner headless: Playwright, wdio, Karma, Cypress, or any other.
- Before a run, check its config for headed defaults, such as `headless: false` or a headed browser list.
- Override them for that run with a CLI flag, an env switch, or a headless project.
- If none exists, use a scratch config that extends the repo config. Never edit tracked test config.
- Run headed only for the headed cases in [Pick the MCP](#pick-the-mcp).
- Sub-agents never start headed browsers or real Safari. They report headed-only checks to the main session.

## Pick the MCP

| Engine | Server | Default |
| --- | --- | --- |
| Chrome | `chrome-devtools` | enabled, headless |
| Chrome | `chrome-headed` | disabled |
| Firefox | `firefox-devtools`, `firefox-headed` | disabled |
| WebKit | `safari`, `safari-headed` | disabled |
| Real Safari | `safari-native` (macOS with `safaridriver --mcp` only) | disabled |

Enable one disabled server per session:

- Codex: `codex -c mcp_servers.<name>.enabled=true`, or the same setting in the repository's `.codex/config.toml`.
- Claude Code: `claude --mcp-config ~/.config/agents/mcp/<name>.json`. A running session cannot add a server, so ask the user to restart it that way.

Do not enable extra engines globally; each enabled server adds startup work to every session.

Use headed mode only for DRM, fullscreen, picture-in-picture, casting, autoplay policy, audio checks, a real user gesture,
or when the user asks to watch.
The `safari` MCP uses Playwright WebKit; it has no FairPlay DRM.
Never enable `safari-native` off macOS or when `safaridriver --help` lacks `--mcp`.
For real Safari or Safari-only bugs, follow `real-safari` for driver selection and approval before starting the visible browser.

Only `chrome-headed` starts muted (`--mute-audio`). Mute other headed pages before playback.
For audio issues, where sound is allowed, read [audible-playback.md](references/audible-playback.md).

## Hangs

A `chrome-devtools` call that times out has hung the page for about 3 minutes;
retrying on that page hangs again.

- After the first `timed out` error, close that page and continue on a `new_page`.
- In `emulate`, omit `networkConditions` unless the check needs throttling. It is the call that hangs most.

## Proof

Check the observable that proves the claim: frames, pixels, or DOM state, not `currentTime`.
Assert preconditions, and run a control that must fail. See `ui-verify`.

## Screenshots

Every image stays in context and is re-read on each later turn. Tool names
below are `chrome-devtools`; use the matching tool on other engines.

- Check text, state, and layout with `take_snapshot` or `evaluate_script` first.
- Take a screenshot only for a visual judgment the DOM cannot give, or for evidence the user or an MR/PR needs.
- Save evidence screenshots with `filePath`. Do not `Read` them back unless you must judge them by eye.
- Browser MCPs write only inside allowed roots. In Claude Code, that is the session's project root: in a repo, save under `<worktree>/.cache/agents/scratch/<task>/`, never `~/.cache`. Codex offers no roots: save `chrome-devtools` and Firefox screenshots under `$TMPDIR`, and `safari` or `safari-headed` ones under `~/.cache/agents/playwright-mcp`.
- Capture an element by `uid` or the viewport. Use `fullPage`, without `uid`, only when the check needs the whole page.
- In the main session, delegate more than three visual checks to the `manual-tester` sub-agent. It returns findings and file paths, not images.

Clean up per [task-resources.md](../host-preflight/references/task-resources.md), on every exit path including failure.
