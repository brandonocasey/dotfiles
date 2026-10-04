---
name: preview
description: Show a live preview when possible. Provide visual choices or screenshots only when requested; use a LAN gallery for requested choices.
---

# Preview

Default to a live preview of the actual app or page. A request to preview or
show the work does not by itself request alternatives or screenshots.

Read [task-resources.md](../host-preflight/references/task-resources.md) before
creating resources or starting a server. It owns locations, ports, and cleanup.
Previewing existing work does not request prototype development.

## Live preview

Reuse a suitable running app server, or start the project's documented preview
or development server. Bind a server you start to `0.0.0.0`, choose a random
free port, and reuse that port throughout the task. Get the LAN IP using the
platform command in `task-resources.md` and share `http://<lan-ip>:<port>` with the route
that shows the work. Verify the page and relevant interactions before sharing
it, following `browser` and `ui-verify` where applicable.

If the app cannot run here, use a faithful local HTML preview when practical
and label its limitations. If neither is possible, explain the blocker;
do not substitute unsolicited screenshots or a choice gallery.

Keep a server and its required files running while the user needs the preview
URL, including after the response. Report the URL and purpose. Stop servers
you started and remove task scratch files after the user finishes or requests
shutdown; preserve servers owned by other tasks.

## Requested screenshots

For preview delivery, capture screenshots only when the user requests them.
This does not change screenshot evidence required by `ui-verify` for UI fixes.
Use the actual app at the requested viewport and state. Attach them natively when available;
otherwise serve them through HTTP. Screenshots are not a prerequisite for
sharing a live preview.

## Requested choices

Offer alternatives only when the user requests choices, options, or variants.
Use `agent-preview` when those choices benefit from a browser gallery. Read
[choices.md](references/choices.md) for that gallery workflow. Prefer live
variants when interaction matters; the gallery's sandboxed HTML cannot run
the app. Use screenshots as gallery assets only when requested.
