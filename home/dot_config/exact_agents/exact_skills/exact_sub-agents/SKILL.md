---
name: sub-agents
description: "Select, prompt, monitor, and verify sub-agents across Claude and Codex."
---

When the assignment includes Git work, read the global [Git policy](../shared/git-policy.md) before spawning. Every spawn follows these rules. The spawning session owns verification and cleanup.

Before choosing a role, model, or effort, read [roles.md](references/roles.md). It owns overrides, role pins, routing, and compatibility checks; [escalation.md](references/escalation.md) owns escalation.

## Prompts

- Include the task, owned files or targets, acceptance criteria, necessary evidence, and required checks. Do not rely on unpassed context.
- Spawn independent tasks without conversation history. In Codex, explicitly set `fork_turns="none"`; its omission can inherit the full conversation. Use a Claude named role rather than a conversation fork (forks inherit the parent model); fork only when a skill requests inherited context.
- Give independent reviewers only the context permitted by the `review` skill.
- For roles with `omitClaudeMd: true`, include applicable repository constraints, required checks, allowed output paths, and any relevant global consent, destination, resource, or test protections absent from the role. Pass only what the assignment needs; do not paste the global rules or transcript.
- The spawning session owns testing and review (see After they return). Give an implementing agent only the fast checks scoped to its owned files (targeted tests, lint or type checks for those paths) and the repository constraints that govern them; keep repo-wide gates, review, and manual or UX checks out of its prompt.
- Paste inputs under about 2k tokens (8k characters). Pass larger ones (diffs, logs, data, file contents) as file paths, and tell the agent to search or read only the parts it needs. Workflow scripts write large computed inputs under the task's scratch directory and pass the path.
- When passing `model: opus`, state the reason in the prompt's first line.
- Request raw results: data, findings, and paths, not prose for the user.
- Tell an agent that implements a change to write `<scratch>/<task>/decisions.md` before handing back, at most 40 lines: choices made, why, and what must not change. Pass its path to every later fix or docs agent for that change, and tell them that a fix conflicting with it comes back as a question, not a change.
- Name a result path, `<scratch>/<task>/<role>-<n>.md`. Tell agents: if the result exceeds ~40 lines, write it there and return at most 5 lines: path, counts, status. Read-only Codex roles (`explorer`, `consult`) cannot write; ask them for at most 40 lines. Read only the parts of a result file you need.
- Fetch diffs, logs, and browser evidence through `cheap` agents first; they write raw output under the task's scratch directory and pass paths on.
- Delegate web page and doc reads (WebFetch) to an agent; return only the needed excerpt.
- Sub-agents never spawn sub-agents. Claude Code role files deny `Agent`; Codex role files enforce this only through instructions.
- A denied action stays denied. Never reach its effect through another command, script, or test. Test destructive tools against a fake root, such as `AGT_CLEANUP_TMP`, never live paths.

## Prompt caching

Give parallel agents identical shared instruction prefixes, then the differing file lists or review items.
Continue an existing agent for related follow-up work when the harness supports it and its last turn ended under 5 minutes ago. Otherwise spawn a fresh agent and pass the earlier results as file paths: continuing an agent whose cache expired rewrites its whole context. The `continue-guard` hook blocks such late continuations when the context is 50k tokens or more.
A sub-agent that stops while its own background job runs must keep a background `agt wait` waiter, so it wakes every 4.5 minutes; the `subagent-wait` hook enforces this. The hook cannot act after a `SubagentHandback`, which also delivers only one report, so tell agents that start background jobs to stop with plain text while they wait and hand back once, at the end. After 10 minutes of waiting on the same work, the hook makes it hand back with `HANDOFF: <file>`; tell agents to start a job expected to run longer detached and hand off at once. The `bash-guard` hook blocks sub-agent foreground calls with a timeout over 4.5 minutes. Then wait on the job's done condition in a background command, and spawn a fresh agent with that file.

## Conditional procedures

- Before writing or starting a Workflow, read [workflows.md](references/workflows.md).
- Before monitoring a command or external target, read [monitoring.md](references/monitoring.md).
- After a failed attempt leaves unresolved reasoning, read [escalation.md](references/escalation.md) before escalating or reporting blocked.

## After they return

- Check high-risk claims inline. Give bulk checking to a fresh agent that writes a verdict file; read only its failed or unverified lines.
- Fix or redo failed results inline. Do not respawn for the same part more than once.
- When an agent changed code, tests, or config: for an orchestrated task, follow the `orchestrate` skill; otherwise run the repository's required pre-commit checks inline before committing, then the `review-fix` skill on the diff at a review end point per [when-to-run.md](../review/references/when-to-run.md) (it runs the tester and reviewer). Feed the agent's open problems and `decisions.md` into it.
- Clean up per [task-resources.md](../host-preflight/references/task-resources.md). Keep evidence awaiting re-verification.
