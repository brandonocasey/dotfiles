# Measure runtime spend

Scan the last 30 days once, instead of writing a new parser:

```sh
agt sessions report --sections cost,tools,cache-gaps --limit 50
```

It reads Claude and Codex transcripts (`--harness claude|codex` narrows it).
It skips scratch and probe projects unless `--scratch` is given.
`--by agent,model,project,session,file,harness` regroups cost.
Prices come from `~/.config/agt/model-prices.json`.
Add `agents` and `hooks` to `--sections` when `agt sessions report --help` lists them.
Otherwise report those checks as not run, with the agt version.
Never read transcript files whole.

- **Spend:** rank cost by agent and model.
  Tie large tool-result shares, such as `Read:skills/rules`, to the rule or skill that causes them.
- **Main thread and agents:** report files read by both in one session, and result tokens agents return to the main thread.
  Propose passing paths instead of contents, narrower reads, or shorter results, in `sub-agents` or the role body.
- **Spawn prompts:** report prompt tokens and lines repeated in 3 or more prompts.
  Propose moving repeated text into the role body or `sub-agents`.
  Keep text that a role with `omitClaudeMd: true` needs and cannot load.
- **Hooks:** report the context each hook adds, per event and command.
  Propose trimming or silencing output the model does not act on.
  Keep output that guards an authorization boundary or stop point.
- **MCP:** list each configured server per harness with its `mcp:<server>` calls.
  Propose disabling servers with no calls, or narrowing Codex `enabled_tools`.
  Account connectors (`claude_ai_*`) are not in config files; propose disconnecting unused ones in claude.ai settings.
- **Cache gaps:** report rewrite tokens by agent.
  Tie long gaps to a rule or hook that causes the wait, if any.

Check each top finding against one transcript before proposing a change.
Read a bounded window around the record, not the whole file.
