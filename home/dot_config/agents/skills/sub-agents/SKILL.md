---
name: sub-agents
description: >
  Use when spawning, monitoring, or escalating sub-agents. Owns model
  selection, prompts, handoffs, and result verification across harnesses.
---

Rules for every sub-agent spawn, regardless of which skill or task triggers it. The
spawning session always owns the result (**After they return**).

## Overrides (check first)

- If the user names a specific model, use that model — it overrides the role's pin.
- If the user names a custom harness agent, use it for the assignment. Check
  that it exists in the loaded roster; ask if the name is unknown.
- If the user asks for an external tool or agent (another CLI agent, a hosted
  service), use it in place of a sub-agent. Treat its output like any sub-agent's:
  verify before acting.

## Roles (mandatory)

Every spawn MUST name one of these roles unless the user names another agent.
Claude Code reads `~/.config/agents/agents/<role>.md`; Codex reads
`~/.codex/agents/<role>.toml`. A symlink for another harness does not prove that
it loads these files or supports their metadata. Check its loaded roster,
effective model, thinking setting, and tools before spawning. If the required
role is unavailable or incompatible, work inline and report the limitation.
Never spawn a sub-agent without a role or a user-named agent, never pass
a `model` or effort that differs from the role's pin, and never use the harness's
generic default agent (`general-purpose`, `claude`, `default`) for work a role
covers. A spawn that omits the role gets the parent model (Claude Code) or the
harness's `default_subagent_model` (Codex) instead of the pin, which is a defect.
The user's named model, custom harness agent, or external tool is the only override.

| Role | Work | Claude Code | Codex |
| --- | --- | --- | --- |
| `cheap` | Mechanical, well-specified: aggregation, formatting, extraction, counting, bulk replacement, factual lookup, watch-and-wait | haiku, low | gpt-6-luna, low |
| `explorer` | Codebase exploration: locating usages, tracing call paths. Read-only | sonnet, medium | gpt-6-luna, xhigh |
| `worker` | Design, debugging, implementation of one split part, review, research synthesis | opus, low | gpt-6-sol, low |
| `consult` | Escalation by the main session only (see below). Read-only | fable, low | gpt-6-astra, low |

Harness forks (`subagent_type: "fork"` in Claude Code) inherit the parent model and
are allowed only where a skill explicitly asks for an inherited-context fork.

Escalate to `worker` when a `cheap` or `explorer` task turns out to need judgement.
If the harness has no sub-agent tool, do the work inline and state when a review is
not independent.

Compare total expected cost, including context, cache, output, and likely retries.
Do not keep work on an expensive role solely to preserve its cache.

## Prompts

- Make each prompt self-contained: the task, the exact files/targets, and the
  acceptance criteria. Conversation inheritance depends on the harness and spawn
  options; do not rely on context that was not passed. Independent reviewers get
  only the review skill's permitted context.
- Sub-agents return raw results (data, findings, paths), not prose for the user.
- Sub-agents do not spawn further sub-agents. The Claude Code role files deny the
  `Agent` tool; the Codex role files forbid it by instruction only.

## Prompt caching

- When spawning several sub-agents for one task, keep the shared context and
  instructions as an identical prefix across their prompts and put the per-part
  variation (file list, item under review) at the end, so cached tokens are reused.
- For follow-up work that shares a sub-agent's existing context, continue that
  agent instead of spawning a fresh one, where the harness supports it.

## Monitoring and long waits

Polling CI, watching logs, waiting on builds or deploys: spawn a `cheap`
background agent. It reports back only the outcome and the relevant
details. The main session continues other work or ends its turn; it never polls the
same target itself.

Exception: never watch an MR/PR or its pipeline for success on your own — no watcher
agent, no polling. Report the pipeline URL and stop. Watch one only when the user
asks for it.

## Escalate with `consult`

Only the main session — the one the user drives — may escalate. Sub-agents never
escalate; they report blocked and the main session decides. The session's own model
is stated in its system prompt. If the session already runs on the `consult` model
(fable, gpt-6-astra), no stronger model exists: continue inline or report the
concrete blocker. Do not invent a model.

- **A hard sub-problem, task stays here** — trigger: one failed attempt, a failure the
  user reports in your work ("still broken", a wrong result, a regression), or
  reasoning that spans files or systems beyond what the session resolved. Spawn one `consult`
  agent with a self-contained question: the problem, the evidence gathered so far,
  the files involved, and what a good answer must settle. No user approval is
  needed because the session keeps the task. Re-validate the answer before acting
  on it. Escalate the same sub-problem at most once.
- **The whole task, on a different model** — stronger because the session already
  failed an attempt or the task needs subtle cross-cutting reasoning; weaker because
  the task is simple enough for a cheaper role. Warn the user first, with the reason.
  On approval, hand the whole task to one `worker` (or `consult` when `worker` is the
  current model) with the full context it needs.
- In the main session, before reporting blocked or a second fix attempt after the user reports a
  failure, on a `cheap`, `explorer`, or `worker` model: check that you spawned
  `consult` once for that sub-problem. Sub-agents report the concrete blocker to
  the main session without spawning.

## After they return

- The spawning session re-validates every result before declaring done.
- If a result fails re-validation, fix or redo that part inline in the main
  session. Do not respawn a sub-agent for the same part more than once.
- Clean up anything a sub-agent left behind (worktrees, servers, ports) — unless
  the spawning skill says the artifact is needed (e.g. a review worktree kept for
  re-verification).
