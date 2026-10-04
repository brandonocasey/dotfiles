---
name: review
description: >
  Review a PR/MR, branch, commit range, or working diff for verified defects.
  Use for review requests and MR/PR thread checks; --fix fixes and pushes,
  --loop re-reviews, --agents runs parallel reviewers.
---

Review a code change adversarially: assume it is broken and try to prove it. The
deliverable is a set of verified findings the user can act on
as-is — ready-to-post comments for an MR/PR, concrete fixes for local targets — each
explained in plain language. Report verified defects and explicit repository
requirement violations. Include optional style suggestions only when requested.

Arguments: the target (step 0), `--fix` (step 4), `--loop [N]` (step 5),
`--threads` (step 6), and `--agents <model>[:<effort>][,…]` (**Delegation**).
A request to approve or merge is part of step 4.

## Delegation

Delegate the review to sub-agents, so that the reviewer is independent, when:

- this session or its sub-agents wrote the change;
- `--loop` or `--agents` is set;
- the user asks for a hard review or a sub-agent review, or names reviewer models.

Otherwise review inline (an MR/PR from a colleague, an arbitrary commit).

Use `reviewer` for an independent review. Explicitly prohibit edits, commits, cleanup, and further delegation in its prompt. Use `hard-review` when the user requests a hard review.
`--agents` starts one reviewer per entry, in parallel. A request that names models
means `--agents` with one entry per model. The `sub-agents` skill owns model and
effort selection. With several targets, start one reviewer set per target.

Before the spawn, establish the review checkout once (step 0). Install dependencies
and build only when required by the affected checks, commit hooks, or review
evidence; share any required build output across reviewers.
Give every reviewer the same prompt: the review target verbatim, the worktree path, and
the absolute path of [reviewer-steps.md](references/reviewer-steps.md). Never pass the
implementation rationale, earlier findings, or the conversation. Tell reviewers not to
rebuild shared output; a reviewer that starts a server uses its own port. Each reviewer
runs steps 0–2 and returns raw data: file, line, severity, failure scenario, evidence,
and the tests it ran. An external tool's findings go through the same re-verification.

Merge the findings and remove duplicates by file, line, and failure scenario. Name the
reviewers that found each finding. Then re-verify each finding in the worktree before
showing or fixing anything: read the cited code, verify the failure scenario is reachable,
and kill anything that isn't concrete. Do not re-run tests a reviewer already reported
running — re-run only when a finding hinges on a test result the reviewer did not show.
The main session then runs steps 3–4 itself (including worktree removal). If a reviewer
could not access the target (missing auth, no checkout), fall back to running the review
inline and note that the reviewer is not independent.

## Fix authorization

Own work skips the `--fix` gate, whether auto-triggered or user-requested:

- this session's own work;
- the working diff;
- a local branch or commit whose commits all have the author email from
  `git config user.email`;
- an MR/PR whose author is the authenticated user (`gh api user --jq .login` or
  `GITLAB_HOST=<host> glab api user`'s `username`, compared with the MR/PR author).

For own work, apply verified fixes at once per step 4. Re-run tests/lint, and do not
review again unless `--loop` is set. An own MR/PR gets the full MR/PR flow of step 4,
including the push (AGENTS.md Git rules).
For any other target, print the comments and wait for `--fix`. End with:
`Reply fix to apply N findings.`
After a report, a reply that starts with `fix` (`fix`, `fix all`, `fix 2`) means
`--fix` for the same target. Treat every other reply as a normal request.

Before the final review of this session's own work, on a model other than Fable or Astra:
when the Git rules authorize pushing the task branch, push it first. Then inspect CI
failures that already finished, once, per [ci-and-conflicts.md](references/ci-and-conflicts.md),
and fix them; do not wait for a running CI. Without push authorization, review the local branch.

## 0–2. Target, review, verify

Read [reviewer-steps.md](references/reviewer-steps.md) and run steps 0–2, inline or
through **Delegation**.

## 3. Output

When reporting results, read [output.md](references/output.md). It owns the
finding format, remote comment links, evidence, and cleanup. Do not post comments
unless the user asks.

## 4. Optional: --fix

Run this step when **Fix authorization** skips the gate, the user asks (`--fix`, a
`fix` reply, or a later fix request for the same MR/PR), or `--threads` has `valid`
threads that the request covers (fix only those threads):

- **Scope**: fix every surviving `bug` and `requirement`, unless the user names
  a subset. Fix `nit` items only when style changes are requested.
- **Behavior changes**: do not apply a fix that changes user-visible behavior beyond
  what the change or its spec intends. Report it as a `question` with options and a
  recommended default.
- **Questions**: if the answer does not change user-visible behavior, choose the
  recommended answer, apply it, and state the choice in one line.
- With `--fix`, never end with comments for the user to post; apply them.
- End with at most one question, for the excluded items only.

Fix authorization also covers CI failures and clear conflicts for the review target.
Read [ci-and-conflicts.md](references/ci-and-conflicts.md) before these repairs.

- **MR/PR**: follow [remote-fixes.md](references/remote-fixes.md) for refresh,
  repair, verification, commit, push, metadata, and any requested merge.
- **Local branch or commit**: apply the fixes in the branch's worktree, run the repo's
  tests/lint, record the `Checked:` line, and commit per the `commit` skill. For a commit
  or the default branch, first create a fix branch per the `worktree` skill; never commit
  in the main checkout. Do not push. Then remove the worktree if this review created it —
  the commits stay on the branch.
- **Working diff**: apply the fixes in place, record the `Checked:` line, and leave them
  uncommitted unless the user asks to commit.

Report the commits, the `Checked:` line, and the MR/PR link. Remove the worktree per step 3.
End the report with one line: `Ship: pushed <sha> to <branch>` or `Ship: not run (<reason>)`.

## 5. Optional: --loop [N]

`--loop` implies `--fix`. N is the maximum number of rounds. The default is 3.

1. In each round, rebuild in the review worktree after the earlier round's fixes. Then
   start a new reviewer per **Delegation** with the current target only.
2. Re-verify, report, and fix as in steps 2–4. Hold behavior-change `question` items for the user.
3. Kill a finding that an earlier round killed, unless its code changed since that round.
4. Stop after a round with no new `bug` or `question` finding, or after N rounds.
5. Report one numbered list of the held `question` items and any `bug` left after round N.

For an MR/PR, push after each round as step 4 says. Keep the review worktree until the
last round. If no sub-agent is available, stop after round 1 and say that the next reviewer
is not independent. `review-full` does not take `--loop`; it runs one cycle.

## 6. Optional: --threads

Only when the user asks (`--threads`, "are all comments resolved?", "fix and resolve the
comments"). Follow [threads.md](references/threads.md) for the named MR/PR.
