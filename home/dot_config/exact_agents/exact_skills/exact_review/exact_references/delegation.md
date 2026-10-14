## Delegation

Always delegate the review to the `reviewer` sub-agent, whatever the target:
own work, a colleague's MR/PR, an arbitrary commit, or a follow-up delta.
Explicitly prohibit edits, commits, cleanup, and further delegation in its prompt.
- Default: one `reviewer`. In a side-by-side trial, a second, lighter reviewer
  beside it found nothing extra. In a real-bug A/B test, Sonnet `xhigh` alone
  caught 74% of bugs against Opus `xhigh`'s 91%, so Sonnet does not review.
- The review skill's step 0–2 owns `--agents` and per-target reviewer sets.

Start each reviewer with the setup prompt from [setup.md](setup.md), verbatim. Never
add a summary of the change, focus areas, what already passed, or earlier findings: that
framing steers reviewers away from the code. Only a fix check adds the inputs
[loop.md](loop.md) lists. An external tool's findings go through the same re-verification.

Merge the findings and remove duplicates by file, line, and failure scenario. Name the
reviewers that found each finding. Then re-verify each finding in the worktree before
showing or fixing anything: read the cited code, verify the failure scenario is reachable,
and kill anything that isn't concrete. Also kill findings the change did not introduce or
make reachable, and findings that restore behavior the user or repository rules
deliberately removed. Keep `unverified` host-behavior questions. For `high` and
`medium` bugs, never kill a finding only because its trigger is rare; kill a `low` bug
or nit unless you are certain. A passing test that covers the exact scenario refutes a
finding. Use `ui-verify` or the repository's benchmark when a finding needs that evidence. Do not re-run tests a reviewer already reported
running — re-run only when a finding hinges on a test result the reviewer did not show.
The main session then runs steps 3–4 itself (including worktree removal). If a reviewer
stalls or returns nothing, start one fresh reviewer, on another model when available, before
any fallback. If a reviewer could not access the target (missing auth, no checkout) or the
retry also fails, fall back to running the review inline and note that the reviewer is not
independent.
