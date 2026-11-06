# Run verification checks without asking

- Status (2026-11-06): current. `home/.chezmoitemplates/main-rules.md` line 7: "Never ask to do checks that answer my question or verify your claims: scratch installs, local repro runs, short `claude -p` checks, reads, and test runs. If you could run it and an answer depends on it, run it before replying. Never mark a claim "unverified" and then offer to verify it." The line is unedited since `b0a320cf`; surrounding lines were edited by later commits.
- Topic: Rules and instructions
- Related: [Pin Claude Code 2.1.296](2026-10-27-pin-claude-code-2-1-296.md)

## Change
One main-rule line (under the "Ask only for outward actions, destructive steps, credentials ..." rule) tells agents to run checks that answer the user's question instead of asking first.

## History
- 2026-11-05 — session 0fa0754d (hive), user: "is the context-lean issue resolved in new verison of claude yet". The assistant answered "No, it is not fixed yet" from the open issue and changelog, marked "unverified: I have not run the test on 2.1.318", and asked approval to run a scratch-only test. The user replied "run it".
- 2026-11-05 — the assistant: "I asked approval for a scratch-only test that you had already effectively requested. That was wrong. Finding the rule source to fix it now." It added the rule to the shared rules template and applied it to Claude (both profiles), Codex, OpenCode, Gemini and Pi.
- 2026-11-05 17:19 local — `b0a320cf dx(agents): run verification checks without asking`: committed and pushed by `/dotfiles-sync` at the end of the session; the commit adds one line to `home/.chezmoitemplates/main-rules.md`.
- 2026-11-05 — `da8e06e5 dx(rules): clarify output cap, waits, and probes` edited the neighboring "Ask only for ..." line (names `agent-probe` runs) and left this line as is.
- 2026-11-06 — `f9cfb60a dx(agents): tighten verify, ship, and fix steps` touched the same file for other rules.

## Results
No measurement. The same session ran the test it had asked about: on 2.1.318 the bug was still there ("context-lean: prompt.attachment bypassed by cc-plugin-sec-default (tier user)"), and the installed 2.1.296 showed no bypass. No later session was checked for whether agents still ask before checks; not found (no search was run beyond the commit history).

## Sources
- [Claude Code issue #102653](https://github.com/anthropics/claude-code/issues/102653) — mod hook `prompt.attachment` bypassed by `cc-plugin-sec-default` (the context-lean bug); still open.
- [Claude Code CHANGELOG](https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md) — no entry fixing it.

## Evidence
Weak. The sources were cited for the context-lean question, not for this rule, and no source backs the rule. The rule came from the user's reaction in the session ("run it") and the assistant's own correction. It was committed by `/dotfiles-sync` at the end of session 0fa0754d (2026-11-05, hive), whose task was checking whether the context-lean bug is fixed. The assistant also tested 2.1.318: "Confirmed: the bug is still there".
