---
name: review
description: "Review PRs/MRs, diffs, commits, branches, or threads for verified defects; supports fixes and review loops."
---

Review a code change adversarially: assume it is broken and try to prove it. The
deliverable is a set of verified findings the user can act on
as-is — ready-to-post comments for an MR/PR, concrete fixes for local targets — each
explained in plain language. Report verified defects and explicit repository
requirement violations. Include optional style suggestions only when requested.

Arguments: the target (step 0), `--test` and `--no-test` (**Manual testing**),
`--deep` and `--agents <model>[:<effort>][,…]` (**Delegation**), `--fix` (step 4),
`--loop [N]` (step 5), `--threads` (step 6), and `--approve`, `--auto-merge`, and
`--merge` (step 7). A request in words to approve or merge, for a deep or hard
review, or that names reviewer models counts as the matching flag.

## Automatic completion review

For automatic completion reviews, read [completion.md](references/completion.md).

## Delegation

Before delegating a review of your own work, --loop, --deep, --agents, or an explicitly requested independent review, read [delegation.md](references/delegation.md).

## Manual testing

Manually test the changed behavior by default; `--no-test` skips it. Read
[manual-testing.md](references/manual-testing.md) for skip rules, cases, and evidence.

## Fix authorization

Before deciding whether review findings may be fixed, read [fix-authorization.md](references/fix-authorization.md).

## 0–2. Target, review, verify

Read [reviewer-steps.md](references/reviewer-steps.md) and run steps 0–2, inline or
through **Delegation**.

## 3. Output

When reporting results, read [output.md](references/output.md). It owns the
finding format, remote comment links, evidence, and cleanup. Do not post comments
unless the user asks.

## 4. Optional: --fix

For authorized fixes, including your own work, read [fix.md](references/fix.md).

## 5. Optional: --loop [N]

For --loop, read [loop.md](references/loop.md).

## 6. Optional: --threads

Only when the user asks (`--threads`, "are all comments resolved?", "fix and resolve the
comments"). Follow [threads.md](references/threads.md) for the named MR/PR.

## 7. Optional: --approve, --auto-merge, --merge

For --approve, --auto-merge, --merge, or a request to approve or merge, read
[approve-merge.md](references/approve-merge.md).
