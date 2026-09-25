# When Fable and Astra run a review

Run `review` automatically, once per task, when the task changed behavior and any of these hold:

- a shared function, module, or API contract with 3+ callers changed
- a trust boundary or irreversible path changed: auth, permissions, money, input parsing, persistence, migration, deletion, external writes, concurrency, crypto
- a new or changed branch, condition, or error path has no test that ran green in this task
- more than ~150 changed lines of hand-written logic remain after you exclude tests, docs, lockfiles, snapshots, generated files, and pure moves, renames, or formatting

Skip it only when the user did not ask for a review and one of these holds: every change is mechanical (rename, move, format, import order, dependency bump, config value), only tests and docs changed, or the code is a prototype or throwaway demo.
