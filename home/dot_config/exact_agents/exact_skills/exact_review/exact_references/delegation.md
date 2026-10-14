## Delegation

Always delegate the review to the `reviewer` sub-agent, whatever the target:
own work, a colleague's MR/PR, an arbitrary commit, or a follow-up delta.
Explicitly prohibit edits, commits, cleanup, and further delegation in its prompt.
- Default: one `reviewer`. In a side-by-side trial, a second, lighter reviewer
  beside it found nothing extra. In a real-bug A/B test, Sonnet `xhigh` alone
  caught 74% of bugs against Opus `xhigh`'s 91%, so Sonnet does not review.
- `--agents <model>[:<effort>][,…]`: one `reviewer` per entry, in parallel, on that
  model and effort.
Without `--agents`, the `sub-agents` skill owns model and effort selection.
With several targets, start one reviewer set per target.

Before the spawn, establish the review checkout once (step 0). Install dependencies
and build only when required by the affected checks, commit hooks, or review
evidence; share any required build output across reviewers.
After any required install, start the repository's full test, lint, and typecheck
commands once in the background, on the pinned target. Write each full log to a file
in the task scratch directory, ending with an `exit N` line. Pass the log paths and
commands to every reviewer and start the reviewers without waiting, so parallel
reviewers do not repeat the checks. A failing check is evidence: reviewers decide
whether the change caused it. Run the checks again for each new pinned target,
including each fix-loop pass.
Pin the target to fixed commits (`<base-sha>..<head-sha>`, or the working diff saved to a
file). Do not commit, amend, or rebase the target while a reviewer runs.
Give every reviewer the same prompt, built only from this template. Fill the fields
and add nothing else:

```text
Review <target verbatim> for verified defects. Read-only: no edits, commits,
cleanup, or sub-agents.
Worktree: <path>
Steps: follow <absolute path of reviewer-steps.md>, steps 0-2.
Repository rules: <paths of AGENTS.md / CLAUDE.md / CONTRIBUTING.md that apply>
Checks: <commands, or log paths with their commands>
Severity scale: <pasted from output.md>
Return raw data: file, line, severity, failure scenario, evidence, tests run.
```

For an MR/PR, the target is its URL, so the reviewer reads the author's title and
description the way a human reviewer does. Never write your own summary of the
change, what to focus on, what to skip, what already passed, or where code came
from ("copied unchanged", "already in use"). That framing steers the reviewer away
from the code that needs review. Do not pass earlier findings or conversation
history. Exception: a fix-loop fix check
passes the inputs [loop.md](loop.md) lists, to continued or fresh reviewers. Tell reviewers not to
rebuild shared output; a reviewer that starts a server uses its own port. Each reviewer
runs steps 0–2 and returns raw data: file, line, severity, failure scenario, evidence,
and the tests it ran. Paste the severity scale from [output.md](output.md) into the prompt. An external tool's findings go through the same re-verification.

Merge the findings and remove duplicates by file, line, and failure scenario. Name the
reviewers that found each finding. Then re-verify each finding in the worktree before
showing or fixing anything: read the cited code, verify the failure scenario is reachable,
and kill anything that isn't concrete. Do not re-run tests a reviewer already reported
running — re-run only when a finding hinges on a test result the reviewer did not show.
The main session then runs steps 3–4 itself (including worktree removal). If a reviewer
stalls or returns nothing, start one fresh reviewer, on another model when available, before
any fallback. If a reviewer could not access the target (missing auth, no checkout) or the
retry also fails, fall back to running the review inline and note that the reviewer is not
independent.
