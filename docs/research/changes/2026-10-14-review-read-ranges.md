# Read ranges instead of whole files; reviewer reads partials; Haiku setup helper

- Status (2026-11-06): mixed. The read-range rule is current in `home/dot_config/exact_agents/private_AGENTS.md` line 24: "Read ranges with `sed -n` or `rg`; the file-read tool's line-numbered output costs more tokens." (extended on 2026-11-05 with the 6,000-character Bash output note). The reviewer's LSP tool was removed on 2026-10-16. The Haiku/`cheap` setup helper was replaced by main-session setup on 2026-10-20.
- Topic: Review
- Related: [LSP-first lookup rule](2026-10-15-lsp-first-lookup.md), [light vs normal reviewer](2026-10-14-light-vs-normal-reviewer.md), [LSP tool token A/B](../ab-tests/2026-10-14-lsp-tool-tokens.md), [agent starting context](../ab-tests/2026-10-13-agent-starting-context.md)

## Change
A global read rule: find code with LSP when available, `ast-grep` for structure, or `rg -n`, read only those ranges with `sed -n` or `rg`, once, all known ranges in one call. Still read the whole changed function, callers and contracts. The user's reasoning: the file-read tool's line-numbered output costs more tokens than `sed -n`.

For review, the main session reads nothing beyond the entry rules and only starts the reviewer. The reviewer role got the LSP tool. Review setup (checkout, deps, background checks, prompt writing) moved to a Haiku helper with its own `setup.md`, and the main session passes only the target. The reviewer-steps rule today: "Read partials: only the ranges you located."

## History
- 2026-10-14 — Session bc200b0a (a long session that also ran the light-reviewer A/B and a context audit through a logging proxy). The audit found: agent first request 2.3k-3.3k tokens; the review-steps file about 2,340 tokens; sub-agent role prompts 210-390 tokens; about 370 tokens per turn trimmable, about 5% of a 7,400-token fresh session.
- 2026-10-14 — The user asked "does the review skill ask for your own pass? if not why are you doing it?" and "update skill to mention this specifically" (about 19:57Z). Commit `c9da99d3 dx(review): skip reviewer checklist in main session` (16:02 local) followed: the main session reads reviewer-steps steps 0 and 2 only and the severity scale is pasted inline.
- 2026-10-14 — commit `345ba6eb dx(agents): compact rules and skill descriptions` (16:14). It came out of the same session's trim work ("alright so help me trim the fat", "approve all"); the commit has no body, so the link is by time and topic.
- 2026-10-14 — The user (about 20:04Z): "feels like the rule is wrong if it costs us. file read always reads the full file?" Then: "main session shouldn't read anything, it should just kick of the reviewer. reviewer should read partials using lsp/ast-grep/sed/rg as best as possible to save tokens, but still read all the needed context." Then: "in general this should always be the rule. the file read tool might actually be worse than this recommendation."
- 2026-10-14 — Three commits at 17:16 local: `61818955 dx(agents): read ranges via sed and rg to save tokens` (the global rule, two lines in `private_AGENTS.md`), `78752a06 dx(agents): give reviewer the LSP tool` (added `LSP` to the reviewer's tools), `027f85c9 dx(review): hand review setup to a haiku helper` (new `setup.md`, and the reviewer prompt template moved into it; the "Never write your own summary of the change..." brief wording became the shorter setup.md wording). The setup helper followed the user's "can we have hakiu 5.5 setup the reviewer worktree/install-deps etc?" at about 20:29Z.
- 2026-10-15 — `ed25d9dd dx(agents): use LSP first for symbol lookups` strengthened the lookup order. See [LSP-first lookup](2026-10-15-lsp-first-lookup.md).
- 2026-10-16 — `19187158 dx(agents): replace lsp with code graph tooling` (16:32) removed `LSP` from the reviewer's tools and the LSP install script.
- 2026-10-20 — `a9f9a3a5 dx(agents): run review setup in main session` (12:30). Replaced the `cheap` sub-agent setup helper with main-session setup per `setup.md`. SKILL.md now says "Run setup yourself per setup.md, with `agt`, `git`, and `gh`/`glab` commands; no sub-agent." No deciding session was found (searched transcripts overlapping 12:30 local on 2026-10-20 by time and by first prompt).
- 2026-11-05 — `da8e06e5 dx(rules): clarify output cap, waits, and probes` extended the read rule: in Claude Code, Bash output over 6,000 characters (`BASH_MAX_OUTPUT_LENGTH`) is saved to a file and needs a second read, so use the file-read tool for skill files, longer reads, and files you will edit.
- Earlier forms of the rule, for context: `17c89067` (2026-10-07) batched rule-file reads; `efa132d0 dx(agents): keep sub-agent reads small` (10-12); `329b6dac dx(agents): merge duplicate read and output rules` (10-13).
- 2026-11-06 — Status checked in the repo as in the Status line.

## Results
No measurement of the read-range rule. It was a user directive, not benchmarked. The savings numbers in the session were unverified: partial reads of about 1.1-1.5k tokens per review, and whether the Agent tool can override effort. The audit counts above are measured token counts.

Later changes show what did not hold. The reviewer's LSP tool was dropped two days later when LSP was replaced by code-graph tooling. The Haiku setup helper was replaced by main-session setup six days later (reason not found in a transcript; the commit has no body). The rule itself needed a caveat on 2026-11-05 because Bash output over 6,000 characters is saved to a file and costs a second read.

## Sources
No web sources. Evidence is internal: a context audit through a logging proxy (agent first request 2.3k-3.3k tokens; review-steps file about 2,340 tokens; sub-agent role prompts 210-390 tokens; about 370 tokens per turn could be trimmed, about 5% of a 7,400-token fresh session).

## Evidence
Measured token counts from the audit. The read-range rule was a user directive, not benchmarked. Unverified in the session: savings of partial reads of about 1.1-1.5k tokens per review, and whether the Agent tool can override effort. Session bc200b0a (2026-10-14).
