---
name: sub-agents
description: >
  Shared rules for spawning any sub-agent: tier and effort selection (Claude and GPT
  tiers), model/tool overrides, self-contained prompts, raw-data returns, main-session
  re-validation, background monitoring, and escalation of a hard sub-problem to a
  stronger tier. Load whenever spawning a sub-agent for any reason.
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

Pick the tier by task class and set the model explicitly in the spawn call. The tier is the rule; the
names in brackets are only today's examples. Read the real tiers from the models the
harness offers, cheapest to most capable. Choose only current-generation, actively
maintained models — "cheapest tier" means the smallest current model, not a stale one.

| Tier | Claude | GPT | Work |
| --- | --- | --- | --- |
| Cheapest | Haiku | GPT 5.6 Luna | Mechanical, well-specified: data aggregation, reformatting, extraction, counting, bulk find-and-replace, web research, watch-and-wait. Low reasoning effort |
| Middle | Sonnet | GPT 5.6 Luna | Codebase exploration and search: locating usages, tracing call paths, "where/how is X done" fan-out |
| Judgement | Opus | GPT 5.6 Terra | Design, tricky debugging, cross-file reasoning, anything ambiguous |
| Top | Fable | GPT 5.6 Sol | Only as the target of an escalation from the main session (see below). Never for splits, monitoring, or review sub-agents; that work stays in the main session, or goes to a forked agent that inherits the parent model where the harness offers one |

Escalate one tier when a simple-looking task turns out to need judgement.

Per-token price dominates cache savings: moving work from a top tier down one
current tier usually saves money even though the sub-agent starts with a cold prompt
cache. Do not keep work on an expensive tier just to preserve the cache.

## Prompts

- Make each prompt self-contained: the task, the exact files/targets, and the
  acceptance criteria. Sub-agents cannot see the conversation.
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

## Escalate to a stronger tier

Only the main session — the one the user drives — may escalate. Sub-agents never
escalate; they report blocked and the main session decides. Each escalation goes one
tier up from the session's tier, so a middle-tier session (Sonnet, Luna) calls the
judgement tier (Opus, Terra), and a judgement-tier session calls the top tier
(Fable, Sol). Escalate again only if the first escalation also fails.

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
