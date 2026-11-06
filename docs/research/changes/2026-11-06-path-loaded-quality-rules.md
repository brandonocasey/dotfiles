# Code-quality and verification rules loaded by path, with an edit gate

- Status (2026-11-06): current. `home/dot_claude/exact_rules/code-standards.md.tmpl` is a path-scoped rule (`paths:` globs for code, config and script files). `home/dot_claude/hooks/executable_rule-gate.py` denies the first edit of a matching file until the rules are read. Latest rule-file commit `63b49de1 dx(code-standards): read sources only when asked`; latest gate commit `720906f9`.
- Topic: Rules and instructions
- Related: [Rule-loading probes](../ab-tests/2026-11-05-rule-loading-probes.md), [Review-driven code and comment rules](2026-11-05-review-driven-code-rules.md), [Bash guard rewrites with updatedInput](2026-10-28-bash-guard-updated-input.md)

## Change
The always-loaded code-standards rule moved to a path-scoped rule `~/.claude/rules/code-standards.md` (`paths` globs for code and config). An edit hook (`rule-gate.py`) denies edits until the matching path rules were read. Follow-up fixes: same-batch edits, hang and state loss, interrupt note. Verify, ship and fix steps were tightened. Hooks were made Python 3.9 safe.

## History
- 2026-11-05 to 06 — session 2697176b (hive), user: "I want you to look into code quality and bug issues that are being found and in my global setup and find out if we can improve the situation with rule tweaks". Analysis and loading probes: see the probes doc. The chosen option was option 1 of 5 in `loading-options.md`: a path-scoped rule plus a gate hook.
- 2026-11-06 — `f712b4a5 dx(rules): load and tighten code quality rules`: standards used to load only when an agent chose to read the skill; now they load as a path-scoped rule on the first touch of a matching file, in the main session and sub-agents. Narrow rules added for tests, shell scripts, chezmoi sources, matchers and guards, builds and dependencies, agent instruction edits. New checks come from repeated review findings (check each fix as new code, find sibling copies, order side effects for safe reruns, key lookups on full identity).
- 2026-11-06 — `f9cfb60a dx(agents): tighten verify, ship, and fix steps`: verify where the user meets the change; run required checks on committed HEAD before pushing; use the required ticket key; load the design skill when a request adds a flag, setting or field; build requests as worded.
- 2026-11-06 — `8e376208 dx(claude): gate edits until path rules are read`: Claude Code skips path rules for files outside the working folder, loads a new file's rules only with the first write, and does not reload after compaction. The gate denies the first edit of each matching file and names the rules to read; the retry after the batch ends counts as read.
- 2026-11-06 — `6ee5949f fix(claude): stop rule-gate hangs and state loss`: a FIFO `.md` file in the rules dir hung the hook (5 s timeout per edit); a failed state write emptied the state file; newline paths split records; sibling rule folders resolving to one folder were walked twice.
- 2026-11-06 — `8d85aee4 fix(claude): deny every same-batch edit of a file`: an agent sends every edit in a batch before seeing a deny, so a second same-batch edit went through before the rules were read.
- 2026-11-06 — `a19316a5 refactor(claude): drop rule-gate record snapshot` (no longer needed after the previous fix).
- 2026-11-06 — `627bdeda docs(claude): note rule-gate deny after interrupt`: Claude Code 2.1.300 sends no PostToolBatch for an interrupted batch, so a file denied in it is denied once more on the next edit.
- 2026-11-06 — `720906f9 fix(claude): run hooks on Python 3.9` and `58bcc745 ci: run hook tests on Python 3.9`: four hooks failed to load on Apple's Python 3.9, so their guards never ran; CI now tests 3.9.
- 2026-11-06 — `1c9a8e46 dx(code-standards): cite sources for the rules` and `63b49de1 dx(code-standards): read sources only when asked`: research behind readability rules kept in the skill references; agents read it only when asked why a rule exists or before changing the rules.
- 2026-11-06 — held decision at the end of session 2697176b: the user kept the interrupted-batch behavior as built ("recommended default"); no code change.

## Results
Measured before the change (probes doc): the old setup loaded code-standards before the first code edit in 47 of 211 main sessions (22%). 219 of 718 distinct code files edited in 30 days (30%) were outside the working folder, so a path rule never matched them. 467 of 4,910 main-session edits (10%) followed a compaction, when a path rule does not reload. These numbers are why the gate was added. The assistant said "'already covered by existing rules' is wording match, not measured effect". A re-measure of load rate and findings was planned for two weeks after applying; not found as done.

Problems seen after applying (all same day, from the commits above): hangs on special files, state loss on a failed write, same-batch edits slipping past, the interrupted-batch re-deny (kept), and the Python 3.9 load failure. At the close of session 2697176b, CI on main failed in the existing test job (`test_claude_cleanup_skips_compaction`, `test_codex_stop_marks_background_until_terminal_ends`), attributed to other sessions' commits and left alone.

## Sources
- [Claude Code memory docs](https://code.claude.com/docs/en/memory.md) — `paths` frontmatter scopes a rule to matching files; user-level rules; a symlink target outside the working dir is an external import (grep of the .md).
- [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) — `skills:` frontmatter injects the full skill content (first 32 names), not linked reference files. "Hooks from settings files ... also apply inside subagents ... a PreToolUse hook in settings.json also runs before every tool a subagent uses".
- [Claude Code skills](https://code.claude.com/docs/en/skills) — no documented way to force-load a skill in the main session; `paths` loads a skill only "when working with files matching".
- [Claude Code hooks](https://code.claude.com/docs/en/hooks) — PreToolUse `additionalContext` is delivered "in a system reminder"; `agent_id`/`agent_type` present in sub-agent hook input; PostToolBatch fires once per batch with `tool_calls`, no `agent_id` field listed (fetched 2026-11-06 for the rule-gate fix).
- [Python tutorial, Compiled Python files](https://docs.python.org/3/tutorial/modules.html) — "it always recompiles and does not store the result for the module that's loaded directly from the command line" (hook scripts run directly are recompiled each run).

## Evidence
Docs fetched and quoted by sub-agents. The primary evidence is local: a defect taxonomy built from reviewer reports, MR threads and CI failures across about 2,000 classified rows, plus loading probes on Claude Code 2.1.296 (see the probes doc). Session 2697176b (2026-11-05 to 06, hive; user: "look into code quality and bug issues ... find out if we can improve the situation with rule tweaks").
