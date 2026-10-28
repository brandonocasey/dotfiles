## Code Quality

- Choose the solution that leaves the least code to maintain, not the smallest diff, within the code you touch. Before writing or editing code, prefer in this order: deletion, an existing codebase helper or a method that already sets the same state (call a setter for the initial value instead of repeating its assignments), the standard library, a native platform feature (CSS over JS, a database constraint over application code), an installed dependency, an established package, then minimal new code. Add no interface with one implementation, factory for one product, or configuration for a value that never changes.
- Add a dependency only when it saves significant time or prevents technical debt. Prefer small, well-maintained packages with few transitive dependencies.
- In unreleased code, change every caller of a renamed or replaced API. Do not keep compat shims, legacy aliases, or deprecation paths unless the user asks.
- Do not edit CHANGELOG files by hand unless the repository documents manual edits; release tooling writes them.
- Fix bugs at the root cause: in the shared code all callers route through, not just the reported path. Check every caller first. When derived objects must carry a flag, policy, or state, find every site that creates one with `rg` before fixing any. Enforce it where they are created rather than with a call at each site; otherwise fix all sites together or list the ones left.
- Before reporting code done, run it on the edge inputs it can meet, not only the happy path: empty, zero, one past each limit (size cap, 255-byte name, exact multiple of a block size); names and paths with Unicode, case, spaces, reserved characters, a repeated basename in another folder, and dots that look like an extension (`v1.2`, `#2.sfc`); sizes or counts read from untrusted data (bound them before allocating).
- For code that creates files, state, locks, or listeners, define what happens on error, cancel, repeat, and concurrent use: remove partial output and reset state on every exit path, guard in-flight work against a second call, and apply a late async result only if it is still current. Cleanup and catch-all handlers MUST NOT replace or mask the original error; a cancel stays a cancel. Delete only what this operation made or captured, never by shared basename or ID, and keep what another consumer still uses.
- When one rule lives in two places (native and browser, CLI and UI, Rust and TypeScript, readiness check and real run), change both in one change and test both with the same input. A dry run, preview, or readiness check MUST call the code the real run calls.
- In loops over user-sized collections, never scan another collection per item (build a Set or index first), never allocate or re-hash per item, and never build one regex or query from all the data. State the expected size and run one case at 10 times it before reporting.
- Never simplify away input validation at trust boundaries, error handling that prevents data loss, security measures, or accessibility basics
- Handle undefined/null where the type system or the callers do not rule it out; always include a message when you raise an error; no nested ternaries; early returns over nested `else` blocks
- Add logs at appropriate levels. Add trace logs only where a failure would otherwise be hard to diagnose
- Export only what a current caller uses. Keep the public API minimal
- In a loop over independent items (repositories, files, worktrees, records), one item's failure warns and the loop goes on. An item that vanished before you acted on it counts as done, not as an error. Record what was done before any step that can fail.
- Quote or validate every outside string before it reaches a shell, a git ref, a path join, or a URL. Compare paths as paths, not string prefixes. Decide whether to follow symlinks. Test with a space, a `;`, and a symlink.

## Edge cases to list before coding

Before writing code in these areas, list the cases below that apply. Handle each one or name why it cannot occur. Add a test for each case the code handles.

- **Code that deletes, moves, or restores user files or git data:** submodules (uninitialized, nested, with local-only refs), nested untracked repos, sparse checkouts, skip-worktree and assume-unchanged files, ignored files, staged changes that differ from the tree, unborn and detached HEAD, missing or locked linked worktrees, and user git config that changes defaults (`merge.autoStash`, `status.showUntrackedFiles`).
- **Replacing or matching another tool (gh, glab, a script):** first write a table of its behavior for each flag and edge input. Read its source or run it. Test each row. Report each deliberate difference.
- **Async UI, polling, or event handlers:** two actions in quick succession, responses out of order, a failed or slow request, a record read while half written, and user input that a refresh would discard.
- New project, or no repo convention: test files in `test/<type>` (`test/unit`, `test/integration`, `test/fixtures`); built or generated files in subdirectories of `./dist` (`./dist/fe/client`, `./dist/be`, `./dist/coverage`, `./dist/types`)
