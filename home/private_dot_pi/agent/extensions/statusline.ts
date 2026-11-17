/**
 * Statusline in the style of the Claude Code one (~/.claude/statusline-command.sh):
 *   model|ctx%|<git status> repo#branch
 *   ↑in ↓out $cost  <extension statuses>
 * The default branch is hidden, so a bare repo name means "on the default branch".
 */
import { execFile } from "node:child_process";
import { basename, dirname } from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const c = (code: string, s: string) => `\x1b[${code}m${s}\x1b[0m`;
const sep = c("38;5;245", "|");
const fmt = (n: number) => (n < 1000 ? `${n}` : n < 1e6 ? `${(n / 1000).toFixed(1)}k` : `${(n / 1e6).toFixed(1)}M`);

function git(cwd: string, args: string[]): Promise<string> {
	return new Promise((resolve) => {
		execFile("git", ["--no-optional-locks", ...args], { cwd, timeout: 3000 }, (err, out) =>
			resolve(err ? "" : out.trim()),
		);
	});
}

interface GitInfo {
	repo: string;
	branch: string;
	status: string;
}

async function readGit(cwd: string): Promise<GitInfo | undefined> {
	const common = (await git(cwd, ["rev-parse", "--path-format=absolute", "--git-common-dir"])).split("\n")[0];
	if (!common) return undefined;
	const repo = basename(common) === ".git" ? basename(dirname(common)) : basename(common, ".git");
	let branch = (await git(cwd, ["branch", "--show-current"])) || "detached";
	const head = (await git(cwd, ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"])).replace(/^origin\//, "");
	if (head ? branch === head : ["main", "master", "develop", "dev"].includes(branch)) branch = "";

	// Powerlevel10k order: ⇣behind ⇡ahead *stashes ~conflicted +staged !unstaged ?untracked
	let ahead = 0, behind = 0, stash = 0, conflicted = 0, staged = 0, unstaged = 0, untracked = 0;
	for (const line of (await git(cwd, ["status", "--porcelain=v2", "--branch", "--show-stash"])).split("\n")) {
		const f = line.split(" ");
		if (line.startsWith("# branch.ab ")) {
			ahead = Number(f[2]?.slice(1)) || 0;
			behind = Number(f[3]?.slice(1)) || 0;
		} else if (line.startsWith("# stash ")) stash = Number(f[2]) || 0;
		else if (line.startsWith("u ")) conflicted++;
		else if (line.startsWith("1 ") || line.startsWith("2 ")) {
			if (f[1]?.[0] !== ".") staged++;
			if (f[1]?.[1] !== ".") unstaged++;
		} else if (line.startsWith("? ")) untracked++;
	}
	const status = [
		behind && `⇣${behind}`, ahead && `⇡${ahead}`, stash && `*${stash}`,
		conflicted && `~${conflicted}`, staged && `+${staged}`, unstaged && `!${unstaged}`, untracked && `?${untracked}`,
	].filter(Boolean).join(" ");
	return { repo, branch, status };
}

export default function (pi: ExtensionAPI) {
	let info: GitInfo | undefined;
	let cwd = process.cwd();
	let requestRender: (() => void) | undefined;

	const refresh = async () => {
		info = await readGit(cwd);
		requestRender?.();
	};

	pi.on("session_start", async (_e, ctx: ExtensionContext) => {
		cwd = ctx.cwd;
		void refresh();
		ctx.ui.setFooter((tui, _theme, footerData) => {
			requestRender = () => tui.requestRender();
			const unsub = footerData.onBranchChange(() => void refresh());
			return {
				dispose: () => {
					unsub();
					requestRender = undefined;
				},
				invalidate() {},
				render(width: number): string[] {
					let input = 0, output = 0, cost = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type === "message" && e.message.role === "assistant") {
							const m = e.message as AssistantMessage;
							input += m.usage.input;
							output += m.usage.output;
							cost += m.usage.cost.total;
						}
					}
					const usage = ctx.getContextUsage();
					const pct = usage?.percent;
					const ctxSeg =
						pct == null ? c("38;5;245", "?%") : c(pct >= 80 ? "31" : pct >= 60 ? "33" : "32", `${pct.toFixed(1)}%`);

					let loc = c("32", info?.repo ?? basename(cwd));
					if (info?.branch) loc += `${c("38;5;245", "#")}${c("97", info.branch)}`;
					if (info?.status) loc = `${c("36", info.status)} ${loc}`;

					const level = ctx.thinkingLevel && ctx.thinkingLevel !== "off" ? c("38;5;245", `:${ctx.thinkingLevel}`) : "";
					const line1 = [c("34", ctx.model?.id ?? "no-model") + level, ctxSeg, loc].join(sep);

					const stats = c("38;5;247", `↑${fmt(input)} ↓${fmt(output)} $${cost.toFixed(2)}`);
					const statuses = [...footerData.getExtensionStatuses().values()].filter(Boolean).join(" ");
					const line2 = statuses ? `${stats} ${statuses}` : stats;
					return [truncateToWidth(line1, width), truncateToWidth(line2, width)];
				},
			};
		});
	});

	pi.on("turn_end", () => void refresh());
	pi.on("agent_end", () => void refresh());
}
