## Delegation

Delegate the review to sub-agents, so that the reviewer is independent, when:

- this session or its sub-agents wrote the change;
- `--loop`, `--deep`, or `--agents` is set;
- the user asks for a sub-agent or independent review.

Otherwise review inline (an MR/PR from a colleague, an arbitrary commit).
Exception: review inline a follow-up delta (`<last-reviewed-sha>..<new-head-sha>`)
on a self-written change that a reviewer already passed, when the delta changes
fewer than 20 lines of logic and touches nothing listed under when-to-run.md
Triggers' risk bullets. It never applies when `--loop`, `--deep`, or `--agents` is set, or
when the user asks for a sub-agent or independent review. Report that the
follow-up review was not independent.
For automatic reviews, [when-to-run.md](when-to-run.md) owns the triggers,
follow-up reviews, and the second-reviewer rule. Inline self-reviews missed about 40% of
the defects found later, against about 18% for independent reviewers.

Use `reviewer` for an independent review. Explicitly prohibit edits, commits, cleanup, and further delegation in its prompt.
`--deep` picks the roles and `--agents` picks the models; they combine.
- Default: one `reviewer`.
- `--deep`: `reviewer` and `deep-review` in parallel on the same target.
- `--agents <model>[:<effort>][,…]`: one `reviewer` per entry, in parallel, on that
  model and effort. With `--deep`, each entry runs both roles.
Without `--agents`, the `sub-agents` skill owns model and effort selection.
With several targets, start one reviewer set per target.

Before the spawn, establish the review checkout once (step 0). Install dependencies
and build only when required by the affected checks, commit hooks, or review
evidence; share any required build output across reviewers.
Pin the target to fixed commits (`<base-sha>..<head-sha>`, or the working diff saved to a
file). Do not commit, amend, or rebase the target while a reviewer runs; one reviewer
reviewed an empty diff because the commit landed first.
Give every reviewer the same prompt: the review target verbatim, worktree path,
the absolute path of [reviewer-steps.md](reviewer-steps.md), applicable
repository constraints, and required check commands. Do not pass implementation
rationale, earlier findings, or conversation history. Tell reviewers not to
rebuild shared output; a reviewer that starts a server uses its own port. Each reviewer
runs steps 0–2 and returns raw data: file, line, severity, failure scenario, evidence,
and the tests it ran. An external tool's findings go through the same re-verification.

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
