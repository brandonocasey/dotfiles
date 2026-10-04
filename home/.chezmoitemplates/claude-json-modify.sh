#!/usr/bin/env bash
set -euo pipefail
exec node -e 'let text = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => text += chunk);
process.stdin.on("end", () => {
let config;
try {
  config = text.trim() ? JSON.parse(text) : {};
} catch {
  process.stderr.write('"'"'Claude configuration must be a JSON object; no changes written.\n'"'"');
  process.exit(1);
}

if (!config || Array.isArray(config) || typeof config !== "object") {
  process.stderr.write('"'"'Claude configuration must be a JSON object; no changes written.\n'"'"');
  process.exit(1);
}

const servers = config.mcpServers && !Array.isArray(config.mcpServers) &&
  typeof config.mcpServers === "object" ? config.mcpServers : {};
const hasBrowser = Object.values(servers).some((server) => {
  if (!server || typeof server !== "object") return false;
  const command = typeof server.command === "string" ? server.command : "";
  const args = Array.isArray(server.args) ? server.args.join(" ") : "";
  return `${command} ${args}`.includes("chrome-devtools-mcp");
});

if (!hasBrowser && !("chrome-devtools" in servers)) {
  servers["chrome-devtools"] = {
    type: "stdio",
    command: "npx",
    args: ["chrome-devtools-mcp@1.10.1", "--headless", "--isolated"],
  };
}
if (!("openaiDeveloperDocs" in servers)) {
  servers.openaiDeveloperDocs = {
    type: "http",
    url: "https://developers.openai.com/mcp",
  };
}

config.mcpServers = servers;

// The trust dialog never saves trust for the home directory, so it asks on
// every start there. Claude Code still honors this flag when it is set here.
const projects = config.projects && !Array.isArray(config.projects) &&
  typeof config.projects === "object" ? config.projects : {};
// Claude Code keys Windows projects with forward slashes.
const home = process.platform === "win32" ?
  require("os").homedir().replaceAll("\\", "/") : require("os").homedir();
const homeProject = projects[home] && typeof projects[home] === "object" &&
  !Array.isArray(projects[home]) ? projects[home] : {};
homeProject.hasTrustDialogAccepted = true;
projects[home] = homeProject;
config.projects = projects;

process.stdout.write(`${JSON.stringify(config, null, 2)}\n`);
});
'
