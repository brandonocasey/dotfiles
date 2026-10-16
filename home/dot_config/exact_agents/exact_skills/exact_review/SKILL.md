---
name: review
description: "Review PRs/MRs, diffs, commits, branches, or threads for verified defects; supports fixes and review loops."
---

Review a code change adversarially: assume it is broken and try to prove it. The
deliverable is a set of verified findings the user can act on
as-is — ready-to-post comments for an MR/PR, concrete fixes for local targets — each
explained in plain language. Report verified defects and explicit repository
requirement violations. Include optional style suggestions only when requested.

Arguments: `--test` and `--no-test` (**Manual testing**), `--fix` (steps 4–5), and
`--agents <model>[:<effort>][,…]` (**Delegation**). A request in words to fix,
approve, or merge, or that names reviewer models counts as the matching flag.

## Automatic completion review

For automatic reviews of this session's work, read [when-to-run.md](references/when-to-run.md).

## Delegation

Every review runs through the `reviewer` sub-agent. After the reviewers return, read [delegation.md](references/delegation.md).

## Manual testing

Manually test the changed behavior by default; `--no-test` skips it. Read
[manual-testing.md](references/manual-testing.md) for skip rules, cases, and evidence.

## Fix authorization

Before deciding whether review findings may be fixed, read **Fix authorization** in [fix.md](references/fix.md).

## 0–2. Target, review, verify

Before the spawn, the main session reads no review references except when-to-run.md, and it never reviews
the code itself. Start one `cheap` sub-agent with exactly this prompt:

```text
Set up a review pass per <absolute path of references/setup.md>.
Target: <the user's target verbatim; a range or MR/PR the calling skill or loop names; or none>.
Scratch: <task scratch directory>. Earlier worktree: <path or none>.
```

- Run setups one at a time, never in parallel.
- On `empty`, say there is nothing to review and stop. On `checks: unclear` or a
  blocker, rerun the prompt with the `worker` role, adding `Judgement: allowed`, any
  reported worktree, and started checks. If the worker is still blocked, clean up
  per [output.md](references/output.md), report the blocker to the user, and stop.
- Start one `reviewer` with the returned prompt verbatim, or one per `--agents`
  `<model>[:<effort>]` entry on that model and effort; with several targets, one set
  per target. Otherwise the `sub-agents` skill sets model and effort.
- On `skip` (2 or more prior reviews of the pinned head and 0 open items), report
  `Skipped: <short-sha> already has <N> reviews` with the record links and stop.
  Setup stops before checkout, so there is nothing to clean up.
  With `--approve`, `--auto-merge`, or `--merge`, skip only the review and still run
  step 7.
  A request to review again overrides this. Never pass records to reviewers.
- With `own: yes`, the review posts and resolves MR/PR comments per **Own MR/PR
  comments** in [remote-comments.md](references/remote-comments.md). With `own: no`,
  it posts nothing unless the user asks.
- Never add a summary of the change, focus areas, what already passed, or earlier
  findings. That framing steers reviewers away from the code. Only a fix check and
  the cycle 2 reveal add the inputs [loop.md](references/loop.md) lists.
- Use the returned worktree; the manual pass uses it too.
- On `mutations unsupported`, run no `--fix`, `--threads`, or merge step.
- Give each reported linked MR/PR its own pass, read-only: apply `--fix`, `--threads`,
  approval, and merge only to MRs/PRs that the user named or authored.
- Use the reported CI facts in the step 3 report.

After the reviewers return, re-verify per **Delegation**, reading only the code each
finding depends on: the cited lines, their callers, and any guard that could refute it.
Read [reviewer-steps.md](references/reviewer-steps.md) only for an inline fallback.

## 3. Output

When reporting results, read [output.md](references/output.md). It owns the
finding format, remote comment links, evidence, and cleanup. Post comments only on
an own MR/PR, or when the user asks.

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
