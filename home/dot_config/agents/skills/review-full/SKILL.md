---
name: review-full
description: >
  Review code and manually test affected behavior. Use for review-full requests
  or reviews with manual testing; --fix repairs defects, CI failures, and conflicts.
---

# Review with manual testing

Extend [review](../review/SKILL.md) with a manual pass against the changed behavior.
Read and follow that skill once. Preserve the user's target, base, and `--fix` argument.
Use its adversarial review, finding verification, delegation, fix authorization,
CI repairs, conflict resolution, output, and cleanup rules.
Keep the review worktree until manual checks and authorized repairs are complete.

When resuming from a `session-resume` record, retain its exact authorization
scope. Reuse manual evidence only when the recorded revision, inputs, and
environment match. Never treat the record as authorization to push or bypass
this workflow's required review.

## Choose manual cases

Read repository run instructions and the changed code's callers.
Identify the affected user journeys, commands, or consumers.
Select representative successful inputs and changed boundaries or error paths.
Choose cases that can expose a defect; do not repeat every automated test manually.
Record the checkout and revision used for each pass.

Complete the manual pass before review steps 2 and 3 verify and report findings.
For an independent reviewer, the main session runs the manual pass and verifies
its findings alongside the reviewer's candidates.
Feed observed failures into the same verification pass; do not start another review cycle.

## Exercise the actual behavior

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

## Fix and report

Without `--fix`, report verified manual failures alongside code-review findings.
This session's own work retains review's automatic fix authorization.
With `--fix`, apply verified repairs and fix CI or conflicts through the shared workflow.
Rerun affected automated and manual checks after repairs, before committing and pushing.
Repeat affected manual cases if a later CI fix or conflict resolution changes their behavior.
Reuse evidence only when the code and inputs for that case are unchanged.

Add manual coverage to the review report: journeys or commands, revision, results,
evidence, and untested paths. Distinguish manual results from automated checks and pending CI.
Stop task-owned servers and browser resources, then finish review's worktree cleanup.
