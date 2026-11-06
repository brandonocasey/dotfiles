# Agent setup A/B tests

Objective A/B tests behind the dotfiles agent setup: two or more arms on the same tasks, scored against an answer key, hidden tests, or a measured count (tokens, cost, time).

This folder sits outside the chezmoi root (`home/`), so chezmoi never applies it and agents never load it on their own.

Each doc has the question, setup, exact results per arm, validity limits, the decision, and the commits that applied it. To add a test, copy a doc, keep its sections, and name it `YYYY-MM-DD-<slug>.md`. Verify each commit with `git cat-file -e <sha>^{commit}`.

## Tests

- [Tester on Haiku vs Sonnet probes](ab-tests/2026-11-03-tester-haiku-vs-sonnet.md) — main bug found 2/2 both; tokens Sonnet 83k/140k vs Haiku 150k/178k
- [Effort trials: Haiku roles medium vs xhigh; Opus reviewer high vs xhigh](ab-tests/2026-11-02-effort-trials.md) — medium = xhigh 20/20 tasks, 6.6 vs 11.1 s; reviewer 20 vs 17 of 31 bugs
- [Haiku and Sonnet review replays against Opus and verified findings](ab-tests/2026-10-30-review-replays-vs-opus.md) — low tier 29 Haiku ($0.52) vs 30 Sonnet xhigh ($3.32) of 51 Opus findings
- [Haiku delegation probes, Haiku xhigh vs Sonnet](ab-tests/2026-10-30-haiku-delegation-probes.md) — 42 runs $0.051 Haiku vs $0.779 Sonnet, equal recall 3/3 per task
- [Reruns: review on vs off (w8), harder shortcut trap (w9), w10 rerun](ab-tests/2026-10-29-reruns-review-on-off.md) — w9 0/10 cheated; forced review costs 1.5-5x; w10 7/24 finished
- [Reworded review rule on Opus, calibration of harder tasks, real-history tasks](ab-tests/2026-10-28-reworded-review-rule.md) — review ran 6/6 vs 6/24 current rules; $2.08 vs $0.90 per run
- [Inline review vs sub-agent review: toy rounds and a real-bug round](ab-tests/2026-10-28-inline-vs-subagent-review.md) — R4 real bugs 3 vs 1 caught; $2.60 vs $0.68 per task; R1-R3 ceilinged
- [Global rules vs no rules, 10 planned tests](ab-tests/2026-10-28-global-rules-vs-none.md) — same hidden-test results all 7 tasks; Opus reviewed 6/24 runs, Sonnet 0/9
- [Main-session model and effort, and handoff A/B](ab-tests/2026-10-25-main-model-and-handoff.md) — feature $1.58 Sonnet med to $7.66 Opus xhigh; 54/54 passed; handoff -33% Opus med
- [Pipeline probes: agent pipeline vs inline](ab-tests/2026-10-23-pipeline-vs-inline.md) — medium task $1.41 inline vs $2.19 pipeline (14/14); 31-file handoff $4.34 vs $5.74 inline
- [AGENTS.md without CLAUDE.md probe](ab-tests/2026-10-15-agents-md-without-claude-md.md) — codeword: TMPDIR repo yes; HOME bare NONE; HOME with CLAUDE.md yes
- [ToolSearch-off cost probe: ToolSearch present vs absent, agents-md plugin on vs off](ab-tests/2026-10-14-toolsearch-off-cost.md) — 50,403 tokens plugin on/off vs about 595-617k tokens without ToolSearch
- [Reviewer model A/B: Opus xhigh vs Sonnet xhigh, with Sonnet max and Opus high](ab-tests/2026-10-14-reviewer-model-opus-vs-sonnet.md) — real bugs 24.5/27 Opus xhigh, 21.5/27 Opus high, 20/27 Sonnet xhigh
- [LSP tool A/B: token use on a shared-name symbol trace](ab-tests/2026-10-14-lsp-tool-tokens.md) — avg tokens 129,982 off vs 91,883 forced LSP (-29%), n=3
- [Concise style A/B: output-style wording and per-turn reminder](ab-tests/2026-10-14-concise-style.md) — median words 77 current, 85 +reminder, 80 merged, 111 Spartan, 88 built-in
- [Review experiment: single Opus xhigh vs xhigh plus Sonnet vs xhigh plus Opus low](ab-tests/2026-10-13-review-experiment-opus-pairs.md) — 3/5 xhigh x2, Sonnet 2/5 x2, Opus low 0/5 and 1/5
- [Auto-title cost probe: lean claude -p vs --bare vs plain claude -p](ab-tests/2026-10-13-auto-title-cost.md) — lean $0.00018/620 tokens vs plain $0.0098/210,575 tokens; --bare not logged in
- [Agent starting context: first-call input tokens, with and without omitClaudeMd](ab-tests/2026-10-13-agent-starting-context.md) — worker 14,238 to 6,661 tokens; manual-tester 11,803 to 4,746
- [Explorer routing: Haiku vs Sonnet on 5 search tasks](ab-tests/2026-10-12-explorer-haiku-vs-sonnet.md) — 5 tasks n=1: Haiku cost 37-75% of Sonnet; Haiku missed 3 of 5 hops/folders
- [compact-bench: auto-compact at 500k vs default](ab-tests/2026-10-07-compact-bench-500k.md) — R3 (n=1): $29.67/68 min vs $34.05/59 min; R1-R2 never reached 500k
