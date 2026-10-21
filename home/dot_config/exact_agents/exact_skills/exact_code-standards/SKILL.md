---
name: code-standards
description: "Apply before writing or reviewing code, tests, configuration, dependencies, or plans."
---

## Code comments

Before adding or changing comments, read [comments.md](references/comments.md).

## Tests & Lint

- Run checks relevant to the change and all checks the repository requires. Fix failures the change caused.
  For other failures, establish their cause and effect on validation, and report them with evidence.
  Fix them only when they block the requested work and are in scope; otherwise ask.
  After a fix, rerun affected checks; broaden only for a new change, failure, or unresolved concern.
- For a bug fix, write or find a test that reproduces it. Run it before the fix and show that it fails. After the fix, show that it passes. If no test can reproduce the bug, show a manual reproduction before and after; for UI, follow `ux-verify`.
- When you write or change a lint rule, CI gate, or verification script, show it fails on a known-bad case before trusting its pass. Make the bad case in a scratch copy, a temporary input, or a reverted change, and remove it afterward.
- Before reporting a check or measurement, confirm from its output that it ran on the current change, not cached, skipped, or stale. When a result beats the expectation you held beforehand, find the cause before reporting it. Rerun only to settle that doubt.
- Make tests use a temporary HOME, XDG_* directories, database, and git repository. Tests never touch the user's real config, logs, or data. Put directories that you make by hand under the AGENTS.md scratch path.
- Give long tests, builds, and background runs a task-appropriate timeout. If output stops, inspect process activity and available progress indicators. Stop only when the timeout expires or evidence shows a hang. Isolate the failing test when identifiable.
- When a change alters behavior, a command, a flag, a config key, or a default, update its tests and docs in the same change. Docs include README, `docs/`, man pages, shell completions, help text, and config schemas. If docs are generated, change the source and run the generator; never edit the generated output. In the final report, list the updated docs or write "Docs: none affected".

## Planning

Before writing a plan, read [planning.md](references/planning.md).

## Code Quality

Before writing or changing production code, read [code-quality.md](references/code-quality.md).
