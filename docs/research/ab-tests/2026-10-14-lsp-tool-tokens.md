# LSP tool A/B: token use on a shared-name symbol trace

- Date: 2026-10-14  Sessions: bc200b0a  Raw data: deleted (`~/.cache/agents/scratch/lsp-ab/RESULTS.md` removed; no run transcripts found under `lsp-ab`)

## Question
Average input tokens per run for a symbol trace with the LSP plugins off vs on, under three rule wordings.

## Setup
Headless runs tracing a `publish` method in a work repo. Its name is shared by another `publish`, so `rg` returns false matches. 3 runs per setup, with plugins forced off or on per run and alternated. An empty-prompt baseline ran first (2 runs per setting). Before the test, the LSP tool had been added to the reviewer role and a search rule said to use LSP "when available". Scored by input tokens and whether the LSP tool was used; all runs checked for the same 4 call sites.

## Results
Average input tokens per run (runs in parentheses):

| Setup | Avg tokens | Runs | LSP used |
|---|---|---|---|
| Empty prompt, plugins off | 11,030 | 10,970 / 11,089 | n/a |
| Empty prompt, plugins on | 11,033 | 10,973 / 11,093 | n/a |
| Trace, plugins off | 129,982 | 143,115 / 108,329 / 138,501 | n/a |
| Trace, plugins on, old rule ("use LSP when available") | 121,837 | 152,039 / 114,310 / 99,162 | 0 of 3 |
| Trace, plugins on, new rule ("use LSP first") | 108,350 | 126,927 / 100,665 / 97,458 | 1 of 3 |
| Trace, prompt forces LSP | 91,883 | 151,799 / 82,899 / 40,952 | 3 of 3 |

- Forced LSP is 29% below plugins off. Forced runs took 9, 6 and 4 turns; the first asked LSP about the wrong line before correcting itself.
- All 12 trace runs found the same 4 call sites.
- Turning the plugins on adds about 3 tokens to an empty prompt.

## Validity
- 3 runs per setup; run-to-run variation up to 3x.
- Gaps between rows other than forced-LSP are within run-to-run variation.
- An earlier version of the test (before it moved into that repo) showed no difference; the model never used LSP in 5 tries.

## Decision
Rule changed to "For a named symbol's references or definition, use LSP first when available, loading it if deferred"; LSP tool given to the reviewer, explorer, worker, consult and tester roles; TypeScript, Python and Rust LSP plugins turned on. The "use LSP first" rule and the role-file LSP tool were removed on 2026-10-16.

## Commits
- `78752a06 dx(agents): give reviewer the LSP tool`
- `de2327e5 feat(lsp): enable Claude Code LSP plugins and servers`
- `ed25d9dd dx(agents): use LSP first for symbol lookups`
- `19187158 dx(agents): replace lsp with code graph tooling` (removed the rule, role-file LSP tool, install script, plugin entries)
- `3afe7502 dx(agents): tighten delegation and cleanup rules` (removed "use LSP first" from `private_AGENTS.md`)
- `6e59e96b dx(mise): drop unused codebase-memory-mcp`
- `4a1b8bfc build(claude): enable code intelligence plugins` (re-enabled the TypeScript, Python and Rust LSP plugins)
- `1856cb43 fix(claude): push ts 7 diagnostics to claude code`
