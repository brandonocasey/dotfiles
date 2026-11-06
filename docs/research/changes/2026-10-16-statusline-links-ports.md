# Statusline links, ports and agent rows

- Status (2026-11-06): current. `home/dot_claude/executable_statusline-command.sh` prints the project name as a link to the repo, the LAN IP and session port as a link, and usage segments as links to the usage settings page; `home/dot_claude/executable_subagent-statusline-command.sh` (wired as `subagentStatusLine` in `claude-settings-modify.sh`) shows model, context, worker name and activity in agent rows; `home/dot_claude/hooks/executable_session-port.sh` reserves each session a block of 10 ports. Minor UX, not a rule.
- Topic: Terminal and UI
- Related: [Tmux hyperlink passthrough for Ghostty](2026-10-15-tmux-hyperlinks-ghostty.md), [Session titles with port and branch](2026-11-06-session-titles-port-branch.md), [Prompt-cache TTL and permission denies](2026-10-14-cache-ttl-and-permission-denies.md)

## Change
- The status line project name links to the repo (OSC 8 link); the worktree branch segment links to the location.
- Session IP and port block: `session-port.sh` (SessionStart hook) reserves a block of 10 dev-server ports in 40000-48999 per session, exports `PORT` and `PORT_1` to `PORT_9` to the session's Bash commands, and the statusline shows `<lan-ip>:<port>` as a link (red when a process from a different session holds the port).
- Usage segments link to the Claude usage settings page.
- Agent rows (shown when the user views a subagent): model and context first, then worker name, then what the agent is doing.

## History
- 2026-10-15 — session 46d4871f: user: "we need to add hostname or ip addr to statusline, let's talk through it so that it doesn't make my statusline huge." Follow-ups in the same session: merge cache time with the context percent, show ip and port together, make `PORT` actually work, remove `192.168.`, put it next to the account name, one port per session regardless of worktree, make the worktree copyable as an absolute path, "don't assume ghostty", cache time yellow at 15m and red at 5m, hide cache time above 30m, link both usage segments, "yes fix all".
- 2026-10-15 — commit `f97640fb dx(claude): give each session its own port block`: `session-port.sh` and its SessionStart hook; also a pointer in `task-resources.md`.
- 2026-10-15 — commit `6db0af13 dx(claude): compact statusline and show session ip`: statusline rewrite with IP and port block, usage links.
- 2026-10-15 — commit `555444c6 dx(claude): keep ports while the cache is valid`: a session holds its port block while its prompt cache is valid.
- 2026-10-15 — commit `147dc273 dx(claude): link statusline project to its repo`.
- 2026-10-15 — commit `79fb8727 dx(claude): show full LAN IP, drop +N server count`; 2026-10-16 `29db07a5 dx(claude): show full LAN IP after the account`; 2026-10-20 `407ecf2c ux(statusline): show full ip when the line fits`.
- 2026-10-16 — session e8cb296d: the user said the earlier subagent-statusline fix "wasn't really what I was trying to fix" and wanted details back. Commit `e111dacf dx(claude): show model and context in agent rows` came before; commit `bbf24743 dx(claude): show agent name and activity in agent rows` follows the user's order "move model/ctx% to the front, then worker name, then finally what it's doing".
- 2026-11-06 — commits `468dd076 feat(claude): start session names with the session's port` and `b016cc17 fix(claude): keep headless runs out of session naming` use the port block in session titles (see [session titles](2026-11-06-session-titles-port-branch.md)); `c2b6da9a ux(statusline): show percentages to one decimal` changed both statusline scripts.
- 2026-11-06 — status check: all three scripts exist and keep the links.

## Results
No measurement. What the sessions reported:
- The first version had a bug: a server the user started (for example `http-server`, which hides its environment and detaches) could show red as a conflict and move to another port block on resume. Fix: such a server counts as the session's when it listens inside the session's reserved block; only a process whose environment shows a different session turns the port red. The assistant reproduced the bug before the fix. Also fixed: compaction no longer moves the port block (tested: compaction kept 42970, a resume moved it to 42980).
- "Will ports ever conflict?": the user asked; the block search avoids blocks held by open sessions and blocks with a listener.
- Not verified: the statusline's behavior while viewing a subagent in the live status-line input. The reply: "Per the docs ... Unverified: I checked the docs and changelog for 2.1.296, not the live input while you view a subagent". The main statusLine command still receives the main session's model, context and transcript while a subagent is viewed; the session drafted a `/feedback` request for Anthropic to pass the viewed agent to `statusLine`.
- For the agent-row change the user asked "will it take effect for existing sesions i'm running?" and then restarted ("alright I did it").
- No later complaint about the links or ports was found in the sessions read.

## Sources
- [Claude Code statusline docs](https://code.claude.com/docs/en/statusline) — status line input has only the main session's model, context and transcript. The reply: "Per the docs ... Unverified: I checked the docs and changelog for 2.1.296, not the live input while you view a subagent".
- Ghostty copy_url_to_clipboard #4676 (mirror commit), Ghostty commit `5e8ce20e` (link removed) — OSC 8 links and click behavior in Ghostty.
- OSC 8 copy fix #7491 (mirror commit), Ghostty commit `f599f8c8` (link removed) — OSC 8 links and click behavior in Ghostty.

## Evidence
Cited in the reply. Sessions 46d4871f (2026-10-15) and e8cb296d (2026-10-16). The Ghostty links are mirror commits found by the session; whether they were fetched or seen as search snippets was not recorded in S.
