# context-lean

A Claude Code mod that keeps rarely used tools out of Claude's prompt. Claude can still load any of them through ToolSearch when a task needs one. Run `/context-lean` to see the real context size and what the mod hid.

## What it saves

Measured on 2026-10-12 with Claude Code 2.1.296, `claude-opus-5-5` and the `~/.claude-two` config, Datadog connected. Two runs each:

| Setup | First request | Last request |
|---|---|---|
| context-lean on | 14,227–14,361 | 15,727–15,995 |
| No mod | 25,309 | 38,591–38,594 |

That is about 22,700 fewer tokens on every request once all connectors have loaded. After the first request, most of these tokens are billed as cached reads, so the main gain is context window space.

## What it hides

| What | Change |
|---|---|
| `Artifact`, `ArtifactComments`, `ArtifactData`, `DesignSync` | Deferred. Description gains "Use only when the user explicitly asks for an artifact." The `Artifact` entry in the deferred-tools list is replaced with the same rule. |
| `ScheduleWakeup`, `SendFeedback`, `ReportFindings`, `ListAgents`, `AskUserQuestion`, `Workflow`, `ShareOnboardingGuide`, `Agent` | Deferred and dropped from the deferred-tools list. ToolSearch's description names them as loadable with `select:<name>`. |
| claude.ai connector tools (`mcp__claude_ai_*`) | Deferred and dropped from the deferred-tools list. One line names the hidden connectors so Claude searches for them by keyword. |
| claude.ai connector server notes | Dropped from the prompt. Each connector's notes are attached to the first ToolSearch result or tool call that uses it, once per session and once per subagent. Connectors in `NOTES` keep theirs in the prompt. |

Local MCP servers, such as `chrome-devtools`, and all other tools are unchanged. Subagents get the same hiding: in a test, a subagent saw no Datadog or Gmail tool names and got the "findable with ToolSearch" line.

Loading a hidden tool costs one ToolSearch call. In tests, Claude found Datadog for "any error logs for playlist-delivery?" and Google Calendar for "what meetings do I have tomorrow?" without being told the connector names.

## See what it hides

Run `/context-lean` at any time. It looks like `/context`, with the real numbers on top and a savings section at the bottom:

- a grid of the context window in `/context`'s colors, with hidden tokens shaded as orange ⛋ boxes after the used squares;
- `/context`'s estimated categories, plus a "Difference from the real total" row when the real size from the API differs;
- how many tokens the mod saved, and the size without it;
- one section each for hidden tool names, hidden tool descriptions, hidden server notes, and notes sent on first use. A section with more than 8 rows shows the 7 largest and folds the rest into one "more" line.

It reports the main session only, not subagents.

Before your first message nothing has been sent, so it shows your last report instead, with the time it was measured. With no saved report yet, it asks you to send a message first.

Counting costs one small request per row to your session's model, about as many input tokens as were hidden. Counts are saved and reused across sessions while a row's text and the model stay the same, so usually only changed rows are counted again. Failed counts show as "not counted" and are retried next time. Hidden built-in tools count their descriptions only, not their input schemas, so the real saving is a little higher.

The mod saves what it hid per session in its plugin store, so a resumed session still reports it. It keeps the last 10 sessions.

## Keep server notes in the prompt

By default every connector's server notes wait until the connector is used. To keep a connector's notes in the prompt from the start, add it to `NOTES` in `hooks/register.ts`:

```ts
const NOTES = new Set(['Atlassian_MCP'])
```

Each entry is the `<Server>` part of the tool name, for example `Atlassian_MCP` for `mcp__claude_ai_Atlassian_MCP__search`. After editing, run `claude plugin test .` and start a new session.

## Install

```
claude plugin marketplace add ~/.claude/local-mods
claude plugin install context-lean@local-mods
```

Restart Claude Code after installing.
