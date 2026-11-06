# LSP-first lookup rule and LSP plugin enablement

- Status (2026-11-06): the rule is reverted, plugin enablement is current. `home/.chezmoitemplates/agents/search.md` has no "use LSP first" sentence; its first line is "For a named symbol, find references with `rg -n '\bName\b'` ... Use `ast-grep` only when text matches would be ambiguous." No agent role file lists the `LSP` tool. `home/.chezmoitemplates/claude-settings-modify.sh` (lines 497-499) enables `typescript-lsp`, `pyright-lsp` and `rust-analyzer-lsp` plugins, re-added by `4a1b8bfc`.
- Topic: Rules and instructions
- Related: [LSP tool token A/B](../ab-tests/2026-10-14-lsp-tool-tokens.md), [Best-practices pass](2026-10-best-practices-pass.md), [Review read ranges](2026-10-14-review-read-ranges.md)

## Change
After an A/B (3 runs per setup, tracing a shared-name `publish` method in a work repo), the session enabled LSP plugins, added the LSP tool to the explorer, worker, consult and tester roles (and reviewer, in `78752a06`), and set the rule: "For a named symbol's references or definition, use LSP first when available, loading it if deferred; otherwise ... `ast-grep` ... `rg -n`". Language servers were installed through mise plus a TypeScript 7 wrapper `typescript-language-server`.

## History
- 2026-10-12 — `47555eea dx(claude): enable lsp plugins for code navigation` and `8236cf3b dx(claude): enable rust lsp plugin`: plugins enabled in the settings template, before this change; they stayed off in practice because the settings script reset `enabledPlugins` on each apply (per `4a1b8bfc`).
- 2026-10-14 — session bc200b0a (long session, about 15:27 to 23:55 UTC). While reworking the reviewer, the user said "reviewer should read partials using lsp/ast-grep/sed/rg as best as possible to save tokens, but still read all the needed context" and "in general this should always be the rule. the file read tool might actually be worse than this recommendation", then asked "is the lsp tool experimental or something? did you update the main session to do this too?". The assistant first said LSP needs `ENABLE_LSP_TOOL=1`, then "I was wrong about `ENABLE_LSP_TOOL`. The docs don't mention it", and removed that step. It found the three code-intelligence plugins were off, so nobody had the tool.
- 2026-10-14 — the user chose "1, but mention when available" and later "can we use mise instead and set it up so that it's automatic in chezmoi", "remove from brew", "why not 7?" (TypeScript 7 server).
- 2026-10-14 — `78752a06 dx(agents): give reviewer the LSP tool`.
- 2026-10-15 — A/B results: see the test doc (average input tokens 129,982 plugins off; 121,837 on with the old rule; 108,350 with "LSP first"; 91,883 forced; 0 of 3, 1 of 3 and 3 of 3 runs used LSP).
- 2026-10-15 — `de2327e5 feat(lsp): enable Claude Code LSP plugins and servers`: mise installs rust-analyzer, pyright and a TS7 wrapper; LSP added to `cheap`, `consult`, `explorer`, `tester` and `worker` role tools; plugins enabled in settings. Committed on 2026-10-15 10:51 local by a later sync.
- 2026-10-15 — `ed25d9dd dx(agents): use LSP first for symbol lookups`: the "use LSP first when available, loading it if deferred" wording in `search.md`, `reviewer-steps.md` and `AGENTS.md`.
- 2026-10-16 — `19187158 dx(agents): replace lsp with code graph tooling`: removes the "use LSP first" wording, the LSP install script, the three plugin enablements, the LSP role tools, and the mise language servers. It adds `github:DeusData/codebase-memory-mcp` (a code-graph MCP server) to mise. The reason is not in the commit message and was not found in a session (searched for the sha and subject).
- 2026-10-16 — `6e59e96b dx(mise): drop unused codebase-memory-mcp`: the code-graph server was removed from mise the same day.
- 2026-10-18 — `4a1b8bfc build(claude): enable code intelligence plugins`: re-adds plugin enablement with a TS7 wrapper, from the best-practices pass. It did not restore the "use LSP first" rule or the LSP role tools.
- 2026-10-24 — `3301fe10 dx(agents): cut duplicate rules and fix conflicts`: edited `search.md` among other rule dedupes; no LSP wording remained.

## Results
Measured in the A/B (direction only): "LSP first" cut average input tokens from 121,837 to 108,350 (-11%), but only 1 of 3 runs used LSP. Forcing LSP in the prompt got 91,883 (-29% against plugins off) with 3 of 3 runs using it. All 12 runs found the same 4 call sites. Runs varied up to 3x. The assistant labelled it "unverified: 3 runs each, within noise". Problem seen: the rule did not make the model use the tool (0 of 3 with the old rule, 1 of 3 with the new one), and the rule and tool setup were dropped one day after commit. No session explaining the removal was found.

## Sources
No web sources as support. A sub-agent WebFetch of code.claude.com settings and tools-reference docs established that the LSP tool exists and that `ENABLE_LSP_TOOL` is not documented (the session first claimed it, then retracted). The local A/B is in the test doc.

## Evidence
Small local A/B, self-labelled "direction only", "unverified: 3 runs each, within noise". Session bc200b0a (2026-10-14).
