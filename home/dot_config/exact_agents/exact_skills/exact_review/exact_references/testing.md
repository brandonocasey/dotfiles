## Testing

Every review tests the target before the reviewer starts. A fresh `tester`
sub-agent runs the repository's checks and the manual and UX cases in one pass.
The main session tests itself only in the inline fallback below; it records the
results with `agt qa`, as it records reviewer findings with `agt review`.

The tester always runs the automated checks. `--no-test` skips its manual and UX
cases, as does a change with no runnable behavior: text-only edits, or internal
refactors. State the skip reason in the report. `--test` forces the cases even
then.

Never run manual or UX cases twice on the same commits, just as reviews never
repeat. Before testing, run `agt qa list`. A commit counts as tested when a
passing case ran at it or at a later commit of the branch (the check's head, or
its `--env head=`). `agt qa status` marks a case stale once later commits change
the tree; that alone never untests earlier commits. Test only untested commits
and uncommitted work. Review and CI fix commits are new work: retest the cases
they affect (**Retest**).

A rebase rewrites commits. It is clean when
`git range-diff --creation-factor=100 <old-base>..<old-head> <new-base>..<new-head>`
shows no changed commit; then earlier results stay valid. Otherwise retest only
the cases the changed commits affect.

Retest already tested commits only when:

- a `high` severity bug survives verification: retest the cases it affects;
- the second cycle ([loop.md](loop.md)) retests as it says;
- the user asks to test again.

Automated checks are not limited by these rules.

Keep the review worktree until testing and authorized repairs are complete.
When resuming from a `session-resume` record, apply `session-resume`'s reuse rules.

## Stage order

1. **Test.** After setup, start one fresh `tester` with the prompt below on the
   whole target, or on only its untested part when earlier commits are already
   tested (see above).
2. **Verify.** Re-verify each failure as [delegation.md](delegation.md) re-verifies
   findings: read the cited log lines or evidence and the code they point to. Mark
   a failure the change did not cause as `pre-existing`.
3. **Record.** Record the results (**Record**), with `pre-existing` in the check note.
4. **Fix.** With fix authorization ([fix.md](fix.md)), fix verified failures the
   change caused and leave them uncommitted. Report `pre-existing` ones; fix.md's
   **Scope** rule for them applies. Without authorization, report all of them
   beside the review findings.
5. **Retest.** Start a fresh `tester` on the uncommitted fixes only (**Retest**).
   Verify, record, and fix again. Stop after 3 retests and report failures that
   remain. Then commit the fixes as fix.md's **4. Optional: --fix** section commits
   review fixes (its commit item, not its retest item).
6. **Review.** When steps 4–5 changed the target, committed or not, re-pin it so
   the reviewers see the fixes:
   - MR/PR or branch: rerun setup; its pin ends at the new head.
   - Working diff: rerun setup; it saves a new diff file.
   - Commit, range, or detached branch: keep the store target, but pin the
     reviewer prompt to `<from>..HEAD` (the fix branch's HEAD for a detached
     branch), and pass `--head HEAD` to the first `pass start` too.

   Then start the reviewers per the spawn bullets of [SKILL.md](../SKILL.md)
   steps 0–2. Never pass test results to reviewers.

If a tester stalls or returns nothing, start one fresh tester. If that fails too,
or no sub-agent is available, run **Tester steps** inline and report the tests as
not independent.

After review fixes, retest before each fix check and before the second cycle's
full review ([loop.md](loop.md)). Feed test failures into the same verification
pass; they never start another review cycle.

## Tester prompt

Fill this template and add nothing else. `<scope>` is one of:

- `whole change` for step 1;
- `changed code only: uncommitted fixes on <last-tested-sha>` for a retest of
  uncommitted fixes;
- `changed code only: <last-tested-sha>..<new-head-sha>` for committed changes,
  such as a CI fix, a conflict merge, or a moved head.

For a working-diff target, give the old and new diff paths instead.

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
viewport, theme, OS). For each failure, also the file and line that cause it
when known, and a possible fix.
```

## Record

Record each tester pass in the QA store, with the same store target flag as the
review (`--target <key>` or `--range <range>`; [store.md](store.md)):

1. `agt qa run start` with the tester's `--model`, `--effort`, and `--harness`;
   keep the `run` field of the printed JSON.
2. One `agt qa check --run <run> --name <name> --outcome <outcome> --kind <kind>`
   per returned check or case, with `--command` or `--steps -`, `--evidence` per
   path, `--env key=value` per fact, and `--note` for blocked or skipped reasons.
   A retest reuses the earlier name, so its result replaces the old one.
3. One `agt qa comment --check <check-id> --type bug --severity <high|medium|low>
   --body <text>` per verified failure the change caused, posted as a review comment: add
   `--path <file> --line <n>` (and `--commit <tested-sha>`) when the failure points to
   a line, and put the possible fix in the body, as a suggestion block when it is a
   line change ([remote-comments.md](remote-comments.md)). Use the severity scale of
   [output.md](output.md); `--type question` for a behavior change the user must
   confirm. File a `pre-existing` failure as `--type comment` with a body that starts
   `Pre-existing bug (<severity>):`, so it never blocks approval. The tester's
   identity comes from the check's run.
4. A retest that still fails, or a tester note on an open QA thread (another possible
   fix, a narrower cause), goes on that thread: `agt qa reply <thread-id> --body <text>`
   with the tester's `--model`, `--effort`, and `--harness`. Without them the reply
   posts as the user.
5. `agt qa run end --run <run>`, with `--usage -` when the harness reports usage.
   An ended run accepts no more checks, so record everything first.
6. After stage 5 commits the fixes, resolve each QA thread whose check passed a
   retest: `agt review resolve <thread-id> --fixed <fix-sha>` with the main
   session's `--model`, `--effort`, and `--harness`. A failed retest of a committed
   fix: `agt review resolve <thread-id> --not-fixed "<reason>"` with the tester's
   flags. A working-diff target has no fix commit: leave its threads open and report
   them as fixed in the working tree.
7. **Approve.** After the last retest of the run's final head, run `agt qa status`;
   when `approvable` is true, run `agt qa approve` with the same target flag. It
   records the approval for the summary headline (`🧪 QA approved`) and sends no host
   approval. It refuses a dirty tree, a failing, blocked, or stale check, and an open
   bug, requirement, or question from a check: report its reason instead. A
   working-diff target is never QA approved.

On an own MR/PR, the review's `agt review publish` ([loop.md](loop.md)) posts the QA
comments, replies, and resolves with the review's, signed `🧪 agt QA · <check> · <model>`.

`agt qa check` has no `--head`: on a `--range <from>..<to>` or `--range <sha>` target
it stamps every check at `<to>` or `<sha>`, even after fix commits. Keep the same
target, and add `--env head=<tested-sha>` to each retest check, or
`--env head=<last-tested-sha>+uncommitted` for a retest of uncommitted fixes.

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

### Exercise the actual behavior

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

## Report

With `--fix`, the last retest gives step 4's `Checked:` line.
Repeat affected cases through a retest when a later CI fix or conflict resolution
changes their behavior.

Add test coverage to the report: checks and their results, journeys or commands,
revision, evidence, and untested paths. Keep the tester's results apart from
pending CI.
