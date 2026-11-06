# Not adopted: options considered and rejected, removed or left undone

- Status (2026-11-06): collection. Each item below was considered in a session and not made, or made and removed before or soon after commit. Where the repo was checked on 2026-11-06 the check is stated. Two items later turned out differently: the main session now defaults to Sonnet (`907d4b39`, 2026-10-20) and `idleCompaction` is on (`dab770cd`, 2026-11-05).
- Topic: Not adopted
- Related: [auto-compact 400k](2026-10-14-auto-compact-400k.md), [auto-compact 500k question](2026-10-07-auto-compact-500k-question.md), [review misses](2026-10-13-review-misses-deep-review.md), [review loop](2026-10-13-review-loop.md), [light vs normal reviewer](2026-10-14-light-vs-normal-reviewer.md), [orchestrator context study](2026-10-13-orchestrator-context-study.md), [cache TTL and permission denies](2026-10-14-cache-ttl-and-permission-denies.md), [Codex tester sandbox](2026-10-21-codex-tester-sandbox.md), [setup audit and sandbox](2026-10-13-setup-audit-sandbox-auto-mode.md), [bun options summary suppression](2026-10-29-bun-options-summary-suppression.md), [Haiku delegation probes](../ab-tests/2026-10-30-haiku-delegation-probes.md), [compact-bench](../ab-tests/2026-10-07-compact-bench-500k.md)

## Change
No change. This doc lists what was left out. Items are grouped by the session that decided them.

- Review misses (session 1602cbf2, 2026-10-13): DJ-style `.bots/review.yaml` per repo; skipping complexity, architecture and naming-taste categories from DJ's list; a per-repo never-flag list ([Anthropic claude-code-security-review](https://github.com/anthropics/claude-code-security-review)); several runs with merged findings ([SWR-Bench](https://arxiv.org/html/2509.01494v2)); a 1-10 confidence score; PR-Agent two-model ranker; Shippie/ai-codereviewer; the Google human review checklist; security-review's "don't run bash". The Sonnet+deep pairing was adopted then dropped after the 6-run experiment.
- 500k auto-compact (990ee95c, 2026-10-07): setting `autoCompactWindow` 500k (blocked, not done); a round 4 with a larger task. Sources: the Context Rot, Lost in the Middle, Complexity Trap and Anthropic context-engineering links in the [500k doc](2026-10-07-auto-compact-500k-question.md).
- Orchestrator study (acb7f610, 2026-10-13): proposal 5 (output-style "Show data in full" exception) and the rules flagged as conflicting needed the user's decision; D8 settings/hooks built then removed. Sources: [Claude Code hooks](https://code.claude.com/docs/en/hooks), [Claude Code workflows](https://code.claude.com/docs/en/workflows).
- Review loop (f9eb94ba, 2026-10-13): raising the cap to 4; looping until clean ("may never get clean"); removing `--loop`; model debate between reviewers ([Should we be going MAD?](https://proceedings.mlr.press/v235/smit24a.html), [controlled debate study](https://arxiv.org/pdf/2511.07784): studies do not support it).
- Light reviewer (bc200b0a, 2026-10-14): Sonnet xhigh/max as normal reviewer (A/B: 74% vs 91%); Opus high (80%); a "dismissed section" Sonnet prompt test (about $30, not run); topic checklists; per-file split reviews; narrowing size/type thresholds for a light tier; the light tier itself (removed). An unrequested gpt-6.1-sol review run was stopped by the user.
- 400k window (01c1e1f7, 2026-10-14): `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60` (removed because [#63186](https://github.com/anthropics/claude-code/issues/63186) and [#36381](https://github.com/anthropics/claude-code/issues/36381) suggest settings.json is ignored); global `CLAUDE_CODE_AUTO_COMPACT_WINDOW=300000` not added.
- 400k window (dda15a16, 2026-10-14): `worker` role to Haiku (rejected, judgment work); `autoCompactWindow` 500k (superseded by 400k); main session on Sonnet (left to the user).
- Agent summaries (77d6ff05, 2026-10-29): `CLAUDE_CODE_FORK_SUBAGENT=0` and `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` (not chosen); the 15-20% savings claim from the [flamerix-ai gist](https://gist.github.com/flamerix-ai/c3905705cc4205e5de3011fa2e74efce) was never verified.
- Reviewer benchmarks (c974856b, 2026-10-30): [AACR-Bench](https://arxiv.org/html/2601.19494v1), [CR-Bench](https://arxiv.org/html/2603.11078v1), [Sphinx](https://arxiv.org/pdf/2601.04252), Qodo PR-Review-Bench, CodeFuse-CR-Bench and MacroscopeBench were surveyed to benchmark Haiku vs Sonnet reviewers. "I only read search snippets, so everything below is unverified". No benchmark was run from them and no config change was made; the Haiku routing edits in that session rest on the A/B probes.
- Disk cleanup tools (ecfe1795, 2026-10-12): `tonz` ([github.com/axect/tonz](https://github.com/axect/tonz)) and `disky` ([docs.rs/crate/disky](https://docs.rs/crate/disky/latest)) were added then removed before commit `02e043ba` as untested.
- Codex tester read-only sandbox (7ed59b69, 2026-10-21): reverted, see [Codex tester sandbox](2026-10-21-codex-tester-sandbox.md).
- Prompt-cache and settings (7e8db009, 2026-10-14): items 1 and 2 (`autoCompactWindow` for Opus, narrow WebFetch allow) declined by the user ("dont do 1/2"); item 6 (idleCompaction vs keepalive) was left ambiguous.
- Setup audit (bd76000a, 2026-10-13/14): CC-2 (narrow sandbox domains) and C1 (enforce Codex read-only) not fixed; the sandbox was turned off instead.

## History
- 2026-10-07 — 990ee95c: settings edit for 500k blocked by the auto-mode classifier. No setting changed. A later session set 400k instead.
- 2026-10-12 — ecfe1795 added `tonz` and `disky` to the disk-cleanup skill, then removed them. Commit `02e043ba dx(skills): full-disk scans; rename worktree-cleanup` (2026-10-12) is the one the removal predates. A search of `home` finds neither name today.
- 2026-10-13 — 1602cbf2, acb7f610, f9eb94ba (see items above). The 6-run experiment ended the Sonnet+deep pairing in `71ee6bb1 dx(review): use one reviewer and loop every fix`. D8 was removed in session 66da602a before commit `d813f42b dx(agents): trim rules and cap agent result size`.
- 2026-10-14 — 01c1e1f7 removed the 60% override before commit `77cc26cc dx(agents): compact subagents at 400k tokens`. bc200b0a removed the light tier in `35fb091e dx(review): review every change with opus only`. dda15a16 declined a Haiku `worker` and a 500k window. 7e8db009 and bd76000a made the declines listed above (bd76000a ran 2026-10-13 23:54Z to 2026-10-14 02:25Z; the user said "turn sandbox off globally.  make fixes").
- 2026-10-20 — `907d4b39 dx(claude): default to sonnet high, halve bash output` made the main session default to Sonnet, which dda15a16 had left to the user.
- 2026-10-21 — 7ed59b69 reverted the Codex tester read-only sandbox.
- 2026-10-29 — 77d6ff05 did not adopt `CLAUDE_CODE_FORK_SUBAGENT=0` or `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`. Neither name is in `home` (checked 2026-11-06). The session's other result is in [bun options summary suppression](2026-10-29-bun-options-summary-suppression.md).
- 2026-10-30 — c974856b surveyed reviewer benchmarks; no config change from them.
- 2026-11-05 — `dab770cd dx(claude): turn on idle compaction setting` turned on `idleCompaction`, which 7e8db009 had left ambiguous.
- 2026-11-06 — Checked in the repo: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`, `CLAUDE_CODE_FORK_SUBAGENT`, `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`, `review.yaml`, `tonz` and `disky` are not present in `home`. The `worker` role is `claude-sonnet-5-5` at high effort and `tester` is `claude-haiku-5-5` at high effort.

## Results
No measurement for most items; they were decisions. Measured results behind some of them:
- Light reviewer and Sonnet as a normal reviewer: Opus xhigh 91%, Opus high 80%, Sonnet xhigh 74% on 27 real bugs. See [light vs normal reviewer](2026-10-14-light-vs-normal-reviewer.md).
- Sonnet+deep pairing: the 6-run experiment found xhigh alone 3/5, plus Sonnet 3/5, plus Opus low 3/5. See [review misses](2026-10-13-review-misses-deep-review.md).
- 500k window: n=1 per arm, no change attributable. See the [500k doc](2026-10-07-auto-compact-500k-question.md).
- Review-loop ideas (cap 4, loop until clean, debate): no local data; the studies did not support debate. See [review loop](2026-10-13-review-loop.md).
- Reviewer benchmarks (c974856b): not run. The session said "I only read search snippets, so everything below is unverified".
- The flamerix-ai 15-20% savings claim was never verified.

## Sources
Links are in the items above, with the claim each supported.

## Evidence
All web claims in this list come from the sessions named. Where a session marked a claim unverified or snippet-only, the item says so. The bd76000a, 77d6ff05, c974856b, 7e8db009 and ecfe1795 sessions are indexed here only by the S notes and the first human turns checked for this doc, not read in full.
