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
explained in plain language.

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

Brief beats complete-sounding: no padding, no restating the diff.

1. **TLDR line** — one sentence: how many findings survived, and whether any are real bugs
   vs. minor notes.
2. **What the change does** — 1–2 plain-language sentences a non-expert could follow. No
   project codenames without a gloss.
3. **One block per surviving finding**, most-severe first, each led by a severity label:
   `bug` (wrong behavior reachable in production), `question` (design choice worth confirming
   with the author), `nit` (cosmetic/noise). Per block:
   - **Where**: file + line. For an MR/PR, add a clickable link (formats in `remote-comments.md`, linked at the end of this step) so the
     comment can be left right there; for local targets, use `path:line` (clickable in the
     terminal).
   - **Why it matters**: 1–3 plain-language sentences — what goes wrong, when, and why it
     matters. Jargon spelled out.
   - **Comment to post** (MR/PR) — ready-to-paste text (this one can be technical): factual,
     no hedging, no AI-flavored preamble; state the failure scenario concretely. Where a
     small code change fixes it, include a suggestion block (syntax in the same file).
     **Fix** (local targets) — the concrete change as a small code snippet or exact edit.
4. **What was checked and cleared** — up to 4 one-line bullets naming candidate issues that
   did not survive verification and why each was killed. This is the proof the review was real.

If nothing survives verification, say so plainly — the cleared list plus "nothing real found"
is a valid result. Do not post anything to the MR/PR unless the user asks; step 6 lists what
`--threads` may post. Print for the user to post. For an MR/PR, put all comments in one copy
file, `review-<number>.md`, numbered by finding, and add follow-ups to it. Report CI and
conflict status separately, with the observed source SHA and job or pipeline links.
Pending checks are unverified, not passing.

Clean up automatically when the review ends. Never ask first, and never hand cleanup to the
user. Remove the worktree this review created — never a pre-existing one — with
`git -C <main-checkout> worktree remove <the .worktrees/review-… path from step 0>`, per the `worktree` skill's
**Remove** section (clean tree, shell moved out first). Also remove this review's scratch
directory, and stop the servers, browser pages, and ports it started. Run cleanup as its own
command. Run it before approve, merge, or other outward steps, so a blocked outward step
cannot block it. When continuing to `--fix`, keep the worktree until the remote source
branch holds the review worktree's HEAD (`git ls-remote origin refs/heads/<source-branch>`
equals `git rev-parse HEAD`) and no repair is pending. The remote is then the backup: clean
up at once. If a later CI failure needs a repair, recreate the worktree from the remote
branch. A review that leaves `.worktrees/review-…` behind is incomplete: the report's last
line names the removed path or the blocker.

For MR/PR comment links and suggestion syntax, read
[remote-comments.md](references/remote-comments.md). Local reviews do not need it.

## 4. Optional: --fix

Run this step when **Fix authorization** skips the gate, the user asks (`--fix`, a
`fix` reply, or a later fix request for the same MR/PR), or `--threads` has `valid`
threads that the request covers (fix only those threads):

- **Scope**: fix every surviving `bug` and `nit`, unless the user names a subset.
- **Behavior changes**: do not apply a fix that changes user-visible behavior beyond
  what the change or its spec intends. Report it as a `question` with options and a
  recommended default.
- **Questions**: if the answer does not change user-visible behavior, choose the
  recommended answer, apply it, and state the choice in one line.
- With `--fix`, never end with comments for the user to post; apply them.
- End with at most one question, for the excluded items only.

Fix authorization also covers CI failures and clear conflicts for the review target.
Read [ci-and-conflicts.md](references/ci-and-conflicts.md) before these repairs.

- **MR/PR**: in the review worktree:
  1. Fetch the source branch. If its head moved, check each finding again and drop stale ones.
  2. Apply the fixes. Remove narrating comments that this MR/PR adds, per `code-standards`.
     Do not touch existing comments.
  3. Resolve clear conflicts with the target branch and fix `new in this change` CI
     failures, per ci-and-conflicts.md.
  4. Run the repo's tests/lint. Check the fixed HEAD by hand (AGENTS.md manual-check rule;
     methods in `review-full` **Exercise the actual behavior**). Record one line:
     `Checked: <steps, page or command, config> -> <result>`, or `Checked: n/a (<reason>)`
     for docs-, test-, or config-only fixes.
  5. Commit through the `commit` skill. Keep the branch's scope and ticket style, but take
     the type from its **Choosing the type** procedure; carry any issue-tracker reference
     from the MR/PR title. Push to the source branch — the review
     worktree is detached, so use `git push origin HEAD:<source-branch>`. For a fork MR/PR,
     `origin` is the base repo: push to the fork's URL instead
     (`git push <fork-url> HEAD:<source-branch>`). That needs push access to the fork and
     leaves `.git/config` unchanged.
  6. Sync the title and description to the final diff, per `ship` step 3, and read them
     back. Then refresh the source SHA, CI, and mergeability once, per ci-and-conflicts.md.
  7. Clean up per step 3. Then, when the request asks to approve or merge, run the `ship` skill's
     [merge.md](../ship/references/merge.md) after the push, only when no `bug` or
     `question` finding remains. Otherwise skip it and name the blocking findings.
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
