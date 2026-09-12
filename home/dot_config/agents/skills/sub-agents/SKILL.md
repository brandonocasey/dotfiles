---
name: sub-agents
description: >
  Use when spawning, monitoring, or escalating sub-agents. Owns model
  selection, prompts, handoffs, and result verification across harnesses.
---

Rules for every sub-agent spawn, regardless of which skill or task triggers it. The
spawning session always owns the result: it re-validates whatever comes back before
declaring done.

## Overrides (check first)

- If the user names a specific model, use that model — it overrides tier choice.
- If the user asks for an external tool or agent (another CLI agent, a hosted
  service), use it in place of a sub-agent. Treat its output like any sub-agent's:
  verify before acting.

## Model tier and effort

Pick the tier by task class from models actually offered by the harness. Use its
model and effort controls when available. Do not infer current availability, price,
or capability order from a model name. Prefer current, actively maintained models;
check provider metadata or official docs when the roster does not establish this.
These rules apply to Claude, GPT, and other model families.

| Tier | Work |
| --- | --- |
| Cheapest | Mechanical, well-specified: aggregation, formatting, extraction, counting, bulk replacement, factual web lookup, watch-and-wait. Low effort |
| Middle | Codebase exploration: locating usages and tracing call paths |
| Judgement | Design, debugging, cross-file reasoning, research synthesis, ambiguous work |
| Top | Escalation by the main session only; do not explicitly select it for splits, monitoring, or review. Those may run in the main session or inherit its model through a supported fork |

Several task classes may map to the same offered model. If the harness cannot select
a tier, use its supported inheritance behavior and disclose that limit. If no
sub-agent tool exists, do the work inline and state when a review is not independent.

Escalate one tier when a simple-looking task turns out to need judgement.

Compare total expected cost, including context, cache, output, and likely retries.
Do not keep work on an expensive tier solely to preserve its cache, or assert a
saving when current prices and usage are unknown.

## Prompts

- Make each prompt self-contained: the task, the exact files/targets, and the
  acceptance criteria. Conversation inheritance depends on the harness and spawn
  options; do not rely on context that was not passed. Independent reviewers get
  only the review skill's permitted context.
- Sub-agents return raw results (data, findings, paths), not prose for the user.
- Sub-agents do not spawn further sub-agents unless their prompt explicitly says to.

## Prompt caching

- When spawning several sub-agents for one task, keep the shared context and
  instructions as an identical prefix across their prompts and put the per-part
  variation (file list, item under review) at the end, so cached tokens are reused.
- For follow-up work that shares a sub-agent's existing context, continue that
  agent instead of spawning a fresh one, where the harness supports it.

## Monitoring and long waits

Polling CI, watching logs, waiting on builds or deploys: spawn a cheapest-tier
background agent at low effort. It reports back only the outcome and the relevant
details. The main session continues other work or ends its turn; it never polls the
same target itself.

Exception: never watch an MR/PR or its pipeline for success on your own — no watcher
agent, no polling. Report the pipeline URL and stop. Watch one only when the user
asks for it.

## Escalate to a stronger tier

Only the main session — the one the user drives — may escalate. Sub-agents never
escalate; they report blocked and the main session decides. Each escalation goes one
tier up from the session's mapped tier. Escalate again only if the first escalation
also fails. If no stronger supported model exists, continue the investigation inline
or report the concrete blocker; do not invent a model or a higher tier.

- **A hard sub-problem, task stays here** — trigger: one failed attempt, or reasoning
  that spans files or systems beyond what the current tier resolved. Spawn one agent
  on the next tier up with a self-contained question: the problem, the evidence
  gathered so far, the files involved, and what a good answer must settle. No user
  approval is needed because the session keeps the task. Re-validate the answer
  before acting on it.
- **The whole task, on a different tier** — stronger because the current tier already
  failed an attempt or the task needs subtle cross-cutting reasoning; weaker because
  the task is simple enough that a cheaper current tier suffices. Warn the user
  first, with the reason. On approval, hand the whole task to one sub-agent on that
  tier with the full context it needs.

## After they return

- The spawning session re-validates every result before declaring done.
- If a result fails re-validation, fix or redo that part inline in the main
  session. Do not respawn a sub-agent for the same part more than once.
- Clean up anything a sub-agent left behind (worktrees, servers, ports) — unless
  the spawning skill says the artifact is needed (e.g. a review worktree kept for
  re-verification).
