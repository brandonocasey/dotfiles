# Tmux bell when Claude waits for input

- Status (2026-11-06): current, and grown into a status-line state marker. `home/dot_claude/hooks/executable_tmux-bell.sh` header: "Marks this tmux pane's agent state for the status line ... input: Stop and permission prompts; also rings the bell so tmux flags the window." It also handles `working` and `clear`, and skips headless runs (`claude -p`).
- Topic: Hooks
- Related: [Session titles: port, branch and part](2026-11-06-session-titles-port-branch.md), [Statusline links and ports](2026-10-16-statusline-links-ports.md)

## Change
A hook rings the tmux bell when Claude needs input, so tmux flags the window.

## History
- 2026-10-16 — session d69dd9a4. The user asked to customize the tmux status line, then "any other tmux custom stuff to do?". The assistant offered a "Claude waiting flag (recommended)" using tmux bell alerts.
- 2026-10-16 — `416f4d78 feat(claude): ring tmux bell when waiting for input`: the Stop hook rings the bell. Tested on a separate tmux server with a real reply. The assistant warned open sessions might not ring until restarted (not tested).
- 2026-10-16 — `38ef8053 feat(claude): mark tmux pane as input on questions`: adds a settings hook so questions also mark the pane as input.
- 2026-10-16 — `88ee843c ux(tmux): show only whether each agent needs input`: the status line shows only whether each agent needs input; hooks added for Codex (`home/dot_codex/hooks.json`) and `tmux-bell.sh` reworked.
- 2026-11-05 — `54770102 fix(tmux): select a compatible hook client` (with tests) and `fe64562c refactor(tmux): share client discovery` (moves discovery into `tmux-client.sh`).
- 2026-11-05 — `7cb662a3 fix(tmux): keep agent name while panes run tools`.
- 2026-11-06 — `0034f716 feat(tmux): show agent background work in yellow`: red for needs input, yellow while waiting for a prompt with background work running, green while working. Claude reports running background tasks on Stop; for Codex the hook looks for commands still running outside the pane's terminal and starts a watcher.
- 2026-11-06 — `c1748edb fix(tmux): mark agents working when a tool starts`: a turn started by a `!` command fires no prompt hook, so the pane stayed red until the first tool finished.
- 2026-11-06 — `ec29d12e fix(tmux): ignore exited codex commands`: zombie processes kept the pane in background; the watcher test failed in CI under dash.
- 2026-11-06 — `a384501b docs(tmux): shorten codex terminals comment`.

## Results
No A/B measurement. The first version was tested in session d69dd9a4 on a separate tmux server with a real Claude reply that rang the bell. The `/goal` check (below) was meant to keep the bell from ringing mid-goal; no test of that is recorded. Later problems seen in commit messages: the pane stayed red when a `!`-command turn started (fixed 2026-11-06), a zombie Codex command kept a pane yellow (fixed 2026-11-06), and the hook picked an incompatible tmux client (fixed 2026-11-05). The user stopped the review in d69dd9a4, so its commits were not reviewed in that session.

## Sources
- [Claude Code hooks](https://code.claude.com/docs/en/hooks) — Stop "Does not run if the stoppage occurred due to a user interrupt"; Stop input fields `stop_hook_active`, `last_assistant_message`; Notification event (page truncated before it).
- [Claude Code goal](https://code.claude.com/docs/en/goal) — `/goal` keeps turns going; checked so the bell does not ring mid-goal.

## Evidence
Both pages fetched, partially truncated. The bell was tested on a separate tmux server with a real reply. Session d69dd9a4 (2026-10-16).
