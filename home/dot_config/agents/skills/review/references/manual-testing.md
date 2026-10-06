## Manual testing

Manually test the changed behavior by default. Skip it only for `--no-test`, or
when the change has no runnable behavior: text-only edits, or internal refactors
whose automated tests pass. State the skip reason in the report. `--test` forces
the manual pass even then.

Keep the review worktree until manual checks and authorized repairs are complete.
When resuming from a `session-resume` record, retain its exact authorization
scope. Reuse manual evidence only when the recorded revision, inputs, and
environment match. Never treat the record as authorization to push or bypass
the required review.

### Choose manual cases

Read repository run instructions and the changed code's callers.
Identify the affected user journeys, commands, or consumers.
Select representative successful inputs and changed boundaries or error paths.
Choose cases that can expose a defect; do not repeat every automated test manually.
Record the checkout and revision used for each pass.

Complete the manual pass before steps 2 and 3 verify and report findings.
With delegated reviewers, the main session runs the manual pass and verifies
its findings alongside the reviewers' candidates.
Feed observed failures into the same verification pass; do not start another review cycle.

### Exercise the actual behavior

Run repository setup and start commands yourself within the authorized scope.
Automated tests, static inspection, and screenshots alone do not replace manual interaction.

- **UI:** load `ui-verify` and `browser`, then exercise real controls in the browser.
  Check the affected states, layouts, input methods, and themes.
  Observe resulting state, downloads, or navigation. Capture useful screenshots
  and relevant console or network errors.
- **CLI or service:** run the changed command or request with representative fixtures.
  Inspect output, exit status, error messages, and resulting files or state.
  Check round-trip or output parity when the change can affect them.
- **Library, configuration, or instructions:** use the consuming tool or a direct
  invocation with representative inputs. For instructions, walk through a realistic
  request and check each decision, reference, and authorization boundary.

Record the actions, inputs, expected result, observed result, and pass/fail evidence.
For browser checks, include engine, viewport, theme, and state where relevant.
State missing credentials, unavailable devices, or unsafe operations as coverage blockers.
Complete reachable checks; do not claim blocked paths passed.
Follow repository rules for server binding, artifact storage, and cleanup.

### Fix and report

Without `--fix`, report verified manual failures alongside code-review findings.
With `--fix`, the rerun manual cases give step 4's `Checked:` line.
Rerun affected automated and manual checks after repairs, before committing and pushing.
Repeat affected manual cases if a later CI fix or conflict resolution changes their behavior.
Reuse evidence only when the code and inputs for that case are unchanged.

Add manual coverage to the report: journeys or commands, revision, results,
evidence, and untested paths. Distinguish manual results from automated checks and pending CI.
Stop task-owned servers and browser resources before worktree cleanup.
