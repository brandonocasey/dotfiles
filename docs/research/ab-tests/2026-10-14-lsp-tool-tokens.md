# LSP tool A/B: token use on a shared-name symbol trace

- Date: 2026-10-14 (evening UTC, about 21:20-21:42)  Sessions: bc200b0a  Raw data: `~/.cache/agents/scratch/lsp-ab/RESULTS.md` is deleted (`test -e` fails). No run transcripts found under the name `lsp-ab`.
- Related: [LSP-first lookup rule](../changes/2026-10-15-lsp-first-lookup.md), [Main session reads nothing for review; read ranges](../changes/2026-10-14-review-read-ranges.md), [Reviewer model A/B](2026-10-14-reviewer-model-opus-vs-sonnet.md) (same session)

## Question
Does having the LSP tool (Claude Code LSP plugins on) reduce tokens for symbol tracing?

## Setup
Headless runs that trace a `publish` method in the vitrine repo. Its name is shared by another `publish`, so `rg` returns false matches. 3 runs per setup, with plugins forced off or on per run and alternated. An empty-prompt baseline ran first (2 runs per setting). Before this test, the session had added the LSP tool to the reviewer role and a search rule saying to use LSP "when available".

## Results
Average input tokens per run.
- Empty prompt, plugins off: 11,030 (10,970 and 11,089). Plugins on: 11,033 (10,973 and 11,093). Turning the plugins on adds about 3 tokens.
- Trace, plugins off: 129,982 (143,115 / 108,329 / 138,501).
- Trace, plugins on, old rule ("use LSP when available"): 121,837 (152,039 / 114,310 / 99,162). LSP used in 0 of 3.
- Trace, plugins on, new rule ("use LSP first"): 108,350 (126,927 / 100,665 / 97,458). LSP used in 1 of 3.
- Trace, prompt forces LSP: 91,883 (151,799 / 82,899 / 40,952). LSP used in 3 of 3. That is 29% below plugins off. The forced runs took 9, then 6, then 4 turns; the first asked LSP about the wrong line before correcting itself.
- All 12 trace runs found the same 4 call sites.
- Why the model skipped LSP, per the session: the LSP tool's description loads only when the model searches for it, so it reaches for `rg`, which it already has. "When available" was too weak to change that.

## Validity
- 3 runs per setup; runs vary up to 3x. The session wrote: "direction, not exact" and that the gaps between rows are within run-to-run noise, apart from the forced-LSP row.
- The early version of the test (before it moved into the vitrine repo) did not show a difference; the model never touched LSP in 5 tries.
- Rust LSP did not work on this machine at the time (`rust-analyzer` failed with "infinite recursion detected" in the juncture repo, a mise and rustup loop). The user chose the rustup fix, then asked for mise instead and automatic reruns in chezmoi, so the three servers install through mise. This did not affect the vitrine trace.

## Decision
Strengthen the rule to "For a named symbol's references or definition, use LSP first when available, loading it if deferred", give the LSP tool to the reviewer, explorer, worker, consult and tester roles, and turn the three LSP plugins on (TypeScript, Python, Rust). The user replied "1, but mention when available" (option 1: strengthen the rule), then ran the rule script. The user ran the plugin-on script (`lsp-on.sh`) at 21:23 UTC because the assistant could not edit settings.

## History
- 2026-10-14 — Test run in bc200b0a. The reviewer review of the LSP changes found 1 low bug (servers never installed) and 1 question (the Haiku helper lacked the tool).
- 2026-10-14 — `78752a06 dx(agents): give reviewer the LSP tool` (reviewer `tools:` gained `LSP`).
- 2026-10-15 — `de2327e5 feat(lsp): enable Claude Code LSP plugins and servers`: plugins on, LSP tool added to cheap, consult, explorer, tester and worker, servers installed via mise, `typescript-language-server` wrapper.
- 2026-10-15 — `ed25d9dd dx(agents): use LSP first for symbol lookups`: the "use LSP first when available" wording in `private_AGENTS.md`, `agents/search.md` and `reviewer-steps.md`.
- 2026-10-16 — `19187158 dx(agents): replace lsp with code graph tooling`: removed the "use LSP first" wording, the LSP tool from the role files, the LSP install script, the plugin entries in settings and the wrapper; mise gained `github:DeusData/codebase-memory-mcp`.
- 2026-10-16 — `3afe7502 dx(agents): tighten delegation and cleanup rules`: also removed "use LSP first" from `private_AGENTS.md`.
- 2026-10-16 — `6e59e96b dx(mise): drop unused codebase-memory-mcp`: the code-graph server was dropped the same day. The deciding session for the replacement was not found (searched transcripts for the commit subject and `codebase-memory-mcp`; hits were only history-reading sub-agents).
- 2026-10-18 — `4a1b8bfc build(claude): enable code intelligence plugins`: the settings script had been resetting `enabledPlugins` on every apply, so the LSP plugins stayed off. Re-enabled TypeScript, Python and Rust LSP; TypeScript 6+ workspaces use the TypeScript 7 server.
- 2026-10-18 — `1856cb43 fix(claude): push ts 7 diagnostics to claude code`: TypeScript 7 answers only pull diagnostics; a bridge pushes them.
- Today: the three LSP plugins are on (`claude-settings-modify.sh`: `typescript-lsp`, `pyright-lsp`, `rust-analyzer-lsp` set true). There is no "use LSP first" rule: `search.md` and `private_AGENTS.md` say to find symbols with `rg -n` and `ast-grep`. The reviewer's `tools:` list has no `LSP`.
