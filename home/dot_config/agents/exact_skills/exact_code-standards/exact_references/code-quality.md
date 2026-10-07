## Code Quality

- Choose the smallest solution that solves the problem, and prefer deletion. Before writing code, prefer in this order:
  1. No new code: no interface with one implementation, factory for one product, or configuration for a value that never changes.
  2. An existing codebase helper.
  3. The standard library.
  4. A native platform feature, such as CSS over JS or a database constraint over application code.
  5. An installed dependency.
  6. An established package or plugin for the job.
  7. The minimum new code that works.
- Add a dependency only when it saves significant time or prevents technical debt. Prefer small, well-maintained packages with few transitive dependencies.
- In unreleased code, change every caller of a renamed or replaced API. Do not keep compat shims, legacy aliases, or deprecation paths unless the user asks.
- Do not edit CHANGELOG files by hand unless the repository documents manual edits; release tooling writes them.
- Fix bugs at the root cause: in the shared code all callers route through, not just the reported path. Check every caller first.
- Never simplify away input validation at trust boundaries, error handling that prevents data loss, security measures, or accessibility basics
- Keep each piece of code small and single-purpose; break up components that grow too complex; reduce duplication
- Handle undefined/null where the type system or the callers do not rule it out; always include a message when you raise an error; no nested ternaries; early returns over nested `else` blocks
- Add logs at appropriate levels. Add trace logs only where a failure would otherwise be hard to diagnose
- Export only what a current caller uses. Keep the public API minimal
- New project, or no repo convention: test files in `test/<type>` (`test/unit`, `test/integration`, `test/fixtures`); built or generated files in subdirectories of `./dist` (`./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)
