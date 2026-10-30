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
| Local MCP server tools (`mcp__<server>__*`), except the desktop app's `ccd_*` servers | Deferred and dropped from the deferred-tools list, like connector tools. Their server notes are deferred the same way once the server's tool names have been seen, in this or an earlier session; the first session after a new server appears keeps them. The `ccd_*` servers stay loaded because the app's task list and wrap-up use them; change `KEPT_LOADED` in `hooks/register.ts` to keep others loaded. |
| claude.ai connector server notes, and local server notes as above | Dropped from the prompt. Each connector's notes are attached to the first ToolSearch result or tool call that uses it, once per session and once per subagent, and again after compaction or a reconnect. Connectors in `NOTES` keep theirs in the prompt, and so do notes that first arrive after Claude already used that connector, which happens when it finishes connecting late. When a `## ` line in a connector's notes could also start a local server's notes, that connector's notes stay in the prompt. This happens when the connector comes last in its notes update, or last before connectors with non-ASCII names, which Claude Code sorts after all other servers. |

The `Skill` tool is deferred too; the skill listing gains one line saying to load it with `ToolSearch select:Skill`. In the agent listing, long descriptions of built-in agents (`claude-code-guide`, `general-purpose`, `claude`, `Explore`, `Plan`, `statusline-setup`) become one-line summaries; custom agents are unchanged.

In the main session, each agent listing leaves the prompt and is repeated whole, in order, in the deferred `Agent` tool's description, so Claude reads it only after loading that tool. Subagents share that description but keep their own listing, with built-in descriptions shortened; the description tells a subagent to use only its own listing's types.

Three attachments are trimmed on every request:

| Attachment | Change |
|---|---|
| Email context (`userEmail`) | Dropped. Other context blocks stay. |
| Auto mode note ("While auto mode is active") | Dropped. |
| Environment | The platform, shell and OS version lines are dropped; Claude can run `uname` when it needs them. The working folder, scratchpad and download rules stay. |

The system prompt cannot be changed: Claude Code's built-in security plugin skips `prompt.compose`, `prompt.section` and `prompt.context` hooks from user plugins. Tools a claude.ai connector marks as always loaded, such as Claude Docs' `batch`, `guide` and `update`, are sent before any hook can defer them; disable that connector with `/mcp` to drop them.

Local MCP servers, such as `chrome-devtools` or the desktop app's built-in browser, are deferred too, and their tool names join the "findable with ToolSearch" line. Their server notes are sent with the first ToolSearch result or call that uses them, like a connector's. A local server's notes stay in the prompt when they sit after a connector's notes in the update, since the mod cannot tell them from that connector's sub-headings. All other tools are unchanged. Subagents get the same hiding: in a test, a subagent saw no Datadog or Gmail tool names and got the "findable with ToolSearch" line.

Loading a hidden tool costs one ToolSearch call. In tests, Claude found Datadog for "any error logs for playlist-delivery?" and Google Calendar for "what meetings do I have tomorrow?" without being told the connector names.

## See what it hides

`/context` shows the mod's report in place of the built-in one. The report looks like `/context`, with the real numbers on top and the savings in its sections:

- a grid of the context window in `/context`'s colors and size: 10 by 10 squares below a 1m window, 20 by 10 from 1m, and 5 columns in a terminal under 80 wide. Hidden tokens show as orange open squares ⛶ after the used squares, since that space stays free; their "Saved" legend line sits under "Free space" as part of it. "System prompt", "System tools" and the difference row get colors of their own, since `/context` draws them in grays close to free space;
- `/context`'s estimated categories ("Memory files" shown as "Memory & Markdown"), with "Messages" given back the real tokens no category accounts for. "MCP server instructions" counts only notes still sent in the prompt: `/context` counts every connected server's notes, sent or not, and computes "Messages" as the real total minus the other rows. So `/context`'s Messages comes out short by the unsent notes, and the report adds the real tokens no row accounts for back to it. A "Difference from real" row appears only when the rows' estimates exceed the real total. Messages also keeps `/context`'s estimate for messages sent since the last request;
- the usable window. With `autoCompactWindow` at `433000` on a 1M model, percentages are of the 400k left before the 33k "Autocompact buffer", so free space and the top line leave the buffer out; the buffer's own line is a share of 433k. The grid then covers the whole 1m model window at `/context`'s 1m size (20 by 10, 5k a square): the usable part fills the first squares, and the 567k the setting cuts takes its true share of the last ones, as dull red crossed squares ⛝, with a "Cut by autocompact window" line;
- how many tokens the mod saved and their share of the size without it, in bold orange at the top. Side lines leave out the word "tokens" to keep the report narrow;
- the built-in `/context`'s sections (MCP tools, custom agents, memory files, skills), plus a System tools section listing the built-in tools sent in full (as seen by the mod; `/context all` names them), built from the session's usage breakdown. System prompt and Messages sections appear only when Claude Code's breakdown includes their details, which 2.1.296 does not give mods. All are shown with the savings merged in. The mod never runs the built-in command for a report: Claude Code then drops the mod's answer and sends the built-in's full text to Claude. "MCP tools" starts with an orange "Saved by context-lean" total for connector and local server tool names, descriptions and notes, with one line per kind under it. "Custom agents" gets the same for shortened built-in agent descriptions and the moved agent listing. "System tools" gets one for built-in tool descriptions and names. Trimmed attachments get their own "Saved by context-lean" section at the end. The Messages section splits messages into yours, Claude's, tool calls, tool results and attachments (by type with `/context all`), as estimated.

`/context all` lists every saved item instead of one line per kind, in the same places, and adds server notes sent on first use or kept in the prompt to "MCP tools" as plain lines. A kind with more than 8 rows shows the 7 largest and folds the rest into one "more" line. The built-in sections list each server, agent, file and skill. Other arguments, such as `/context tools`, run the built-in command.

It reports the main session only, not subagents.

The report is drawn in the command's row in the transcript. Claude reads only one summary line, such as `Context: 12k real tokens; context-lean hid 23.9k. [context-lean report <id>]`, about 25 tokens instead of about 2k. The mod keeps the last 20 reports in memory, so after a restart or reload an older row shows only its summary line. Before your first message nothing has been sent, so there is no real size. Then `/context` sends `ping` just after the command finishes, and draws the report under Claude's reply once it ends (only you see it), waiting up to 3 seconds for the session's usage to count the ping. That costs one small request. Claude Code sends no attachments with a prompt a mod submits, so the ping's turn sends no tool list or server notes; your next message does. That report shows the tool names and server notes the mod last hid, in any session, as estimates of what your next message will hide, marked "estimated". Their counts are usually reused, since these texts rarely change. Before the mod has ever hidden them, the MCP tools section says nothing is hidden yet. A second `/context` before anything was counted runs the built-in command. If the report cannot be built, the built-in `/context` runs instead.

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
