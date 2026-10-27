# Tester steps

## Run the checks

Run the given checks within the scope. Write each full log to the scratch
directory, ending with an `exit N` line. Search the whole log for failures,
errors, and warnings, and match the failure count to the summary line; do not
judge a log from its tail alone. Do not weaken or skip tests. When the repository
enforces size, accessibility, or performance budgets, check whether the change
moves them. Never install dependencies; report missing ones as blocked.

## Choose the cases

Skip this and the next section when the prompt says `Cases: skipped`.

Test exhaustively within the scope. Never sample or pick only representative cases.

Read repository run instructions and the changed code's callers.
List every affected user journey, command, flag, route, and consumer.
For each, build a case matrix and run every cell that applies:

- **Inputs:** each valid class; empty, missing, null, zero, negative, and huge
  values; each boundary and one past it; malformed, wrong-type, and duplicate
  input; Unicode, whitespace, and special characters in text and paths.
- **Paths:** the success path, every error and fallback branch the change can
  reach, and every option, mode, or feature flag it touches.
- **State:** first run, repeat run, existing and missing data, interrupted or
  cancelled work, retries, and concurrent use where the code allows it.
- **Environment:** each supported engine, OS, viewport, theme, locale, and
  permission level the change can affect, as far as tools allow.
- **Neighbors:** adjacent features that share the changed code, to catch
  regressions outside the diff.

Then explore freely for defects the matrix missed, and record those as `exploratory`.
Do not repeat by hand what an automated test already proves for the same input.
Read code only to choose and run cases, never to review the diff itself.
Record the checkout and revision used, and list any cell left untested with its reason.

## Exercise the actual behavior

Run repository setup and start commands within the prompt's scope.
Automated tests, static inspection, and screenshots alone do not replace manual interaction.
Follow `ux-verify` for every user-facing result, and `browser` for browser work.

- **UI:** exercise real controls in the browser. Check the affected states,
  layouts, input methods, and themes. Observe resulting state, downloads, or
  navigation. Capture useful screenshots and relevant console or network errors.
- **CLI or service:** run the changed command or request across the case matrix.
  Inspect output, exit status, error messages, and resulting files or state.
  Check round-trip or output parity when the change can affect them.
- **Runtime-only code** (workers, WASM, a server route): exercise it across the
  case matrix with realistic inputs. Running the code finds the most severe defects.
- **Library, configuration, or instructions:** use the consuming tool or a direct
  invocation across the case matrix. For instructions, walk through realistic
  requests for every branch, and check each decision, reference, and authorization
  boundary.

State missing credentials, unavailable devices, or unsafe operations as blocked.
Complete reachable checks; do not claim blocked paths passed.
Follow repository rules for server binding, artifact storage, and cleanup.
