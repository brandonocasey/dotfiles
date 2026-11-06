# Copy output via `/copy`

- Status (2026-11-06): current, and extended. `home/dot_config/exact_agents/exact_skills/exact_host-preflight/exact_references/copyable-output.md`: "I copy text with `/copy`. Claude Code and Codex both have it." "Never write copy files. Put all copyable text in chat, however long." "End with one line: “Run `/copy`.”" It now also says to prefix commands I must run with `! ` and to hand over at most one command per reply, merged into one script. `main-rules.md` points to it ("Before copyable output: `host-preflight/references/copyable-output.md`").
- Topic: Rules and instructions
- Related: [Main-session rules in an output style](2026-10-12-output-style-rules.md)

## Change
Copyable-output rule: put each copyable item in its own code block, keep it in the final reply, end Claude Code replies with "Run `/copy`". Copy files are no longer written. For Codex the rule keeps `/copy` but notes "unverified: it has no block picker", and asks for status and URLs in an earlier message.

The earlier note said "Codex keeps copy-file steps" and "the rule is Claude-only". Commit `3daf877f` shows otherwise: it removed the copy-file steps for both agents and kept the Codex `/copy` line with the no-picker caveat. The earlier note was wrong on that point.

## History
- 2026-10-13 — session 20d262f0, user: "any way to copy text easier?" then "can we add to my agents.md that using /copy should be made super easy". A reviewer found 5 wording problems (for example a contradiction between "use a copy file only when the text cannot fit" and "show every proposal's exact final wording in chat"); all fixed. The assistant reported rule size: copy rule 752 to 1,277 characters (about 130 tokens added, loaded only before copyable output), main agents file 4,219 to 4,175, review merge step 2,888 to 2,813, review output 3,020 to 2,984; net about 90 tokens added, offset by no longer writing and deleting a copy file.
- 2026-10-13 09:19 local — `3daf877f dx(agents): copy via /copy instead of copy files`: committed later than the session by another sync. Replaces the copy-file steps in `copyable-output.md`, `approve-merge.md`, `output.md` and `AGENTS.md`.
- 2026-10-13 — `d813f42b dx(agents): trim rules and cap agent result size` touched the reference.
- 2026-10-15 — `8513bac3 dx(agents): hand over multiple commands as one script`.
- 2026-10-16 — `0e980603 dx(agents): keep one handed-off script across replies`.
- 2026-10-17 — `62c2d3fd docs(copyable-output): write a blocked script with the file-write tool, never list commands`.
- 2026-10-24 — `3301fe10 dx(agents): cut duplicate rules and fix conflicts`.
- 2026-11-05 — `b953b057 dx(agents): prefix commands to run with !`: every command the user must run starts with `! `.
- Earlier history of the same file, before this rule: `cc14dc48 dx(agents): streamline shared workflows` (2026-10-04), `0248759e dx(agents): move main-session rules to output style` (2026-10-12), `6de4e9b4 dx(skills): point repeated rules to their owners` (2026-10-12).

## Results
Measured in the session: net about +90 tokens of rule text, loaded only when the agent gives copyable output; each copy task saves a file write and a delete step. No measurement of how often agents follow the rule. Problems seen later: the rule grew rules about command handoff (one command per reply, one script across replies, a `! ` prefix) in the following three weeks, which shows that the original `/copy` wording did not cover how to hand over commands. The Codex half stays unverified in the rule text.

## Sources
- [Claude Code interactive mode](https://code.claude.com/docs/en/interactive-mode) — keybindings; `/copy` copies the last reply with a picker for code blocks.
- [Codex CLI slash commands](https://developers.openai.com/codex/cli/slash-commands) — Codex `/copy` has no code-block picker, so the picker advice is Claude-only.
- [Codex TUI shortcuts (third party)](https://codex.danielvaughan.com/2026/04/08/codex-cli-tui-shortcuts-slash-commands/) and [potato-ai.xyz](https://potato-ai.xyz/codex-cli-copy-last-response-first-use/) — Codex copy behavior.

## Evidence
Cited in the reply; "None of the sources I found mention a picker" for Codex. A reviewer found 5 wording problems, all fixed. Session 20d262f0 (2026-10-13).
