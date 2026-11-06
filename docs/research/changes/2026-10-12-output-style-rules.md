# Main-session rules moved into a custom output style

- Status (2026-11-06): current. `home/dot_claude/output-styles/main.md.tmpl` exists (`name: main`, `keep-coding-instructions: true`, body is the `main-rules.md` template) and `home/.chezmoitemplates/claude-settings-modify.sh` line 525 sets `"outputStyle": "main"`. The rules in `home/.chezmoitemplates/main-rules.md` have since been edited by 40+ commits.
- Topic: Rules and instructions
- Related: [Copy output via /copy](2026-10-13-copy-output.md), [Concise style A/B](../ab-tests/2026-10-14-concise-style.md), [Agent starting context](../ab-tests/2026-10-13-agent-starting-context.md)

## Change
Main-session-only rules moved out of the shared `AGENTS.md` into `~/.claude/output-styles/main.md` (`keep-coding-instructions: true`), and role bodies are shared across Claude and Codex. Gemini, opencode and pi get a full copy of the shared plus main rules in their own instruction files.

## History
- 2026-10-12 — session d1531dd8 (borg), `/llm-setup-audit`. User: "would it be better to let agents read the global claude.md?", then "can we add a file that only the main session reads?", then "do all of the proposals and the output style".
- 2026-10-12 14:43 local — `0248759e dx(agents): move main-session rules to output style`: adds the output style, shrinks `private_AGENTS.md` (26 lines changed), adds main-rules copies for opencode, gemini and pi, and registers the style in the managed `settings.json`.
- 2026-10-12 14:43 local — `700218a6 dx(agents): share role bodies across claude and codex`: role bodies become shared templates (`explorer`, `reviewer`, `tester`, `worker`, `deep-review`, `manual-tester`), replacing per-harness copies (35 files changed).
- 2026-10-12 — `68dbce7f dx(agents): limit claude-two rule to claude`: "The claude-two command rule applies only in Claude Code. Codex, Gemini, opencode, and pi no longer load it."
- 2026-10-12 to 11-06 — `main-rules.md` then took 45 commits in all (first `0248759e`, latest `f9cfb60a dx(agents): tighten verify, ship, and fix steps` on 2026-11-06); each edits a single rule and is covered by that rule's doc where one exists, for example `4f496d8d dx(agents): adopt concise replies and quiet waits` and `43e2978c dx(agents): add concise rules from style a/b test` (see the concise-style test), and `ff6e4303 dx(agents): apply claude code best practices`.

## Results
Measured in the session: the shared file dropped from about 2.65k to 1.4k tokens, each Codex sub-agent saves about 1.2k, Claude's `worker` and `manual-tester` now read the shared file (about +0.7k each), and a main session loads about 2.7k tokens in total, roughly the same as before. A new Claude session reported its output style as "main", and Codex also loaded the main rules. Codex sub-agents were not tested ("the docs say their role instructions replace the main ones"). An independent review found one real gap: Gemini, opencode and pi read `AGENTS.md` through links and would lose the main rules; each got a full copy, but writing those files was blocked by the auto-mode safety check and needed one command from the user. Limits noted by the assistant: switching output style mid-session drops the main rules for that session, and style files are read at startup. Also applied without being named: option 1 (worker and manual-tester read the shared file; revert by re-adding `omitClaudeMd: true`). No later problem found beyond the rule edits above.

## Sources
- [Claude Code output styles](https://code.claude.com/docs/en/output-styles) — a custom output style sets role and tone for a whole session. The assistant concluded: "Output styles reach the main session and forks, but not other sub-agents".
- [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) — sub-agents skip CLAUDE.md (`omitClaudeMd`).
- [Codex config reference](https://learn.chatgpt.com/docs/config-file/config-reference) (also under developers.openai.com/codex/...) — `developer_instructions`. "Every role file must set its own, which replaces the main one (per the docs; I haven't tested it)".

## Evidence
Cited in the reply with an explicit "haven't tested" for the Codex half. The assistant's reply also cited a Codex custom-agents page (https://learn.chatgpt.com/docs/agent-configuration/subagents#custom-agents), which the earlier note omitted. Session d1531dd8 (2026-10-12, borg; `/llm-setup-audit`, then "can we add a file that only the main session reads?").
