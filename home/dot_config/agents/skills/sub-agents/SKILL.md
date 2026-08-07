---
name: sub-agents
description: >
  Shared rules for spawning any sub-agent: model tier and effort selection,
  user-named model and external-tool overrides, self-contained prompts,
  prompt-cache-friendly prompt structure, raw-data returns, and main-session
  re-validation. Other skills (delegate, review) reference this instead of
  duplicating it. Use whenever spawning a sub-agent for any reason.
---

Rules for every sub-agent spawn, regardless of which skill or task triggers it.

## Overrides (check first)

- If the user names a specific model, use that model — it overrides tier choice.
- If the user asks for an external tool or agent (another CLI agent, a hosted
  service), use it in place of a sub-agent. Treat its output like any sub-agent's:
  verify before acting.

## Model tier and effort

Pick tier and reasoning effort to fit the work: cheap tier and low effort for
mechanical or watch-and-wait work; stronger tier only when the work is subtle.
Default to inheriting the session model when unsure.

- Choose only among current-generation, actively maintained frontier models in the
  harness's roster. Never pick an older, deprecated, or weak model just because it
  is cheap — "cheapest tier" means the smallest current model, not a stale one.
- Per-token price dominates cache savings: moving work from a top tier down one
  current tier usually saves money even though the sub-agent starts with a cold
  prompt cache. Do not keep work on an expensive tier just to preserve the cache.

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
  agent (SendMessage or the harness equivalent) instead of spawning a fresh one.

## After they return

- The spawning session re-validates every result before declaring done.
- If a result fails re-validation, fix or redo that part inline in the main
  session. Do not respawn a sub-agent for the same part more than once.
- Clean up anything a sub-agent left behind (worktrees, servers, ports) — unless
  the spawning skill says the artifact is needed (e.g. a review worktree kept for
  re-verification).
