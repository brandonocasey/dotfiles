# Godot MCP

Godot MCP stays disabled because it scans its project path at every startup.
Only a host whose `~/.codex/config.toml` defines `[mcp_servers.godot-mcp]` has
it; elsewhere, report it unavailable. In a directory that contains
`project.godot`, enable it for one Codex session with:

`codex -c mcp_servers.godot-mcp.enabled=true`

If Codex starts outside the project directory, also override the final `-p`
argument with the absolute directory that contains `project.godot`.
