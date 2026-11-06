# Codex tester sandbox and log access

- Status (2026-11-06): replaced twice. `home/dot_codex/exact_agents/tester.toml.tmpl` now sets `sandbox_mode = "danger-full-access"` on every OS (since `dbb58ebc`, 2026-10-27); `explorer` and `consult` stay `read-only` (full access on Linux). `test/unit/test_agent_configuration.py` expects `{"tester": "danger-full-access", "explorer": "read-only", "consult": "read-only"}`.
- Topic: Incidental doc use (the change was not driven by the source)
- Related: [Codex rules file](2026-10-13-codex-rules-file.md), [Setup audit: sandbox and auto mode](2026-10-13-setup-audit-sandbox-auto-mode.md), [Rule trims from a local audit](2026-10-13-rule-trims-local-audit.md), [Tester Haiku vs Sonnet](../ab-tests/2026-11-03-tester-haiku-vs-sonnet.md)

## Change
The Codex tester role needs to write logs and caches and to run checks. Before 2026-10-21 its template gave `read-only` on macOS and full access on Linux (Linux hosts lack bwrap, which Codex needs to enforce a sandbox). The sequence:
1. `workspace-write` on macOS (reverted the same day, because "Codex ignores sandbox_mode in custom agent files; sub-agents inherit the parent sandbox").
2. `workspace-write` on macOS again, 2026-10-27, after a probe showed `read-only` blocks writes.
3. `danger-full-access` everywhere, one hour later, because `workspace-write` blocked network and writes to `~/.cache` and `/dev/stdout`.

Correction to S: S said the status was "replaced; c32dc76b (10-27) let the tester write logs and caches instead" and that "the sha dbb88769 named in the notes does not exist and was removed". The commit the notes meant is `dbb58ebc dx(agents): give the codex tester full access` (a typo in the sha), which exists, is in main, and is the current state. `c32dc76b` itself was superseded by it.

## History
- 2026-10-21 — session 7ed59b69: while moving testing into a tester before review (`f0943031 dx(review): test with a tester before review`), the assistant offered "1. Test a Codex tester on macOS first, then decide (recommended)" or "2. Give the Codex tester write access to the workspace on macOS". The change that was made gave `workspace-write` on macOS.
- 2026-10-21 — commit `d32fe99a dx(codex): let the tester write logs on macOS`: `sandbox_mode = workspace-write` on macOS.
- 2026-10-21 — commit `c9e0bbcc Revert "dx(codex): let the tester write logs on macOS"`: "Codex ignores sandbox_mode in custom agent files; sub-agents inherit the parent sandbox, which config.toml sets to danger-full-access, so the tester could already write." The review (tester first, then reviewer) showed the setting did nothing; local Codex logs showed explorer and consult sub-agents ran with full access although their files say `read-only`.
- 2026-10-27 — session e0777840: the assistant confirmed "read-only blocks writes to both the working directory and `$TMPDIR`; workspace-write allows both" with sandbox runs, then fixed the tester role.
- 2026-10-27 — commit `c32dc76b dx(codex): let the tester write logs and caches`: `workspace-write` on macOS again, a unit test for each role's sandbox, and removal of a write-docs workaround (using `worker` on Codex).
- 2026-10-27 — the review of that change raised two sandbox questions. "Both questions are the same issue. On macOS, the Codex tester's new sandbox still blocks the network, writes to `~/.cache`, and writes to `/dev/stdout`. So this repo's own tests fail there." Options offered: full access like Linux and the Claude tester (recommended), keep the sandbox and allow `~/.cache` and network, or keep as is. Option 1 was applied.
- 2026-10-27 — commit `dbb58ebc dx(agents): give the codex tester full access`: "workspace-write blocked network and writes to ~/.cache and /dev/stdout, so checks failed in the tester." Sets `danger-full-access` on every OS and updates the test.
- 2026-11-02 — commit `2062feea dx(agents): tune codex role models and effort`: raised the tester's reasoning effort from low to high (model and effort, not sandbox).
- 2026-11-06 — status check: `tester.toml.tmpl` line 6 is `sandbox_mode = "danger-full-access"`; its comment reads "Checks need network and writes to ~/.cache and /dev/stdout, which workspace-write blocks. Like the Claude tester, only instructions keep tracked files unchanged."

Commits listed in S under this entry that do not touch `tester.toml.tmpl` or the tester sandbox: `3301fe10 dx(agents): cut duplicate rules and fix conflicts` (2026-10-24), `727c4ce5 dx(review): prefer rg in reviewer search steps`, `2929fd0b dx(agents): restore the cheaper sonnet handoff`, `d2ba1443 dx(review): fix setup gaps and split tester steps` (added `tester-steps.md` for the review skill), `bd887691 dx(agents): fix skill steps found by setup audit`. They are audit-session commits from 446ca2ba (S: "not attributed") and are listed here only because S listed them.

## Results
Probe-backed, no A/B:
- 2026-10-21: local Codex logs showed sub-agents ran with full access although their agent files said read-only (the basis for the revert).
- 2026-10-27 (e0777840): a write under Codex's read-only sandbox failed with "Operation not permitted" for both the working folder and `$TMPDIR`; workspace-write allowed both. Then: workspace-write still blocked network, `~/.cache` and `/dev/stdout`, so the repo's own tests failed in the tester. After full access: 85 Python and 20 Node tests and both manual checks passed (run before the final change); after the `dbb58ebc` change the role-config test (4 tests) passed and the live role file showed `danger-full-access`.
- Open contradiction, not resolved in the session: on 10-21 the finding was that Codex ignores the role file's sandbox setting; on 10-27 the same setting was treated as effective (tests blocked by `workspace-write`). Not found: a run that directly compared both claims through a real spawned tester. Searched sessions 7ed59b69, e0777840 and the commit messages.
- Cost of the final state: the tester has full access, and only its instructions keep tracked files unchanged.

## Sources
- [Codex sandboxing docs](https://learn.chatgpt.com/docs/sandboxing) — read-only "can inspect files, but can't edit files or run commands without approval"; the page is silent on sub-agents.
- Codex protocol and spawn source and the Codex security docs were also fetched (session 446ca2ba and audit sessions 4b282477 and e0777840). The security docs page "doesn't answer your question".

## Evidence
The tester sandbox change was settled by a local test ("old read-only sandbox refused writes ... Operation not permitted"), so it is probe-backed. Sessions 7ed59b69 (2026-10-21), e0777840 (2026-10-27, which made both `c32dc76b` and `dbb58ebc`), 446ca2ba, 4b282477. The Codex protocol and spawn source URLs were not preserved.
