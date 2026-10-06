---
name: ui-verify
description: "Verify UI changes, responsive layouts, themes, and interaction states in a browser."
---

Scope: Verify changed UI behavior, responsive layouts, themes, and interaction states in a browser. Use for UI changes, visual defects, test pages, and prototypes.


# Verify UI

Check the affected user journeys against the requested behavior. Scale coverage
to the change: a shared navigation change needs more routes than a local label
edit. Keep the existing design direction unless a redesign is part of the task.

When resuming from a `session-resume` record, reuse UI evidence only when its
revision, inputs, browser environment, viewport, theme, and state still match.

## Choose the checks

Record the checkout or preview URL and the changed code revision. Read the
relevant components, styles, and existing browser tests. Select the viewports,
themes, and states affected by the change; avoid a full Cartesian product when
the same behavior can be checked with a smaller set.

When the request names a breakpoint or state, change only that scope. Check one
other breakpoint to prove that it did not change.

For a reported defect, first reproduce it at the user's viewport and theme.
Take a before screenshot. A phone screenshot from the user means a phone width.

For responsive changes, check narrow and wide layouts and sizes immediately
around the actual CSS breakpoints. Include long content and the affected
empty, loading, error, and populated states. Check light/dark themes and
reduced motion when their styling or transitions changed.

## Exercise the UI

Load the `browser` skill before browser MCP calls. It owns engine selection,
focus, audio, and browser cleanup. Use a repository run/test skill when
available to start the app with its required headers and assets.

Inspect the rendered DOM before choosing selectors. Prefer roles and accessible
names. Wait for the state under test, such as a visible result or completed
download; do not use arbitrary sleeps or network-idle as proof that a page is
ready. Exercise the real control and assert the result.

For the affected controls, check clipping, unintended horizontal scrolling,
overlap, reachable actions, tab order, visible focus, and accessible names.
Check pointer and touch behavior when the interaction changes. Screenshots show
appearance; assertions and observed actions establish behavior. A resized
desktop window does not prove mobile keyboard or real Safari behavior. Record
those limits and use the `real-safari` skill when that specific check is needed.

Measure each layout claim with a DOM script, not only by eye. Examples: the
offset between two centers, the right edges of aligned items, equal heights,
`scrollWidth > clientWidth`, and a tap target of at least the project's target
size, or 44 px when the project sets none. Report the numbers. If no browser script is available, say that the measurement is
unverified.

Save representative screenshots with their viewport, theme, state, and revision.
Use the repository's output convention, or `dist/ui-verify/<task>` for new
artifacts. Capture relevant console or network failures with the reproduction.

When the user reports no visible change, make sure that the URL serves the
current build. Compare a bundle hash or version string to the revision. If a
service worker or immutable cache serves old files, tell the user how to clear
site data.

## Return the evidence

Report the checked journey and states, concrete failures, screenshots,
measurements, and untested device or engine coverage. For a reported defect,
include before and after screenshots at the same viewport. Do not say "fixed"
without this evidence. Fix in-scope defects and
rerun the affected checks. Reuse results for unchanged code and inputs.

Return evidence to the requesting task or `review`; do not start another review
or shipping cycle from this skill. `frontend-design` owns a requested design
direction, and [preview](../preview/SKILL.md) owns galleries of visual options.
This skill checks the implemented result.
