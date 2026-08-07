---
name: delegate
description: >
  Decide whether and how to pass work to sub-agents. Covers: monitoring and
  long-running waits (cheapest background agent), tasks changing 5+ non-doc files
  with independent parts (parallel cheaper sub-agents, main-session re-validation), and
  moving a whole task to a different tier (warn, then single sub-agent on approval).
  Spawn mechanics live in the sub-agents skill. Use when starting a task that may
  be worth delegating, when the user says "delegate this", or when invoked as
  /delegate.
---

Pass work to sub-agents when it saves cost or keeps the main session free — and only
then. The main session always owns the result: it re-validates whatever comes back
before declaring done.

Every spawn follows the `sub-agents` skill.

## Monitoring and long-running waits

Polling CI, watching logs, waiting on builds/deploys: delegate to a background agent
on the smallest, cheapest model tier available at the lowest reasoning effort. The
agent reports back only the outcome and relevant details. The main session continues
other work or ends its turn; it never polls the same target itself.

## Large splittable tasks

Split automatically — without being asked — when the task will change 5+ files
(excluding documentation) and divides into independent parts that each need
substantial reading or editing on their own (multi-file migrations, broad audits,
repetitive edits). Fan the parts out to parallel sub-agents on a cheaper
current-generation tier, each with a self-contained prompt and non-overlapping file
ownership. When they return, re-validate all results in the main session before
declaring done.

If the parts share most of their context, or the task is small or sequential, run
it inline — each spawned agent re-pays the shared context, so splitting a
medium-sized task costs MORE than doing it inline.

## Tier mismatch (moving the whole task)

This section applies only when moving the WHOLE current task to a single sub-agent
on a different tier. Tier choice for monitoring, fan-out parts, and review
sub-agents follows the `sub-agents` skill and needs no consent.

If a different tier fits the whole task better — stronger because the current tier
has already failed an attempt or the task needs subtle cross-cutting reasoning, or
weaker because the task is simple enough that a cheaper current tier suffices
(usually a net saving even though the sub-agent starts with a cold prompt cache) —
warn the user first. On approval, delegate to a single sub-agent on that tier with
the full context it needs.
