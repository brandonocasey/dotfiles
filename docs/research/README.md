# Research record for agent setup

Why the dotfiles agent setup changed: the sources behind each change, the A/B tests and probes, and what happened afterwards.

This folder sits outside the chezmoi root (`home/`), so chezmoi never applies it and agents never load it on their own. Read it on demand.

Each change doc has its status, a dated history of every commit that touched the rule, results, sources, and how the session used them. Each test doc has its question, setup, exact results, validity, decision, and history of what happened to that decision.

To add an entry, copy a doc of the same kind and keep its sections. Name it `YYYY-MM-DD-<slug>.md` and add one line below. Verify each commit with `git cat-file -e <sha>^{commit}` and copy its real subject. Link only raw data that still exists. Do not paste Claude session or artifact links.

## Changes

### Context and compaction

- [Auto-compact window: 400k for sub-agents, then all sessions](changes/2026-10-14-auto-compact-400k.md) — Changed: 400k set 10-14, now 433000 (compacts at 400k); a pick, not measured
- [Auto-compact at 500k: negatives, cost estimate and local benchmark](changes/2026-10-07-auto-compact-500k-question.md) — Never made; benchmark n=1, 500k saved 13% only in round 3 (maybe noise)

### Review

- [Review comments on own MRs: auto-mode rule and review skill](changes/2026-10-15-review-comments-own-mrs.md) — Current: auto-mode rule unchanged; skill mechanics rewritten many times
- [Read ranges instead of whole files; reviewer reads partials; Haiku setup helper](changes/2026-10-14-review-read-ranges.md) — Rule current; reviewer LSP and Haiku setup helper later removed
- [Light vs normal reviewer: tier added, then removed](changes/2026-10-14-light-vs-normal-reviewer.md) — Replaced: tier removed in 23 min; Opus xhigh 91%, Opus high 80%, Sonnet 74%
- [Review misses: fixed brief, Opus xhigh deep review, extra checks](changes/2026-10-13-review-misses-deep-review.md) — Mostly live in one Opus xhigh reviewer; brief wording shortened
- [Review loop: two cycles, fix checks, severity labels, auto-loop](changes/2026-10-13-review-loop.md) — Partly current: 2 cycles, 3 fix checks; pair and --no-loop gone

### Sub-agents and orchestration

- [Orchestrator context study: result cap, checkpoints, bulk checks](changes/2026-10-13-orchestrator-context-study.md) — Current: 40-line result cap, 5-line return; D8 hooks never committed

### Hooks

- [Session titles: port, branch and part number via sessionTitle](changes/2026-11-06-session-titles-port-branch.md) — current; 8 same-day commits, no measurement
- [Bash guard rewrites bad commands with updatedInput instead of blocking](changes/2026-10-28-bash-guard-updated-input.md) — current; 10 bugs fixed after review, 92 tests
- [Tmux bell when Claude waits for input](changes/2026-10-16-tmux-bell-on-wait.md) — current; grew into red/yellow/green pane state
- [Session names from the first prompt via a Haiku hook](changes/2026-10-13-session-names-haiku-hook.md) — current, reworked; about $0.0002 per title at most

### Skills

- [Skill descriptions tuned with skill-creator guide](changes/2026-11-05-skill-creator-tuning.md) — descriptions reverted (+1,000 chars); body trims kept

### Rules and instructions

- [Code-quality rules loaded by path with an edit gate](changes/2026-11-06-path-loaded-quality-rules.md) — current; baseline load rate 22% (47 of 211 sessions)
- [Review-driven code and comment rules](changes/2026-11-05-review-driven-code-rules.md) — current; test rule tightened next day; no measurement
- [Run verification checks without asking](changes/2026-11-05-checks-without-asking.md) — current; no source backs the rule; no measurement
- [Best-practices pass: two tries then /clear, compaction note, LSP plugins](changes/2026-10-best-practices-pass.md) — current; rules unedited since ff6e4303; not re-measured
- [LSP-first lookup rule and LSP plugin enablement](changes/2026-10-15-lsp-first-lookup.md) — rule reverted 10-16; plugins re-enabled 10-18; 3-run A/B
- [Copy output via /copy](changes/2026-10-13-copy-output.md) — current; net +90 rule tokens, copy files dropped
- [Main-session rules moved into a custom output style](changes/2026-10-12-output-style-rules.md) — current; shared AGENTS.md 2.65k to 1.4k tokens

### Settings, permissions and security

- [Agent summary suppression via BUN_OPTIONS preload](changes/2026-10-29-bun-options-summary-suppression.md) — current; preload live, 15-20% savings claim never verified
- [Pin Claude Code 2.1.296 so context-lean hooks run](changes/2026-10-27-pin-claude-code-2-1-296.md) — current; 2.1.318 still bypasses context-lean (11-05)
- [Prompt-cache TTL, credential-read denies, cold-cache hook](changes/2026-10-14-cache-ttl-and-permission-denies.md) — current; 1h TTL, Read denies, cold-cache hook live
- [Setup audit: sandbox, auto mode, Codex guard](changes/2026-10-13-setup-audit-sandbox-auto-mode.md) — changed; sandbox off, auto-mode rules; Codex hook dropped 10-19
- [Codex rules file to prompt for merges and force pushes](changes/2026-10-13-codex-rules-file.md) — current; prompt rules live, no real-session prompt test found
- [Observability MCP loaded only via a separate launcher](changes/2026-10-08-observability-mcp-opt-in.md) — removed 10-12; context-lean hides connector tools instead

### Terminal and UI

- [Statusline links, ports and agent rows](changes/2026-10-16-statusline-links-ports.md) — current; links, port blocks and agent rows live
- [Tmux hyperlink passthrough for Ghostty](changes/2026-10-15-tmux-hyperlinks-ghostty.md) — current; not tested in a live Ghostty window

### Incidental doc use (the change was not driven by the source)

- [Codex tester sandbox and log access](changes/2026-10-21-codex-tester-sandbox.md) — replaced twice; now danger-full-access on all OSes
- [HR days to calendar out-of-office](changes/2026-10-15-hr-days-to-calendar-ooo.md) — current; probe passed (HTTP 200), review fixed 5 bugs
- [tmux plugins installed on apply](changes/2026-10-13-tmux-plugins-on-apply.md) — current; runs only when the plugin list changes
- [Rule trims driven by a local audit](changes/2026-10-13-rule-trims-local-audit.md) — current; 74 of 77 trim items applied, bare-Bash trim reverted

### Not adopted

- [Not adopted: options considered and rejected or removed](changes/not-adopted.md) — Collection of 13 declined items with sessions and later status

## A/B tests and probes

- [Tester value analysis, 203 historical tester runs](ab-tests/2026-11-05-tester-value-analysis.md) — 20% real bugs, 53% all passed; tester kept
- [Rule-loading probes and quality-rules analysis](ab-tests/2026-11-05-rule-loading-probes.md) — Path rules + gate hook adopted; live in rule-gate.py
- [Tester on Haiku vs Sonnet probes](ab-tests/2026-11-03-tester-haiku-vs-sonnet.md) — Both found all bugs; tester moved to Haiku high
- [Nov 2 effort trials: Haiku medium; Opus reviewer high](ab-tests/2026-11-02-effort-trials.md) — Haiku roles medium kept; reviewer high reverted to xhigh
- [Haiku and Sonnet review replays against Opus](ab-tests/2026-10-30-review-replays-vs-opus.md) — Low tier to Haiku; inline and Sonnet review modes dropped
- [Haiku delegation probes, Haiku xhigh vs Sonnet](ab-tests/2026-10-30-haiku-delegation-probes.md) — Haiku matched Sonnet at ~15x less cost; explorer to Haiku
- [Reruns: review on vs off, shortcut trap, w10](ab-tests/2026-10-29-reruns-review-on-off.md) — Inconclusive; forced review 1.5-5x cost; no rule change
- [Reworded review rule on Opus, harder tasks](ab-tests/2026-10-28-reworded-review-rule.md) — Review ran 6 of 6 vs 6 of 24; rule not applied
- [Inline vs sub-agent review](ab-tests/2026-10-28-inline-vs-subagent-review.md) — Sub-agent caught 3 of 7 real bugs vs 1; sub-agent kept
- [Global rules vs no rules, 10 planned tests](ab-tests/2026-10-28-global-rules-vs-none.md) — Same quality both arms; Opus skipped review in 18 of 24
- [Main-session model and effort, and handoff A/B](ab-tests/2026-10-25-main-model-and-handoff.md) — Opus medium kept; handoff -33% on Opus; nested guard added
- [Pipeline probes: agent pipeline vs inline](ab-tests/2026-10-23-pipeline-vs-inline.md) — Full pipeline rejected; 15+ file Sonnet handoff -24% adopted
- [AGENTS.md without CLAUDE.md probe](ab-tests/2026-10-15-agents-md-without-claude-md.md) — AGENTS.md ignored under $HOME without a CLAUDE.md; keep one-line CLAUDE.md
- [ToolSearch-off cost probe](ab-tests/2026-10-14-toolsearch-off-cost.md) — ToolSearch missing sent ~600k tokens per call; headless guard added
- [Reviewer model A/B: Opus xhigh vs Sonnet xhigh](ab-tests/2026-10-14-reviewer-model-opus-vs-sonnet.md) — Real bugs: Opus xhigh 91%, Opus high 80%, Sonnet 74%; Opus xhigh kept
- [LSP tool A/B: token use on a shared-name symbol trace](ab-tests/2026-10-14-lsp-tool-tokens.md) — Forced LSP -29% tokens (n=3); LSP-first rule later dropped, plugins on
- [Concise style A/B: output-style wording and reminder](ab-tests/2026-10-14-concise-style.md) — 120 runs; reminder no effect, rules merged, reminder hook dropped 10-16
- [Review experiment: Opus xhigh vs xhigh plus Sonnet or Opus low](ab-tests/2026-10-13-review-experiment-opus-pairs.md) — Opus xhigh alone 3/5; pairing added nothing; fixed brief and checks
- [Auto-title cost probe](ab-tests/2026-10-13-auto-title-cost.md) — Haiku title ~$0.0002 max per call; --bare needs API key; hook live
- [Agent starting-context audit](ab-tests/2026-10-13-agent-starting-context.md) — omitClaudeMd: worker 14.2k to 6.7k, manual-tester 11.8k to 4.7k tokens
- [Explorer routing: Haiku vs Sonnet on 5 search tasks](ab-tests/2026-10-12-explorer-haiku-vs-sonnet.md) — Haiku tied on lists, missed on traces; explorer is Haiku medium today
- [Deep vs normal reviewer, observational](ab-tests/2026-10-08-deep-vs-normal-reviewer.md) — Deep reviewer found real issues in 3 of 4 runs; paired rule later merged
- [compact-bench: auto-compact at 500k vs default](ab-tests/2026-10-07-compact-bench-500k.md) — One compaction at 466k (R3): -13% cost, +15% time; may be noise
