---
name: review
description: "Review PRs/MRs, diffs, commits, branches, or threads for verified defects; supports fixes and review loops."
---

Scope: Review PRs/MRs, branches, commits, diffs, or review threads for verified defects, including automatic completion reviews. Supports fixes, review loops, and parallel reviewers.


Review a code change adversarially: assume it is broken and try to prove it. The
deliverable is a set of verified findings the user can act on
as-is — ready-to-post comments for an MR/PR, concrete fixes for local targets — each
explained in plain language. Report verified defects and explicit repository
requirement violations. Include optional style suggestions only when requested.

Arguments: the target (step 0), `--fix` (step 4), `--loop [N]` (step 5),
`--threads` (step 6), and `--agents <model>[:<effort>][,…]` (**Delegation**).
A request to approve or merge is part of step 4.

## Automatic completion review

For automatic completion reviews, read [completion.md](references/completion.md).

## Delegation

Before delegating a review of your own work, --loop, --agents, or an explicitly requested independent review, read [delegation.md](references/delegation.md).

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

For --threads or requests to fix or resolve review comments, read [thread-routing.md](references/thread-routing.md).
