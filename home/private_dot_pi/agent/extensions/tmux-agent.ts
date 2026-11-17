/**
 * /clear and /rename commands, plus tmux state: runs the same hook as Claude
 * and Codex (~/.claude/hooks/tmux-bell.sh) so the window list shows the state
 * and the bell rings when pi waits for input. tmux.conf names the window from
 * the terminal title that pi sets (includes the /rename name).
 */
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function mark(state: "working" | "input" | "clear") {
	if (!process.env.TMUX_PANE) return;
	try {
		const child = spawn("sh", [`${homedir()}/.claude/hooks/tmux-bell.sh`, state, "pi"], {
			stdio: "ignore",
			detached: true,
		});
		child.on("error", () => {});
		child.unref();
	} catch {}
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("clear", {
		description: "Start a new session (same as /new)",
		handler: async (_args, ctx) => {
			await ctx.waitForIdle();
			await ctx.newSession();
		},
	});

	pi.registerCommand("rename", {
		description: "Set the session name (same as /name)",
		handler: async (args, ctx) => {
			const name = args.trim() || (await ctx.ui.input("Session name", pi.getSessionName() ?? ""))?.trim();
			if (name) pi.setSessionName(name);
		},
	});

	pi.on("agent_start", () => mark("working"));
	pi.on("agent_end", () => mark("input"));
	pi.on("session_shutdown", (event) => {
		if (event.reason === "quit") mark("clear");
	});
}
