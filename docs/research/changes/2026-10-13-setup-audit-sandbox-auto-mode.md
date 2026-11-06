# Setup audit against current Claude Code and Codex docs: sandbox, auto mode, Codex guard

- Status (2026-11-06): changed. Current Claude settings: `"sandbox": {"enabled": false}` and no narrow merge/approve/Jira-write allows in `home/.chezmoitemplates/claude-settings-modify.sh`; an `autoMode.allow` entry covers MR/PR and Jira actions the user asked for, including re-enabling paused auto-merge; Codex `web_search = "cached"` in `home/dot_codex/modify_private_config.toml.tmpl`. The Codex force-push guard hook from this audit is gone (removed 2026-10-19, see History).
- Topic: Settings, permissions and security
- Related: [Codex rules file](2026-10-13-codex-rules-file.md), [Prompt-cache TTL and permission denies](2026-10-14-cache-ttl-and-permission-denies.md), [Codex tester sandbox](2026-10-21-codex-tester-sandbox.md)

## Change
- Global Claude sandbox turned off, with its dead config removed.
- Narrow allow rules for merges, approvals and Jira writes removed so the auto-mode classifier sees them (`Bash(glab mr approve*)`, `Bash(glab mr merge*)`, `Bash(gh pr merge*)`, `Bash(gh pr review*--approve*)`, `Bash(jira-api POST *)`, `Bash(jira-api PUT *)`). An `autoMode` allow rule restores merges the user asked for and auto-merge re-enabled after a push.
- A Codex force-push guard hook (`guard.py`, wired in `hooks.json`).
- Codex `web_search = "cached"` (default under full access is live).
- Session logs chmod 600 (done locally; no commit).

Correction to S: S listed "blanket `Bash`/`Task` allows" removed in this audit. The git diff shows those two blanket allows were removed by `fe42308a` in the 2026-10-14 cache-TTL session, not by this audit. See [Prompt-cache TTL and permission denies](2026-10-14-cache-ttl-and-permission-denies.md).

Earlier, 2026-10-12, read-only allow rules and a sandbox with auto-allow were added (session 67edba11) and then reversed by this audit.

## History
- 2026-10-12 — session 67edba11 (borg): user: "I pretty much never want to deny claude code running commands, but i'm not sure how to stop needing to babysit everything. Would it be better to have a virtual machine ...". The assistant recommended the built-in sandbox with auto-allow, plus `/fewer-permission-prompts`; a VM or dev container was costed but not chosen.
- 2026-10-12 — commit `f8b0eb32 dx(claude): allow common read-only commands`: adds read-only allows (`tmux capture-pane`, `chezmoi status`/`diff`/`source-path`, `glab mr list`/`view`, `claude plugin validate`).
- 2026-10-12 — commit `f73670c7 dx(claude): enable sandbox with open network`: sandbox enabled with auto-allow, all domains, write access to agent dirs. (Not in S.)
- 2026-10-12 — commit `8ee8f585 dx(claude): route outward commands to auto mode`: adds `excludedCommands` (glab, gh, git push, curl, ssh, tmux, claude, codex and others) so they leave the sandbox, widens writable paths to `~/Projects`, `~/.cache` and `~/Library/Caches`, and adds an auto-mode rule to retry with `dangerouslyDisableSandbox` after sandbox failures.
- 2026-10-13 — commit `02856e46 dx(claude): turn off the local sandbox`: `settings.local.json` set `sandbox.enabled` false, which overrode the global block. (Not in S; this is the "local settings file" the audit found.)
- 2026-10-13 to 10-14 — session bd76000a: `/open-ended` "audit my setup for current codex and claude code best practices". 6 audit rounds, 37 confirmed findings; top finding: neither tool had an enforced safety boundary. The user told it which to fix.
- 2026-10-13 — commit `d67738e3 security(claude): route merges and approvals through auto mode`: sandbox off in global settings, dead sandbox config removed, narrow merge/approve/Jira allows removed, merge auto-mode rule added, retry-with-`dangerouslyDisableSandbox` rule dropped, sandbox override removed from `settings.local.json`. A duplicate of this commit exists as `91ef45c3` (same subject, same time, not reachable from main); S listed both.
- 2026-10-13 — commit `ac18047a security(codex): deny force pushes the rules cannot prompt`: adds `home/dot_codex/hooks/executable_guard.py` and `hooks.json`; also changes the pr-fix push command to the one plain form the Codex rules prompt on. 82 test cases, two reviews.
- 2026-10-13 — commit `1c69eb92 security(codex): use cached web search under full access`.
- 2026-10-15 — `1cc6cc7d dx(claude): simplify auto-mode rules` and `2f1ff037 dx(claude): restore dropped auto-mode exceptions` rewrote the auto-mode allow list; the merge rule with the re-enable-auto-merge wording survives in today's file.
- 2026-10-17 — commit `9b89877b fix(codex): require approval for mirror pushes`: guard and rules treat `git push --mirror` as a force push (the assistant had flagged `--mirror` as not covered).
- 2026-10-19 — commit `cf5cb999 dx(codex): drop force-push guard needing python`: removes `guard.py`, its hook entry and test. Message: "The hook needed Python, which not every machine has. Codex rules still prompt for git push with a force flag right after push; chained or late-flag force pushes now run unprompted." Only the rules-file prompt remains.
- 2026-11-06 — status check: sandbox off, web search cached, no Python guard. S said "Status: current" for the whole entry; the guard part is not current.

## Results
No A/B measurement. Audit and test results:
- bd76000a: 37 issues. Top 6: Claude sandbox off via a local file; merge/approve allows skipping the auto-mode classifier; Codex read-only agents not read-only; Codex guard rules missing common force-push forms such as `git push origin main --force`; session logs readable by other users on the Mac (three contained token-shaped strings; liveness not checked); Codex web search live by default.
- The Codex guard passed 82 test cases after the reviewers found 4 bugs (a comment-parsing hole and missing command wrappers among them). Two reviews found no open medium or high bugs. No reviewer saw the last two small guard fixes.
- Open at the end: "Codex still ignores read-only on its agents, and with the sandbox off nothing can enforce it". Audit items CC-2 (narrow sandbox domains) and C1 (enforce Codex read-only) were not fixed; the sandbox was turned off instead.
- The one open doc question, "I didn't confirm how auto mode treats the bare Bash rule", was later resolved in bd76000a.
- The sandbox decision of 10-12 was reversed within a day.
- Later problem: the Python guard did not survive (cf5cb999), so chained or late-flag force pushes in Codex now run without a prompt.

## Sources
Session bd76000a (fetched by audit sub-agents; per-claim quotes not preserved):
- [Claude Code settings](https://code.claude.com/docs/en/settings), [permissions](https://code.claude.com/docs/en/permissions), [permission modes](https://code.claude.com/docs/en/permission-modes), [sandboxing](https://code.claude.com/docs/en/sandboxing) — blanket `Bash` allow rules are ignored in auto mode and skip checks outside it; narrow allow rules bypass the auto-mode classifier; `autoMode.classifyAllShell` (a managed-settings table shows it "honored even when a managed source sets false").
- [Codex config reference](https://developers.openai.com/codex/config-reference), [agent approvals and security](https://developers.openai.com/codex/agent-approvals-security), [config reference (learn.chatgpt.com)](https://learn.chatgpt.com/docs/config-file/config-reference) — `web_search` defaults to live under full access; `sandbox_mode = "read-only"` in agent files is ignored (agents get the parent's access).
- [tree-sitter-bash node types](https://raw.githubusercontent.com/tree-sitter/tree-sitter-bash/master/src/node-types.json) — used to write the Codex force-push guard (later rewritten to avoid shell parsing).

Session 67edba11:
- [Claude Code sandboxing (docs.anthropic.com)](https://docs.anthropic.com/en/docs/claude-code/sandboxing) — built-in sandbox with auto-allow removes most prompts on macOS.
- [Claude Code dev container](https://docs.anthropic.com/en/docs/claude-code/devcontainer) — reference container with a network firewall.

## Evidence
bd76000a was audit style with sub-agent doc reads, an 82-case guard test and two reviews (6 audit rounds, 37 confirmed findings). The assistant stated one open point, "I didn't confirm how auto mode treats the bare Bash rule", which bd76000a later resolved. The sandbox decision was reversed within a day. Sessions bd76000a (2026-10-13/14) and 67edba11 (2026-10-12, borg; VM vs sandbox question and `/fewer-permission-prompts`). Doc pages were fetched by sub-agents and summarized; per-claim quotes were not kept.
