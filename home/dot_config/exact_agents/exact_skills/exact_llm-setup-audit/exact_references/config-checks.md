# Config coverage checks

- **Coverage:** each file that a hook or `statusLine` command names must appear in `chezmoi managed`.
- **Empty hooks:** report hook events with no commands, such as `"PreToolUse": []`.
- **Parity:** list each Claude hook with no Codex equivalent in `~/.codex/hooks.json`, and the reverse.
- **Secrets:** run the `dotfiles-sync` secret scan on the chezmoi source; report per AGENTS.md. Propose a move to the secret store for each.
- **Tool search:** flag `ENABLE_TOOL_SEARCH=false` in a Claude profile's settings `env`, a custom `ANTHROPIC_BASE_URL`, or a `ToolSearch` deny rule.
  Each turns tool search off, so every MCP tool schema loads in full on each call.
- **MCP servers:** check use per [runtime.md](runtime.md).
