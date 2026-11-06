# Bash guard rewrites bad commands with PreToolUse `updatedInput` instead of blocking

- Status (2026-11-06): current. `home/dot_claude/hooks/executable_bash-guard.py` fixes the call and returns `updatedInput` with no permission decision when every problem has a safe fix. Its docstring: "It returns the fixed input as updatedInput with no permission decision, so permission rules and auto mode still check the fixed command". Latest commits `720906f9` (2026-11-06) and `f16ba2e8` (2026-11-02).
- Topic: Hooks
- Related: [Rule-loading probes](../ab-tests/2026-11-05-rule-loading-probes.md), [Path-loaded code-quality rules](2026-11-06-path-loaded-quality-rules.md)

## Change
`bash-guard.py` fixes quote-`=` words, trailing `echo $?`, `pgrep -f` self-match, a missing `ToolSearch` in headless `--tools`, and foreground waits, and tells the model what it ran. It still blocks kills by name, `claude -p` in a handoff session, and anything unsafe to rewrite. The rewrite is returned without a `permissionDecision`.

Before 2026-10-28 the guard only blocked. The blocking guard started on 2026-10-16.

## History
- 2026-10-16 — `a4e62c6a dx(claude): block foreground polling and self-matching pkill -f`: first guard. It blocks until/while/for sleep loops and `pkill -f` with a plain pattern, which kills its own shell (exit 144).
- 2026-10-16 — six parser fixes in one day: `8c51e242 fix(claude): skip quoted text and read sleep units in bash-guard`, `e7ca3d33 fix(claude): parse shell quoting and comments in bash-guard`, `8ed28b88 fix(claude): parse pkill options and skip backgrounded lines in bash-guard`, `2b366557 fix(claude): split backgrounded lines at ; and anchor loop keywords in bash-guard`, `f1a8e990 fix(claude): read pkill signal flags and backgrounded groups in bash-guard`, `d3c74b15 fix(claude): track background & across lines and shell keywords in bash-guard`.
- 2026-10-18 — `d3b8861f dx(claude): block three wasteful bash patterns`: unquoted `=` words (zsh fails), `$?` echo, headless `claude --tools` without ToolSearch (every connector tool sent in full).
- 2026-10-18 — `c6df970a fix(claude): allow saving exit codes to files`, `bb8cb125 fix(claude): block only trailing exit-code echoes`, `44b2c41c fix(bash-guard): fewer false blocks, catch wrapped claude`: false-block fixes.
- 2026-10-19 — `e2bab145 dx(claude): block sleep-then-check log polling` and `2b34262e fix(claude): match only real reads after a sleep`.
- 2026-10-20 — `3971e517 dx(hooks): block sub-agent waits past cache expiry`: sub-agent foreground calls over 4.5 minutes (the sub-agent cache lasts 5 minutes).
- 2026-10-25 — `1aa4319c dx(agents): block nested handoff sessions`, then flag-form fixes `28f27c6a fix(agents): catch grouped and = print flags`, `b8a3a6ab fix(agents): catch more headless flag forms`, `0ee9e7bf fix(agents): catch -pc in the ToolSearch check`.
- 2026-10-25 — `c5585274 fix(agents): block kills that reach other sessions`: six A/B runs died with exit 143 when other test sessions ran `pkill -f '[s]tock'` and `pkill -f '[u]nittest discover'`, whose patterns matched the runs' command lines. Followed by `73d5330a fix(agents): show the bracketed pkill form`, `e5e30d6a fix(agents): allow no pattern kills, only scoped ones`, `a27fe4b5 fix(agents): keep the self-match hint where the kill check is blind`, `6d7e7d4e fix(agents): read pkill options after the pattern on Linux`, `51ae200e fix(agents): read values attached to pkill short options`.
- 2026-10-27 — `fc9fe7e9 dx(claude): allow agt wait help past bash-guard`.
- 2026-10-28 — session 157ecfb6, user: "can we fix bash issies rather than gaurd?" after asking what else `agt` could do to cut LLM cost.
- 2026-10-28 — `9926b953 dx(bash-guard): fix bad commands, not block them`: the switch from block to rewrite with `updatedInput`.
- 2026-10-28 — `e30593bf fix(bash-guard): keep heredocs, groups, broad pkill safe`, `08c3e356 fix(bash-guard): parse-check fixes, scope wait &`, `838aef18 fix(bash-guard): strip & after a piped agt wait`, `ce908996 fix(bash-guard): refuse unsafe cuts, quoting, waits`: fixes from two full reviews and a fix check (10 bugs in all).
- 2026-11-01 — `f1e145c3 fix(agents): fix more pgrep self-matches, clearer kill blocks` and `9e6c9b35 fix(agents): correct bash-guard kill hints`.
- 2026-11-02 — `d6068e6d fix(agents): fix bash-guard false blocks and hints` and `f16ba2e8 fix(agents): skip killall -n and abbreviated values`.
- 2026-11-06 — `720906f9 fix(claude): run hooks on Python 3.9`: on a Mac without Homebrew, `python3` is Apple's 3.9 and four hooks failed to load there, so their guards never ran. Annotations deferred, `TypeGuard` imported for type checks only. `58bcc745 ci: run hook tests on Python 3.9` followed (see [the path-loaded rules doc](2026-11-06-path-loaded-quality-rules.md)).

## Results
No A/B measurement. Known from session 157ecfb6: 92 unit tests plus a headless end-to-end run. Two full reviews and a fix check found 10 problems, all fixed with tests; the worst was the `echo $?` fix deleting a heredoc script. The first, buggy commit (`9926b953`) was pushed by another session before the fixes, so other machines that pulled and applied it ran the heredoc bug until they applied the latest commit. The undocumented no-decision case was settled by a headless probe on 2026-10-28: "a rewrite with no decision applies, and permission checks still run against the new command". Later problems: false blocks and wrong kill hints needed fixes on 2026-11-01 and 2026-11-02, and the Python 3.9 load failure on 2026-11-06 meant four hooks did not run on a Mac with the system Python until then.

## Sources
- [Claude Code hooks reference, PreToolUse decision control](https://code.claude.com/docs/en/hooks) — `updatedInput` replaces the whole input; "Claude Code evaluates permission rules ... against the input your hook returns"; "Combine with allow to auto-approve, or ask to show the modified input"; "defer: ignored". The docs say nothing about `updatedInput` without a `permissionDecision`.
- [claudeissues.com #79321, PreToolUse updatedInput ignored for Bash](https://claudeissues.com/issue/79321-bug-pretooluse-hook-updatedinput-is-silently-ignored-for-the-bash-tool) — the reporter saw rewrites dropped on v2.1.207 (Windows Git Bash) even with allow; closed "not planned" Sep 5 2026. It raised the risk that the rewrite may not apply.
- [claudeissues.com #32060](https://claudeissues.com/issue/32060-feature-hooks-permissionrequest-and-pretooluse-support-updatedinput-without-requ) — request to allow `updatedInput` without `permissionDecision`; closed "not planned"; the page does not say what shipped.

## Evidence
Docs and issues fetched (4 hook-doc fetches, the first two truncated before the section) and cited in the reply ("the docs only describe a rewrite paired with allow or ask"). The headless probe on 2026-10-28 settled the no-decision case. Session 157ecfb6 (2026-10-28).
