---
name: preview
description: "Show live previews; screenshots only on request. Offer requested or open-ended design choices through a LAN gallery."
---

Scope: Show a live preview when possible. Provide screenshots only when requested, and visual choices when requested or for an open-ended design; use a LAN gallery for choices.

# Preview

Default to a live preview of the actual app or page. A request to preview or
show the work does not by itself request alternatives or screenshots.

Read [task-resources.md](../host-preflight/references/task-resources.md) before
creating resources or starting a server. It owns locations, ports, and cleanup.
Previewing existing work does not request prototype development.

## Live preview

Reuse a suitable running app server, or start the project's documented preview
or development server per `task-resources.md`. Share its LAN URL with the route
that shows the work. Verify the page and relevant interactions before sharing
it, following `browser` and `ui-verify` where applicable.

If the app cannot run here, use a faithful local HTML preview when practical
and label its limitations. If neither is possible, explain the blocker;
do not substitute unsolicited screenshots or a choice gallery.

Keep the server and its files running while the user needs the preview URL,
including after the response; `task-resources.md` owns shutdown and cleanup.
Never stop servers owned by other tasks.

## Requested screenshots

For preview delivery, capture screenshots only when the user requests them.
This does not change screenshot evidence required by `ui-verify` for UI fixes.
Use the actual app at the requested viewport and state. Attach them natively when available;
otherwise serve them through HTTP. Screenshots are not a prerequisite for
sharing a live preview.

## Choices

Offer alternatives when the user requests choices, options, or variants. Also
offer them for an open-ended visual design with no reference or set direction,
such as a new look, layout, icon, or slide style.

- Before the first round, list the hard constraints from the request and
  earlier feedback, such as "mobile layout is the default". Every variant must meet them.
- Build 3–4 variants per decision. Each differs on a named axis: layout,
  density, color, type, or motion. Name the axis in the option description.
- If the user gave no reference image or URL, ask for one in the message that
  shares the gallery. Do not wait for it.
- When the user rejects every option, change the axis for the next round
  instead of tweaking the rejected options. Ask one question about what fails
  in the message that shares that round.

Use `agent-preview` when those choices benefit from a browser gallery. Read
[choices.md](references/choices.md) for that gallery workflow. Prefer live
variants when interaction matters; the gallery's sandboxed HTML cannot run
the app. Use screenshots as gallery assets only when requested.
