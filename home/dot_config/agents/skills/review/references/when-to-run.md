# When to run a review automatically

Applies to every model. Run `review` on this session's own change, before reporting done or
pushing, when the task changed behavior and any of these hold:

- a plan, feature, or multi-file implementation was just committed or is about to be
- a refactor, consolidation, type cleanup, or "no behavior change" edit touched logic;
  these hid dropped fallbacks, side effects, and broken callers more often than any other change
- a shared function, module, export, CLI flag, or API contract with 2+ callers changed
- a trust boundary or irreversible path changed: auth, permissions, money, input parsing,
  persistence, migration, deletion, external writes, concurrency, crypto
- browser worker, WASM, OPFS, service worker, or async lifecycle code changed
- a shell script or wrapper, CI workflow, build or packaging config, or agent skill/rule file
  changed behavior
- a rebase or merge needed manual conflict resolution
- a new or changed branch, condition, or error path has no test that ran green in this task

Skip it only when the user did not ask for a review and one of these holds: every change is
mechanical (pure rename, move, format, import order, dependency bump, config value), only
tests and docs changed, or the code is a prototype or throwaway demo.

## Follow-ups

Fixes made after a review, and follow-up commits pushed to an already reviewed MR/PR,
introduced new defects about as often as first drafts. Review the follow-up delta
(`<last-reviewed-sha>..HEAD`) when it changes logic beyond a one-line local edit. A
CSS-only or copy-only follow-up skips the review but still needs the rendered check.

## Second reviewer

One clean pass is not convergence. Run `--agents` with two reviewers on different models
when the change touches a trust boundary, concurrency, or persistence, or exceeds about
400 changed lines of hand-written logic.

## What review cannot replace

About half of the defects that reached the user were not visible in the diff: layout on a
real viewport or device, iOS/Safari behavior, worker/WASM runtime limits, real-data parsing,
external services, and CI-only budgets. A clean review never substitutes for the manual
check in AGENTS.md or for the repository's full test, lint, typecheck, and E2E suites.
