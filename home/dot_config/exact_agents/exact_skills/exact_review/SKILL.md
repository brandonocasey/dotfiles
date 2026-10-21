---
name: review
description: "Review PRs/MRs, diffs, commits, branches, or threads for verified defects; supports fixes and review loops."
---

Review a code change adversarially: assume it is broken and try to prove it. The
deliverable is a set of verified findings the user can act on
as-is — ready-to-post comments for an MR/PR, concrete fixes for local targets — each
explained in plain language. Report verified defects and explicit repository
requirement violations. Include optional style suggestions only when requested.

Arguments: `--test` and `--no-test` (**Testing**), `--fix` (steps 4–5), and
`--agents <model>[:<effort>][,…]` (**Delegation**). A request in words to fix,
approve, or merge, or that names reviewer models counts as the matching flag.

## Automatic completion review

For automatic reviews of this session's work, read [when-to-run.md](references/when-to-run.md).

## Delegation

Every review runs through the `reviewer` sub-agent. After the reviewers return, read [delegation.md](references/delegation.md).

## Testing

A `tester` sub-agent runs the checks and the manual and UX cases before the
reviewer starts; `--no-test` skips only the cases. Read
[testing.md](references/testing.md) for the stage order, retests, and `agt qa` records.

## Fix authorization

Before deciding whether review findings may be fixed, read **Fix authorization** in [fix.md](references/fix.md).

## 0–2. Target, review, verify

Before the spawn, the main session reads no review references except when-to-run.md,
[setup.md](references/setup.md), [testing.md](references/testing.md), and the
references testing.md names for verifying and fixing test failures. It never reviews
or tests the code itself, except in testing.md's inline fallback. Run setup
yourself per setup.md, with `agt`, `git`, and `gh`/`glab` commands; no sub-agent.
Its inputs: the user's target verbatim (a range or MR/PR the calling skill or loop
names, or none), the task scratch directory, any earlier review worktree, and the skip
check (on for a run's first setup; off when the user asks to review again, and for
later passes).

- Run setups one at a time, never in parallel.
- On `empty`, say there is nothing to review and stop. On a blocker, clean up per
  [output.md](references/output.md), report it to the user, and stop.
- Run the testing stage in [testing.md](references/testing.md) first. Start the
  reviewers only after its last retest.
- Start one `reviewer` with the filled prompt verbatim, or one per `--agents`
  `<model>[:<effort>]` entry on that model and effort; with several targets, one set
  per target. Otherwise the `sub-agents` skill sets model and effort; when the
  current risk tier is `low`, pass `model: sonnet` (effort stays `xhigh`).
- On `skip` (own MR/PR only: `agt review status --head <sha>` on its store target
  shows `reviews_at_head` of 2 or more and 0 open threads; [store.md](references/store.md)),
  report `Skipped: <short-sha> already has <N> reviews` with the run IDs and stop.
  Setup stops before checks; clean up any worktree it reports per
  [output.md](references/output.md).
  With `--approve`, `--auto-merge`, or `--merge`, skip only the review and still run
  step 7.
  A request to review again overrides this. Never pass records to reviewers.
- With `own: yes`, the review posts and resolves MR/PR comments per **Own MR/PR
  comments** in [remote-comments.md](references/remote-comments.md). With `own: no`,
  it posts nothing unless the user asks.
- Never add a summary of the change, focus areas, what already passed, or earlier
  findings. That framing steers reviewers away from the code. Only a fix check and
  the cycle 2 reveal add the inputs [loop.md](references/loop.md) lists.
- Use the returned worktree; the tester uses it too.
- On `mutations unsupported`, run no `--fix`, `--threads`, or merge step.
- Give each reported linked MR/PR its own pass, read-only: apply `--fix`, `--threads`,
  approval, and merge only to MRs/PRs that the user named or authored.
- Use the reported CI facts in the step 3 report.
- The risk tier is the highest of setup's `risk`, the reviewers' `Risk:` lines, and
  `high` when a security finding or `high` bug survives. A new head resets it.

After the reviewers return, re-verify per **Delegation**, reading only the code each
finding depends on: the cited lines, their callers, and any guard that could refute it.
Record every pass, its verified and killed findings, and the run in the store per
[store.md](references/store.md).
Read [reviewer-steps.md](references/reviewer-steps.md) only for an inline fallback.

## 3. Output

When reporting results, read [output.md](references/output.md). It owns the
finding format, remote comment links, evidence, and cleanup. Post comments only on
an own MR/PR, or when the user asks, and only with `agt review publish`
(`publish --not-own --only <ids>` on another person's MR/PR, per
[output.md](references/output.md);
[store.md](references/store.md)).

## 4. Optional: --fix

For authorized fixes, including your own work, read [fix.md](references/fix.md).
Fixing always continues into step 5.

## 5. Fix loop

Every review that fixes runs the loop in [loop.md](references/loop.md).

## 6. Optional: --threads

Only when the user asks (`--threads`, "are all comments resolved?", "fix and resolve the
comments"). Follow [threads.md](references/threads.md) for the named MR/PR.

## 7. Optional: --approve, --auto-merge, --merge

For --approve, --auto-merge, --merge, a request to approve or merge, or a fix
pushed to an MR/PR, read [approve-merge.md](references/approve-merge.md). Each
marks a draft MR/PR ready.
