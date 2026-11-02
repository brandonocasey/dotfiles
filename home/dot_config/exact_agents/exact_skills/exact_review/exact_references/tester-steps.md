# Tester steps

## Run the checks

Run the given checks within the scope. Write each full log to the scratch
directory, ending with an `exit N` line. Search the whole log for failures,
errors, and warnings, and match the failure count to the summary line; do not
judge a log from its tail alone. Do not weaken or skip tests. Rerun only a failed
test, once, on the same tree: a pass on rerun is reported `flaky`, not pass, and
marked `pre-existing` unless the change touched that test. Never cache a failure.
When the repository enforces size, accessibility, or performance budgets, check
whether the change moves them. Never install dependencies; report missing ones as
blocked.

## Choose the cases

Skip this and the next section when the prompt says `Cases: skipped`.

Read repository run instructions and the changed code's callers.
Derive cases from `Expected:` first. A case with no stated expected result is
reported as `question` with the observed behavior, not pass or fail. As a fallback
oracle, compare output before and after the change.
List every affected user journey, command, flag, route, and consumer. For each:

- Run the boundary values of each changed input: empty, missing, zero, negative,
  huge, each boundary and one past it, malformed and wrong-type input, Unicode,
  whitespace, and special characters in text and paths.
- Run pairwise (2-way) combinations across input, state, and environment (engine,
  OS, viewport, theme, locale, permission level), including first and repeat run,
  existing and missing data, interrupted work, and retries. Use 3-way only for the
  `high` risk tier or stateful sequences.
- Cover the success path, every error and fallback branch the change can reach,
  and every option, mode, or feature flag it touches.
- Cover the sibling sites already found: adjacent features that share the changed
  code.

Keep an exploratory pass for defects the list missed, and record those as `exploratory`.
Do not repeat by hand what an automated test already proves for the same input.
Read code only to choose and run cases, never to review the diff itself.
Record the checkout and revision used, and list any untested cell with its
reason. Stop when the list is done.

## Exercise the actual behavior

Run repository setup and start commands within the prompt's scope.
Automated tests, static inspection, and screenshots alone do not replace manual interaction.
Follow `ux-verify` for every user-facing result, and `browser` for browser work.

- **UI:** exercise real controls in the browser. Check the affected states,
  layouts, input methods, and themes. Observe resulting state, downloads, or
  navigation. Capture useful screenshots and relevant console or network errors.
- **CLI or service:** run the changed command or request across the case list.
  Inspect output, exit status, error messages, and resulting files or state.
  Check round-trip or output parity when the change can affect them.
- **Runtime-only code** (workers, WASM, a server route): exercise it across the
  case list with realistic inputs. Running the code finds the most severe defects.
- **Library, configuration, or instructions:** use the consuming tool or a direct
  invocation across the case list. For instructions, walk through realistic
  requests for every branch, and check each decision, reference, and authorization
  boundary.

State missing credentials, unavailable devices, or unsafe operations as blocked.
Complete reachable checks; do not claim blocked paths passed.
Follow repository rules for server binding, artifact storage, and cleanup.
