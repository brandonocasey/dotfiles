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
- For a bug fix, write or find a test that reproduces it through the real entry point with the real input shape; for an error, use the message production code builds, not a hand-written one. Run it before the fix and show that it fails. After the fix, show that it passes. A test that calls a helper directly does not cover the code that wires it in: remove the wiring in a scratch change, confirm a test fails, and restore it. If no test can reproduce the bug, show a manual reproduction before and after; for UI, follow `ux-verify`. New behavior needs the same wiring check for each new branch; a fixture that takes another route (zipped instead of loose input, only the first event) or a test that also passes on base proves nothing.
- After fixing a finding or failure, reread the fix as new code and apply the edge, failure, mirror, and scale checks in `code-quality.md` to it, then rerun the failing case and its neighbors.
- When you write or change a lint rule, CI gate, or verification script, show it fails on a known-bad case before trusting its pass. Make the bad case in a scratch copy, a temporary input, or a reverted change, and remove it afterward.
- Before reporting a check or measurement, confirm from its output that it ran on the current change, not cached, skipped, or stale. When a result beats the expectation you held beforehand, find the cause before reporting it. Rerun only to settle that doubt.
- Make tests use a temporary HOME, XDG_* directories, database, and git repository. Tests never touch the user's real config, logs, or data. Put directories that you make by hand under the AGENTS.md scratch path.
- Give long tests, builds, and background runs a task-appropriate timeout. If output stops, inspect process activity and available progress indicators. Stop only when the timeout expires or evidence shows a hang. Isolate the failing test when identifiable.
- When a change alters behavior, a command, a flag, a config key, or a default, update its tests and docs in the same change. Docs include README, `docs/`, man pages, shell completions, help text, and config schemas. If docs are generated, change the source and run the generator; never edit the generated output. Before committing, `rg` the whole repository for every changed or removed flag, command, path, message, and behavior claim. Include skills, AGENTS.md, comments, and error hints that name a flag. Fix each stale mention. In the final report, list the updated docs or write "Docs: none affected".
- Check each factual claim in a comment, doc, help text, or PR description (what other code does, counts, names, limits) against the final code. After the last edit or push, reread every one you wrote and `rg` the old value (count, label, message, each locale) in tests and docs.

## Planning

Before writing a plan, read [planning.md](references/planning.md).

## Code Quality

Before writing or changing production code, read [code-quality.md](references/code-quality.md).
