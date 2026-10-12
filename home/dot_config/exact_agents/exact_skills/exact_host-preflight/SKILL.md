---
name: host-preflight
description: "Check local or SSH tool availability before unfamiliar tools, agent assignments, or host-specific workflows."
---

Run `agent-preflight` before work depends on tools that can differ by host. It
prints bounded JSON with the OS, current directory, Git context, selected CLI
paths, and safe capability flags. It does not print environment
variables or tokens.

For an SSH host, run `agent-preflight --remote user@host`. The remote check uses
batch mode, a ten-second connection timeout, and no remote command from SSH
configuration. It does not install or change anything. Treat an empty tool path
as unavailable. Report the missing command and inspected host. The check also
looks in `~/.local/bin`, `~/bin`, and standard Homebrew prefixes.
When `on_path` is false, use the returned absolute path.

## Conditional procedures

- When a task needs Godot MCP, read [godot.md](references/godot.md).
- Before starting servers, creating temporary task resources, or cleaning them
  up, read [task-resources.md](references/task-resources.md).
- For commands or text the user must copy, read
  [copyable-output.md](references/copyable-output.md).
