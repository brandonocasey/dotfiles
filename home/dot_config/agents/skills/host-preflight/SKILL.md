---
name: host-preflight
description: Check local or SSH host tool availability before assigning agent work or choosing a host-specific workflow.
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

Godot MCP is globally disabled because it scans its project path during every
startup. In a directory that contains `project.godot`, enable it for one Codex
session with:

`codex -c mcp_servers.godot-mcp.enabled=true`

If Codex starts outside the project directory, also override the final `-p`
argument with the absolute directory that contains `project.godot`.
