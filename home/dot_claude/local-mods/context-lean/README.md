# context-lean

A Claude Code mod that keeps rarely used tools out of Claude's prompt. Claude can still load any of them through ToolSearch when a task needs one. Run `/context` to see the real context size and what the mod hid.

## What it saves

Measured on 2026-10-13 with Claude Code 2.1.296 and `claude-opus-5-5`, with user settings off (`--setting-sources project`) so only the mod differs. Claude.ai connectors loaded during each session. Tokens per request, two runs each:

| Setup | First request | Last request |
|---|---|---|
| context-lean on | 10,508 | 13,015–13,052 |
| No mod | 17,774 | 37,336–37,406 |

That is about 24,300 fewer tokens on every request once all connectors have loaded. Most of the saving comes from claude.ai connectors, so you save less with fewer connectors enabled. After the first request, most of these tokens are billed as cached reads, so the main gain is context window space.

## What it hides

| What | Change |
|---|---|
| `Artifact`, `ArtifactComments`, `ArtifactData`, `DesignSync` | Deferred. Description gains "Use only when the user explicitly asks for an artifact." The `Artifact` entry in the deferred-tools list is replaced with the same rule. |
| `ScheduleWakeup`, `SendFeedback`, `ReportFindings`, `ListAgents`, `AskUserQuestion`, `Workflow`, `ShareOnboardingGuide`, `Agent` | Deferred and dropped from the deferred-tools list. ToolSearch's description names them as loadable with `select:<name>`. |
| claude.ai connector tools (`mcp__claude_ai_*`) | Deferred and dropped from the deferred-tools list. One line names the hidden connectors so Claude searches for them by keyword. |
| claude.ai connector server notes | Dropped from the prompt. Each connector's notes are attached to the first ToolSearch result or tool call that uses it, once per session and once per subagent, and again after compaction or a reconnect. Connectors in `NOTES` keep theirs in the prompt, and so do notes that first arrive after Claude already used that connector, which happens when it finishes connecting late. When a `## ` line in a connector's notes could also start a local server's notes, that connector's notes stay in the prompt. This happens when the connector comes last in its notes update, or last before connectors with non-ASCII names, which Claude Code sorts after all other servers. |

The `Skill` tool is deferred too; the skill listing gains one line saying to load it with `ToolSearch select:Skill`. In the agent listing, long descriptions of built-in agents (`claude-code-guide`, `general-purpose`, `claude`, `Explore`, `Plan`, `statusline-setup`) become one-line summaries; custom agents are unchanged.

In the main session, each agent listing leaves the prompt and is repeated whole, in order, in the deferred `Agent` tool's description, so Claude reads it only after loading that tool. Subagents share that description but keep their own listing, with built-in descriptions shortened; the description tells a subagent to use only its own listing's types.

Three attachments are trimmed on every request:

| Attachment | Change |
|---|---|
| Email context (`userEmail`) | Dropped. Other context blocks stay. |
| Auto mode note ("While auto mode is active") | Dropped. |
| Environment | The platform, shell and OS version lines are dropped; Claude can run `uname` when it needs them. The working folder, scratchpad and download rules stay. |

The system prompt cannot be changed: Claude Code's built-in security plugin skips `prompt.compose`, `prompt.section` and `prompt.context` hooks from user plugins. Tools a claude.ai connector marks as always loaded, such as Claude Docs' `batch`, `guide` and `update`, are sent before any hook can defer them; disable that connector with `/mcp` to drop them.

Local MCP servers, such as `chrome-devtools`, keep their tools and notes, but their tool names leave the deferred-tools list and join the "findable with ToolSearch" line. All other tools are unchanged. Subagents get the same hiding: in a test, a subagent saw no Datadog or Gmail tool names and got the "findable with ToolSearch" line.

Loading a hidden tool costs one ToolSearch call. In tests, Claude found Datadog for "any error logs for playlist-delivery?" and Google Calendar for "what meetings do I have tomorrow?" without being told the connector names.

## See what it hides

`/context` shows the mod's report in place of the built-in one. The report looks like `/context`, with the real numbers on top and a savings section at the bottom:

- a grid of the context window in `/context`'s colors, with hidden tokens shaded as orange ⛋ boxes after the used squares;
- `/context`'s estimated categories, plus a "Difference from the real total" row for real tokens no category accounts for. "MCP server instructions" counts only notes still sent in the prompt: `/context` counts every connected server's notes, sent or not, and computes "Messages" as the real total minus the other rows. The unsent notes' tokens move to the difference row, not to "Messages", so a short session's messages are not inflated. `/context`'s estimate for messages sent since the last request gets its own row, "Messages since the last request (estimated)", and stays out of the difference row, since the real total does not include those messages yet;
- the usable window, as the built-in `/context` draws it. With `autoCompactWindow` at `433000` on a 1M model, the grid and percentages cover 433k, with a 33k "Autocompact buffer". A "Removed by autocompact window" line shows the 567k of the 1m model window that the setting leaves out;
- how many tokens the mod saved, and the size without it;
- one section each for hidden tool names, hidden tool descriptions, hidden server notes, and notes sent on first use. A section with more than 8 rows shows the 7 largest and folds the rest into one "more" line.

It reports the main session only, not subagents.

The report is drawn in the command's row in the transcript. Claude reads only one summary line, such as `Context: 12k real tokens; context-lean hid 23.9k. [context-lean report <id>]`, about 25 tokens instead of about 2k. The mod keeps the last 20 reports in memory, so after a restart or reload an older row shows only its summary line. Before your first message nothing has been sent, so `/context` shows your last report for the session's current model, with the time it was measured; with no saved report for that model, it runs the built-in command. `/context all` runs the built-in command. If the report cannot be built, the built-in `/context` runs instead.

Counting costs one small request per row to your session's model, about as many input tokens as were hidden. Counts are saved per model and reused across sessions while a row's text stays the same, so switching models back and forth does not count again, and usually only changed rows are counted. Failed counts show as "not counted" and are retried next time. Hidden built-in tools count their descriptions only, not their input schemas, so the real saving is a little higher.

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
