## Testing

Every review tests the target before the reviewer starts. A fresh `tester`
sub-agent runs the repository's checks and the manual and UX cases in one pass.
The main session never tests itself; it records the results with `agt qa`, as it
records reviewer findings with `agt review`.

The tester always runs the automated checks. `--no-test` skips its manual and UX
cases, as does a change with no runnable behavior: text-only edits, or internal
refactors. State the skip reason in the report. `--test` forces the cases even
then.

Keep the review worktree until testing and authorized repairs are complete.
When resuming from a `session-resume` record, apply `session-resume`'s reuse rules.

## Stage order

1. **Test.** After setup, start one fresh `tester` with the prompt below on the
   whole target.
2. **Record.** Record its results (**Record**), then re-verify each failure as
   [delegation.md](delegation.md) re-verifies findings: read the cited log lines or
   evidence and the code they point to. Mark a failure the change did not cause as
   `pre-existing` in its check note.
3. **Fix.** With fix authorization ([fix.md](fix.md)), fix verified failures and
   commit them per fix.md step 4. Without it, report them beside the review findings.
4. **Retest.** After fixes, start a fresh `tester` on the changed code only
   (**Retest**). Record, re-verify, and fix again. Stop after 3 retests and report
   failures that remain.
5. **Review.** Start the reviewer per steps 0–2 of [SKILL.md](../SKILL.md) only
   after the last retest. Never pass test results to reviewers.

After review fixes, retest before each fix check and before the second cycle's
full review ([loop.md](loop.md)). Feed test failures into the same verification
pass; they never start another review cycle.

## Tester prompt

Fill this template and add nothing else. `<scope>` is `whole change` for step 1,
or `changed code only: <last-tested-sha>..<new-head-sha>` for a retest; for a
working-diff target, give the old and new diff paths.

```text
Test <target> (pinned <range or diff path>). Read-only: no edits, commits,
cleanup, or sub-agents. Never run `agt qa` or `agt review`.
Worktree: <path>
Scope: <scope>
Rerun: <names of checks and cases that failed last time, or `none`>
Checks: <test, lint, and typecheck commands from setup, or `none documented; choose relevant ones`>
Cases: <`manual and UX` or `skipped: <reason>`>
Steps: follow <absolute path of testing.md>, **Tester steps**.
Repository rules: <paths of AGENTS.md / CLAUDE.md / CONTRIBUTING.md at the root and in every changed directory>
Return per check and case, failures first: name, kind (automated, manual, or
exploratory), command or steps, inputs, expected and observed result, outcome
(pass, fail, blocked, or skipped), evidence paths, and environment (engine,
viewport, theme, OS).
```

## Record

Record each tester pass in the QA store, with the same store target flag as the
review (`--target <key>` or `--range <range>`; [store.md](store.md)):

1. `agt qa run start` with the tester's `--model`, `--effort`, and `--harness`;
   keep the printed run ID.
2. One `agt qa check --run <run> --name <name> --outcome <outcome> --kind <kind>`
   per returned check or case, with `--command` or `--steps -`, `--evidence` per
   path, `--env key=value` per fact, and `--note` for blocked or skipped reasons.
   A retest reuses the earlier name, so its result replaces the old one.
3. One `agt qa finding --check <check-id> --type bug --body <text>` per verified
   failure; `--type question` for a behavior change the user must confirm.
4. `agt qa run end --run <run>`, with `--usage -` when the harness reports usage.

Report the outcomes from `agt qa list`, not from memory.

## Retest

A retest covers only what the fixes changed:

- the checks whose tests or lint targets cover the changed files, when the
  repository's runner can scope them; otherwise the full check;
- the manual and UX cases whose behavior the changed code affects;
- every check and case that failed last time.

Each retest starts a fresh tester. Never continue an earlier tester.

## Tester steps

### Run the checks

Run the given checks within the scope. Write each full log to the scratch
directory, ending with an `exit N` line. Search the whole log for failures,
errors, and warnings, and match the failure count to the summary line; do not
judge a log from its tail alone. Do not weaken or skip tests. When the repository
enforces size, accessibility, or performance budgets, check whether the change
moves them. Never install dependencies; report missing ones as blocked.

### Choose the cases

Skip this and the next section when the prompt says `Cases: skipped`.

Read repository run instructions and the changed code's callers.
Identify the affected user journeys, commands, or consumers.
Select representative successful inputs and changed boundaries or error paths.
Choose cases that can expose a defect; do not repeat every automated test manually.
Read code only to choose and run cases, never to review the diff itself.
Record the checkout and revision used.

### Exercise the actual behavior

Run repository setup and start commands within the prompt's scope.
Automated tests, static inspection, and screenshots alone do not replace manual interaction.
Follow `ux-verify` for every user-facing result, and `browser` for browser work.

- **UI:** exercise real controls in the browser. Check the affected states,
  layouts, input methods, and themes. Observe resulting state, downloads, or
  navigation. Capture useful screenshots and relevant console or network errors.
- **CLI or service:** run the changed command or request with representative fixtures.
  Inspect output, exit status, error messages, and resulting files or state.
  Check round-trip or output parity when the change can affect them.
- **Runtime-only code** (workers, WASM, a server route): exercise it with a
  realistic input. Running the code finds the most severe defects.
- **Library, configuration, or instructions:** use the consuming tool or a direct
  invocation with representative inputs. For instructions, walk through a realistic
  request and check each decision, reference, and authorization boundary.

State missing credentials, unavailable devices, or unsafe operations as blocked.
Complete reachable checks; do not claim blocked paths passed.
Follow repository rules for server binding, artifact storage, and cleanup.

## Report

With `--fix`, the last retest gives step 4's `Checked:` line.
Repeat affected cases through a retest when a later CI fix or conflict resolution
changes their behavior.

Add test coverage to the report: checks and their results, journeys or commands,
revision, evidence, and untested paths. Keep the tester's results apart from
pending CI.
