## Delegation

- Default: one `reviewer`; in a trial, a second, lighter one beside it found
  nothing extra. Setup picks the model ([setup.md](setup.md) **Risk tier**), and
  [loop.md](loop.md) step 2 picks it for fix checks. Keep those choices: in A/B
  tests Sonnet `xhigh` caught 74% of real bugs against Opus `xhigh`'s 91%. Haiku
  held up only on docs-only and test-only changes (43 of 55 findings valid, at a
  sixth of Sonnet's cost); on mixed changes it found 0 of Opus's 13 medium or
  high findings.
- The review skill's step 0–2 owns `--agents` and per-target reviewer sets.

An external tool's findings go through the same re-verification.

Merge the findings and remove duplicates by file, line, and failure scenario. Name the
reviewers that found each finding. Then re-verify each finding in the worktree before
showing or fixing anything: read the cited code, verify the failure scenario is reachable,
and kill anything that isn't concrete. Keep a finding the change did not introduce or
make reachable as `pre-existing` when it is in code the review read; kill other old-code
findings. Kill findings that restore behavior the user or repository rules
deliberately removed, and security findings on the false-alarm list in
[reviewer-steps.md](reviewer-steps.md) step 2. Keep `unverified` host-behavior questions. For `high` and
`medium` bugs, never kill a finding only because its trigger is rare; kill a `low` bug
or nit unless you are certain. A passing test that covers the exact scenario refutes a
finding. When a finding hinges on a test, `ux-verify` case, or benchmark, check
`agt qa list` first. When it lacks that result, start a fresh `tester` for only that
check and record it per [testing.md](testing.md) **Record**. Run it yourself only
under testing.md's inline fallback.
The main session then runs steps 3–5 itself; output.md and loop.md own worktree removal. If a reviewer
stalls or returns nothing, start one fresh reviewer, on another model when available, before
any fallback. If a reviewer could not access the target (missing auth, no checkout) or the
retry also fails, fall back to running the review inline and note that the reviewer is not
independent.

