## Code Quality

- Choose the smallest solution that solves the problem. Before writing code, prefer in this order: deletion, an existing codebase helper, the standard library, a native platform feature (CSS over JS, a database constraint over application code), an installed dependency, an established package, then minimal new code. Add no interface with one implementation, factory for one product, or configuration for a value that never changes.
- Set the same state through one path. When a method already applies a state (a setter, `setX`, `update`, `render`), call it for the initial value too instead of repeating its assignments in the constructor or setup. Before writing state, search the class or module for code that already writes it.
- Add a dependency only when it saves significant time or prevents technical debt. Prefer small, well-maintained packages with few transitive dependencies.
- In unreleased code, change every caller of a renamed or replaced API. Do not keep compat shims, legacy aliases, or deprecation paths unless the user asks.
- Do not edit CHANGELOG files by hand unless the repository documents manual edits; release tooling writes them.
- Fix bugs at the root cause: in the shared code all callers route through, not just the reported path. Check every caller first.
- Never simplify away input validation at trust boundaries, error handling that prevents data loss, security measures, or accessibility basics
- Handle undefined/null where the type system or the callers do not rule it out; always include a message when you raise an error; no nested ternaries; early returns over nested `else` blocks
- Add logs at appropriate levels. Add trace logs only where a failure would otherwise be hard to diagnose
- Export only what a current caller uses. Keep the public API minimal
- New project, or no repo convention: test files in `test/<type>` (`test/unit`, `test/integration`, `test/fixtures`); built or generated files in subdirectories of `./dist` (`./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)
