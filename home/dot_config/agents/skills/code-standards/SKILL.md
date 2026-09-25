---
name: code-standards
description: >
  Rules for code, comments, tests, dependencies, and plans. Use before you write
  or change code, tests, config, or dependencies, write a plan, or review code.
---

## Code comments

- Comment only what the code cannot show: a reason, constraint, workaround, required behavior, or warning about code that deliberately breaks convention. Do not repeat what the code says or describe the change; put the bug, investigation, and ticket in the commit message. Remove redundant comments, and update or remove comments when the code changes. Each comment must make sense to someone who has not read the conversation.
- Put the comment at the method or block level, in 1–2 complete sentences
- State a real requirement with a capitalized RFC 2119 keyword (MUST, SHOULD, MAY, …) https://www.rfc-editor.org/rfc/rfc2119 : `Callers MUST hold the lock`. Lowercase in ordinary prose
- Link external context at the point of use: the source of copied code, the spec tricky logic implements, the issue a workaround works around, and `TODO` plus an issue reference for known-incomplete code

## Tests & Lint

- Run the lint, type checks, and tests needed for the change and all checks required by the repository. Fix failures without the user's intervention; do not dismiss them as "pre-existing". After a fix, rerun the affected checks. Once the required checks pass, repeat or broaden them only for a new change, failure, or unresolved concern.

## Planning

- No pseudo code or real code in plans
- Break plans into the simplest steps, each with the context and location of its changes
- Delete plans on completion

## Code Quality

- Choose the smallest solution that solves the problem, and prefer deletion. Before writing code, prefer in order: no new code (no interface with one implementation, factory for one product, or configuration for a value that never changes); an existing codebase helper; the standard library; a native platform feature (CSS over JS, a database constraint over application code); an installed dependency; then the minimum new code that works. Add a dependency only when it saves significant time or prevents technical debt; prefer small, well-maintained packages with few transitive dependencies.
- Fix bugs at the root cause: in the shared code all callers route through, not just the reported path. Check every caller first
- Never simplify away input validation at trust boundaries, error handling that prevents data loss, security measures, or accessibility basics
- Keep each piece of code small and single-purpose; break up components that grow too complex; reduce duplication
- Handle undefined/null cases; always include a message when you raise an error; no nested ternaries; early returns over nested `else` blocks
- Add logs at appropriate levels; be generous with trace logs — they are how LLM agents debug
- New project, or no repo convention: test files in `test/<type>` (`test/unit`, `test/integration`, `test/fixtures`); built or generated files in subdirectories of `./dist` (`./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)
