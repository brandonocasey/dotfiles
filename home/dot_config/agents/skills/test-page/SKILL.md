---
disable-model-invocation: true
name: test-page
description: >
  Build a standalone test page that loads one or more builds, with numbered
  scenario buttons and a result and log panel. Explicit-only.
---

Optional arguments: builds (default branch, MR/PR numbers, branches) and scenarios.
Without builds, use the default branch and the current branch's MR/PR.

## Gather

1. Read the repo docs (AGENTS.md, AGENTS_PROJECT.md, README, `docs/`) for:
   - the existing test harness and its URL;
   - hosted builds of the default branch and of releases;
   - MR/PR build artifacts or a CI preview, and their URL pattern;
   - the local build and serve commands, and the browser floor.
2. Resolve one URL per build. For stacked branches, add one build per branch,
   in stack order. See [dependent-branches.md](../shared/dependent-branches.md).
   Build locally only when no hosted build exists. Load [worktree](../worktree/SKILL.md) first.
3. Take the scenarios from the user. Otherwise, derive them from the MR/PR
   description, the diff, and the tests. Show the list before you build the page.

## Build the page

Write one HTML file under `~/.cache/agents/scratch/<task>/`. Commit it only
when the user asks. Use only syntax and APIs that the repo's browser floor supports.

- A build selector, also settable as `?build=<name>`. Load one build per page load.
- Numbered scenario buttons, `1` to `N`. Number keys run them too.
- A result panel: one row per scenario with pass, fail, or not run, and the reason.
- A log panel: page errors, console output, and the events each scenario records.
  Add a button that copies the log as text.
- The build name and its URL, shown at the top.

## Serve

Serve the directory on `0.0.0.0` with a random free port, per
[AGENTS.md](../../AGENTS.md). Report `http://<lan-ip>:<port>/<file>`.
Use the project's CI preview only when the user asked to commit the page and
the push is authorized.

Before you share it, load [ui-verify](../ui-verify/SKILL.md). Run every
scenario on every build yourself and record the results.

## Hand off

Print short steps that work on any device:

1. Open `<url>`.
2. Pick a build.
3. Press each scenario button and read its result row.
4. Copy the log and send it when a result is wrong.

Stop the server at task end, unless the user still uses it.
