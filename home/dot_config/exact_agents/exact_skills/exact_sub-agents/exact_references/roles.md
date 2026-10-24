# Role selection

## Overrides (check first)

- A user-named model overrides the role's pin. Keep the role that fits the work; override only its model and effort.
- Read effort shorthand: `lo`/`low` low, `med`/`medium` medium, `hi`/`high` high, `xhigh`/`x high` xhigh, `max` max.
- Use a user-named custom harness agent. Check the loaded roster; ask if the name is unknown.
- Use a user-requested external tool or agent instead of a sub-agent. Verify its output before acting.

## Roles

Name a role below for every spawn unless the user names another agent.
Claude Code reads `~/.config/agents/agents/<role>.md`; Codex reads
`~/.codex/agents/<role>.toml`. Links for another harness do not prove support.
Check its loaded roster, effective model, thinking setting, and tools before spawning.
If the role is unavailable or incompatible, work inline and report the limitation.

Unless an override applies, keep the role's model and effort pins.
Never use a generic agent (`general-purpose`, `claude`, `default`) for work a role covers.
Omitting the role bypasses its pin: Claude Code uses `CLAUDE_CODE_SUBAGENT_MODEL` (Sonnet), or inherits the parent model when that is unset; Codex uses `default_subagent_model`.
Workflow `agent()` calls follow [workflows.md](workflows.md#agents).

| Role | Work | Claude Code | Codex |
| --- | --- | --- | --- |
| `cheap` | Named command execution, aggregation, formatting, extraction, counting, bulk replacement, factual lookup, watch-and-wait | claude-haiku-5-5, xhigh | gpt-6-luna, xhigh |
| `explorer` | Locate usages and trace code paths; read-only | claude-sonnet-5-5, medium; pass `model: haiku` for usage lists | gpt-6.1-sol, low |
| `worker` | Design, debugging, implementation, orchestrated parts, research synthesis | claude-sonnet-5-5, medium; default sonnet. Pass `model: opus` only for a design decision with no written plan, or a root-cause hunt after a sonnet worker failed once. Never for review fixes, finishing a PR, CI edits, or commit splitting | gpt-6.1-sol, low |
| `tester` | Run checks, manual cases, and UX checks; inspect failures and validate evidence; the `review` skill runs it before every review; read-only | claude-sonnet-5-5, medium | gpt-6.1-sol, low |
| `consult` | Main-session escalation only; read-only | claude-fable-5-1, high | gpt-6-astra, xhigh |
| `reviewer` | Independent adversarial review of a change; the `review` skill runs it for every review; read-only | claude-opus-5-5, xhigh; the `review` skill passes `model: sonnet` for `low` risk tiers and fresh fix checks | gpt-6-astra, xhigh |

Routing:

- Use `cheap` for named commands with explicit pass/fail criteria (a named test, lint, or build run; request exit status and bounded output) and to find one named file, definition, string, or config value; tell it not to edit.
- Use `explorer` to list usages, trace calls, or map affected files.
- Main-session cost is per turn, so delegate when it replaces three or more turns: GitLab, Jira (`jira-api`), Jenkins, or Slack fetches to `cheap`; chained reads to understand code you will not edit, where each read depends on the last, to `explorer`. Claude Code `cheap` has read-only Slack tools; after the user consents to private search, tell it that private search is allowed.
- Use `tester` for manual or UX checks, doc reader passes, and when choosing checks or interpreting failures needs judgment; `worker` for diagnosis and fixes. Escalate `cheap` or `explorer` work to `worker` when it needs judgement.
- Independent review keeps its reviewer role. Do trivial commands inline when spawning costs more.
- Verify the key claims of any `haiku` run before acting on them.
- Without a sub-agent tool, work inline and identify any review that is not independent.
- Choose by total expected context, output, and retry cost, not cache reuse alone.
