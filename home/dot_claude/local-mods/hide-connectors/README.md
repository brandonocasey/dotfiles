# hide-connectors

Keeps claude.ai connectors you rarely use out of Claude's prompt. Their tools still work: Claude finds them with ToolSearch when a task needs them.

## What it saves

About 15k tokens on every request with Datadog connected, measured on 2026-10-12 with the `~/.claude-two` config:

| Setup | First request | Last request |
|---|---|---|
| This mod on, Datadog connected | 17,673 | 19,353–19,641 |
| No mod, Datadog connected | 32,652 | 34,334–34,462 |
| No mod, Datadog denied | 21,119 | 22,874–22,950 |

Datadog alone costs about 11.5k tokens per request without this mod. Most of the saving is context window space; after the first request, these tokens are billed as cached reads.

## What it hides

For each tool named `mcp__claude_ai_<Server>__<tool>` whose `<Server>` is not kept, the mod:

1. Defers the tool, so its schema is not sent until ToolSearch loads it.
2. Removes its name from the deferred-tools list.
3. Removes the server's block from the MCP server instructions.
4. Adds one line naming the hidden servers, so Claude knows to search for them.

Local MCP servers, such as `chrome-devtools`, are never hidden.

## Choose which connectors stay listed

Kept connectors are listed in `KEEP` in `hooks/register.ts`:

```ts
const KEEP = new Set(['Atlassian', 'Atlassian_MCP', 'Slack'])
```

Each entry is the `<Server>` part of the tool name, for example `Google_Calendar` for `mcp__claude_ai_Google_Calendar__list_events`. To keep a connector listed, add its name, run `claude plugin test .`, and start a new session.

Every connector not in `KEEP` is hidden, including ones connected later.
