---
name: ui-verify
description: >
  Verify changed UI behavior, responsive layouts, themes, and interaction states
  in a browser. Use for UI changes or reported visual and interaction defects.
---

# Verify UI

Check the affected user journeys against the requested behavior. Scale coverage
to the change: a shared navigation change needs more routes than a local label
edit. Keep the existing design direction unless a redesign is part of the task.

## Choose the checks

Record the checkout or preview URL and the changed code revision. Read the
relevant components, styles, and existing browser tests. Select the viewports,
themes, and states affected by the change; avoid a full Cartesian product when
the same behavior can be checked with a smaller set.

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

Save representative screenshots with their viewport, theme, state, and revision.
Use the repository's output convention, or `dist/ui-verify/<task>` for new
artifacts. Capture relevant console or network failures with the reproduction.

## Return the evidence

Report the checked journey and states, concrete failures, screenshots,
and device or engine coverage that remains untested. Fix in-scope defects and
rerun the affected checks. Reuse results for unchanged code and inputs.

Return evidence to the requesting task or `review`; do not start another review
or shipping cycle from this skill. `frontend-design` owns a requested design
direction, while this skill checks the implemented result.
