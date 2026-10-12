# hide-connectors

Keeps claude.ai connector tool names out of Claude's prompt. Their tools still work: Claude finds them with ToolSearch when a task needs them.

## What it saves

About 15k tokens on every request with Datadog connected, measured on 2026-10-12 with the `~/.claude-two` config. The first row is one run; the others are two:

| Setup | First request | Last request |
|---|---|---|
| This mod on, Datadog connected | 17,475 | 19,943 |
| No mod, Datadog connected | 32,652 | 34,334–34,462 |
| No mod, Datadog denied | 21,119 | 22,874–22,950 |

Datadog alone costs about 11.5k tokens per request without this mod. Most of the saving is context window space; after the first request, these tokens are billed as cached reads.

## What it hides

For each tool named `mcp__claude_ai_<Server>__<tool>`, the mod:

1. Defers the tool, so its schema is not sent until ToolSearch loads it.
2. Removes its name from the deferred-tools list.
3. Removes the server's block from the MCP server instructions, unless the server is in `NOTES`.
4. Adds one line naming the hidden servers, so Claude knows to search for them.

Local MCP servers, such as `chrome-devtools`, are never hidden.

## Choose which server notes stay

Server notes kept in the prompt are listed in `NOTES` in `hooks/register.ts`:

```ts
const NOTES = new Set(['Atlassian', 'Atlassian_MCP'])
```

Keep notes for a connector when its tools need setup steps that tool names can't show. Atlassian's notes explain getting a site ID and finding operations before running them. Datadog, Notion and Claude Docs also send notes; they are dropped because they cost more than they help here.

Each entry is the `<Server>` part of the tool name, for example `Atlassian_MCP` for `mcp__claude_ai_Atlassian_MCP__search`. After editing, run `claude plugin test .` and start a new session.
