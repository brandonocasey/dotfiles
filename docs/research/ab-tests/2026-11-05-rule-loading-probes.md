# Rule-loading probes and quality-rules analysis

- Date: 2026-11-05 to 2026-11-06  Sessions: 2697176b (2026-11-05 22:21 to 2026-11-06 18:34 UTC, hive)  Raw data: `~/.cache/agents/output/quality-rules/proposals.md` and `loading-options.md` survive (checked with `test -e`). The scratch dir `quality-rules-review` in the chezmoi worktree is deleted.
- Related: [tester value analysis](2026-11-05-tester-value-analysis.md) (same day, same family of evidence analyses), [path-loaded quality rules](../changes/2026-11-06-path-loaded-quality-rules.md), [review-driven code rules](../changes/2026-11-05-review-driven-code-rules.md)

## Question
How do code-quality rules get loaded reliably in the main session and in sub-agents?

## Setup
- Claude Code 2.1.296 `claude -p` probes in scratch projects with inert test rules, InstructionsLoaded hook output and docs checks.
- An evidence analysis of 657 reviewer reports, 247 stored review threads, 3,563 user messages, 160 MRs and 476 pipelines. About 70 agents classified 2,026 findings. 13 theme drafts were each attacked by 3 skeptic lenses.
- The user started the session with: "I want you to look into code quality and bug issues that are being found and in my global setup and find out if we can improve the situation with rule tweaks". After the first probes the user asked: "sounds like we need to make code quality load whenever something is acting as a worker, including the main session?"

## Results
- A path-scoped rule in `~/.claude-two/rules/` (`paths` frontmatter) loads on the first Read of a matching file. It does so in the main session and in `omitClaudeMd` sub-agents, once per session.
- Symlinked rule dirs and files work. `{a,b}` brace globs work. All 24 proposed glob cases matched.
- Files outside the session's working folder never match (plain, absolute and `~` globs; `--add-dir` did not help). 219 of 718 distinct code files edited in 30 days (30%) were outside the working folder.
- After compaction a path rule does not reload. 467 of 4,910 main-session edits (10%) followed a compaction, in 36 sessions.
- A skill `paths:` field does not inject the body. Sub-agent `skills:` preload injects SKILL.md only.
- Baseline: code-standards loaded before the first code edit in 47 of 211 main sessions (22%).
- Later hook probes covered flow-list, BOM, `!` negation, multi-line `paths:`, parallel-edit batch behavior (PostToolBatch), a compact3 probe (it refuted a docstring claim) and Python 3.9 vs 3.15 hook parity (separate session).
- Not found: the planned re-measure of load rate and findings two weeks after applying. No later session or doc in the repo records it (searched the repo log, `agt sessions search`).

## Validity
- The assistant said "'already covered by existing rules' is wording match, not measured effect". A re-measure was planned for two weeks after applying (not found as done).
- One probe batch had a restart-script bug that sent theme outputs to the same file. It was rerun.
- Probes used inert test rules in scratch projects, one Claude Code version (2.1.296). The later note in 627bdeda records behaviour on 2.1.300.

## Decision
Path-scoped rules for code standards plus a rule-gate hook that denies the first edit of a matching file until the rules are read. This covers files outside the working folder and edits after compaction. It is option 1 of 5 in `loading-options.md` ("Path-scoped rule plus a gate hook ... recommended").

## History
- 2026-11-05 — Evidence analysis and probes run in session 2697176b (hive).
- 2026-11-05 — `395ba50f feat(review): trace what removed links guaranteed` (04:40 EST), `6e11c86d dx(code-standards): add review-driven code rules` (13:52 EST) and `7bd40559 dx(review): check added comments against the comment rules` (14:20 EST). The old record listed these under this test. They were committed before session 2697176b started (22:21 UTC is 17:21 EST), so they are related by theme (review-driven findings) and not by this session. Session not found (searched `agt sessions search` for the commit wording).
- 2026-11-06 — `f712b4a5 dx(rules): load and tighten code quality rules`. Adds path-scoped rules (code-standards, tests, shell-scripts, chezmoi-source, matchers-and-guards, builds-and-dependencies, instruction-edits) under `home/dot_claude/exact_rules/`. Why: agents often edited code without the standards in context.
- 2026-11-06 — `8e376208 dx(claude): gate edits until path rules are read`. Adds `rule-gate.py` and its tests. It denies the first edit of each matching file and clears records on compaction.
- 2026-11-06 — `6ee5949f fix(claude): stop rule-gate hangs and state loss`. Skips FIFO `.md` files, writes state atomically, drops newline paths, walks each real rule folder once.
- 2026-11-06 — `8d85aee4 fix(claude): deny every same-batch edit of a file`. An agent sends a whole tool batch before seeing a deny, so every edit of a denied file in the batch is now denied.
- 2026-11-06 — `a19316a5 refactor(claude): drop rule-gate record snapshot`. Removes the pre-edit copy of the records that became dead after 8d85aee4.
- 2026-11-06 — `627bdeda docs(claude): note rule-gate deny after interrupt`. Notes that Claude Code 2.1.300 sends no PostToolBatch for an interrupted batch, so a denied file is denied once more on its next edit.
- 2026-11-06 — `720906f9 fix(claude): run hooks on Python 3.9`. Four hooks failed to load on Apple's Python 3.9, so their guards never ran. The commit touches `rule-gate.py` (deferred annotations, `TypeGuard` imported for type checks only), `bash-guard.py`, `continue-guard.py` and `edit-guard.py`.
- 2026-11-06 — `1c9a8e46 dx(code-standards): cite sources for the rules` and `63b49de1 dx(code-standards): read sources only when asked`. Later edits to `exact_rules/code-standards.md.tmpl`; they add and then soften a pointer to the cited sources.
- Today: `rule-gate.py` is registered as a PreToolUse hook (`python3 -I ~/.claude/hooks/rule-gate.py`, timeout 5) for `Edit|Write|MultiEdit` in `home/.chezmoitemplates/claude-settings-modify.sh`, after `edit-guard.py`. Seven rule files live in `home/dot_claude/exact_rules/`.
