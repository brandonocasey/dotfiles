---
name: host-preflight
description: "Check local or SSH tool availability before unfamiliar tools, agent assignments, or host-specific workflows."
---

Run `agent-preflight` before work depends on tools that can differ by host. For
an SSH host, run `agent-preflight --remote user@host`. Treat an empty tool path
as unavailable; report the missing command and inspected host. When `on_path`
is false, use the returned absolute path.

## Conditional procedures

- When a task needs Godot MCP, read [godot.md](references/godot.md).
- Before starting servers, creating temporary task resources, or cleaning them
  up, read [task-resources.md](references/task-resources.md).
- For commands or text the user must copy, read
  [copyable-output.md](references/copyable-output.md).
