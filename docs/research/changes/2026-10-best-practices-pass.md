# Best-practices pass: two failed fixes then /clear, compaction note, code-intelligence plugins

- Status (2026-11-06): current. `home/.chezmoitemplates/main-rules.md` says "After two “still broken” turns, stop. Name the doubtful assumption, ask one diagnostic question, and give a rewritten prompt, with what we learned, for a fresh session." `home/dot_config/exact_agents/private_AGENTS.md` line 23: "When compacting, keep the full list of changed files, the test and check commands, and scratch file paths." Both lines are unedited since `ff6e4303`. LSP plugin enablement lives in `home/.chezmoitemplates/claude-settings-modify.sh` and a `run_onchange_after_51-claude-code-intelligence` script.
- Topic: Rules and instructions
- Related: [LSP-first lookup rule and plugin enablement](2026-10-15-lsp-first-lookup.md), [LSP tool token A/B](../ab-tests/2026-10-14-lsp-tool-tokens.md), [Setup audit, sandbox and auto mode](2026-10-13-setup-audit-sandbox-auto-mode.md)

## Change
`ff6e4303` replaced "after three still-broken turns ask a question" with a two-tries-then-suggest-`/clear`-plus-rewritten-prompt rule, added a compaction rule (keep changed files, check commands, scratch paths), and dropped two duplicate lines. `4a1b8bfc` enabled TypeScript/Python/Rust LSP plugins (the settings script had been resetting them) and installs `typescript-language-server`.

## History
- 2026-10-18 — session bd2695fc, user: "do we follow https://code.claude.com/docs/en/best-practices?". The assistant compared live settings, hooks, skills, agents and rules to the guide and found 6 gaps: sandbox off; always-loaded rules about 4.5k tokens and dense (estimated from file size); the three-turn rule; no compaction rule; no code-intelligence plugin in user settings; side-effect skills invokable by the model. It offered options 1 to 6. The user answered "1/2 send opus xhigh to do 3. code intelligence?".
- 2026-10-18 12:18 local — `4a1b8bfc build(claude): enable code intelligence plugins`: "The settings script reset enabledPlugins on every apply, so the installed LSP plugins stayed off." mise and a run script install the servers; TypeScript 6+ workspaces use the TypeScript 7 server for less memory.
- 2026-10-18 12:18 local — `ff6e4303 dx(agents): apply claude code best practices`: the two-tries `/clear` rule, the compaction rule, and two duplicate lines dropped.
- 2026-10-18 13:48 local — `9da0e3d0 dx(agents): tighten waiting and handoff rules`: same session, not attributed to the guide. Waits on exit notifications instead of Monitor loops.
- 2026-10-18 — follow-on TypeScript 7 diagnostics commits: `1856cb43 fix(claude): push ts 7 diagnostics to claude code`, `59598496 fix(claude): push cross-file ts 7 diagnostics`, `54dd0186 fix(claude): drop stale ts 7 diagnostics`, `e89a26e4 fix(claude): check parent tsconfigs for ts 7`. These came from reading the typescript-go LSP server source, not from a rule.
- Gaps left open in the reply: sandbox off (see the setup-audit doc); skills manual-only (the assistant judged risk low because Git consent rules cover it); the Opus audit of the rule set ("llm-setup-audit") was started in the session.

## Results
No measurement. The `/clear` and compaction rules have not been re-checked against sessions. The assistant's own figure for rule size, about 4.5k tokens, was an estimate from file size, "I did not check this against past sessions". One earlier problem that led to commit `4a1b8bfc`: LSP plugins installed earlier were off because the settings script reset `enabledPlugins` on each apply. A review of the TypeScript 7 commits was set up in the session; its findings were not read.

## Sources
- [Claude Code best practices](https://code.claude.com/docs/en/best-practices) — after two failed corrections `/clear` and write a better prompt; add a compaction instruction; keep CLAUDE.md short; use code-intelligence plugins; manual-only for side-effect skills.
- [Claude Code code-intelligence plugins](https://code.claude.com/docs/en/plugins/code-intelligence) — LSP plugins give type errors after each edit and symbol lookup.
- [Claude Code skills](https://code.claude.com/docs/en/skills) and [sub-agents](https://code.claude.com/docs/en/sub-agents) — compared, no change. The assistant: "Unverified: the docs don't say whether a forked skill's text also stays in the main session".
- [typescript-go lsp server source](https://raw.githubusercontent.com/microsoft/typescript-go/main/internal/lsp/server.go) — used for the follow-on TypeScript 7 diagnostics commits (1856cb43, 5959849, 54dd018, e89a26e), not for a rule.

## Evidence
Doc fetched (best-practices read by a sub-agent) and cited in the reply ("The guide says after two, /clear and rewrite the prompt"). Gaps 1-5 in the reply were compared against live settings. Session bd2695fc (2026-10-18; user: "do we follow https://code.claude.com/docs/en/best-practices?"). The abbreviated shas 5959849, 54dd018 and e89a26e in the original note are `59598496`, `54dd0186` and `e89a26e4`.
