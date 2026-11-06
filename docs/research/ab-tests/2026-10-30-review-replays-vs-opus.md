# Haiku and Sonnet review replays against Opus and verified findings

- Date: 2026-10-30  Sessions: 80b76ea2 (2026-10-30 13:45-18:44 UTC)  Raw data: `~/.cache/agents/output/haiku-review-replay/` is deleted. The review store at `~/.local/state/agents/reviews` still exists. 21 headless replay run transcripts survive as Claude project dirs named `*80b76ea2*replay*`.
- Related: [Haiku delegation probes](2026-10-30-haiku-delegation-probes.md) (earlier the same day, the session being continued), [inline vs sub-agent review](2026-10-28-inline-vs-subagent-review.md), [Oct 14 Opus vs Sonnet reviewer](2026-10-14-reviewer-model-opus-vs-sonnet.md), [effort trials](2026-11-02-effort-trials.md)

## Question
Can Haiku or Sonnet review low and medium changes, and where is the breaking point?

## Setup
- Replay of past stored reviews (`~/.local/state/agents/reviews`: 41 full reviews, 32 with verified fixed findings, 137 verified and 10 killed). Every stored reviewer run was Opus xhigh.
- Replay 1: 21 mixed changes, 86 labeled fixed findings.
- Low-tier replay: 12 docs/test commits against Opus findings.
- Sonnet rerun at xhigh on all cases (the first runs used medium by mistake).
- Medium replay: 6 commits of 81-296 lines.
- Sonnet judged matches. Sonnet at high verified extras.
- The session opened with "continue 'Explore Haiku cost-saving task delegation'" and the user said "run the replay". Later user turns: "ok so what about low risk?", "what effort levels did we use?", "sonnet should have used xhigh to review..", "will inline really cost less than haiku ever?", "how did sonnet fair vs opus for medium?", "is sonnet even worth using at all then?".

## Results
- Replay 1 (Haiku xhigh vs Sonnet medium): all 86 findings 13 (15%) vs 8 (9%). Medium/high 0 of 16 vs 2 of 16. Cost $2.00 vs $3.28. After dropping an invalid working-tree case: 76 findings 13 (17%) vs 8 (11%), medium/high 0 of 14 vs 2 of 14.
- Low tier (51 Opus findings, 26 medium/high): Haiku 29 (17 medium/high) $0.52. Sonnet medium 18 (13) $1.44. Opus $6.27.
- Sonnet xhigh rerun (mixed 18 cases / 68 findings; low 12 / 51): mixed Haiku 11, Sonnet medium 8, Sonnet xhigh 16. Mixed medium/high (13): 0, 2, 3. Low all: 29, 18, 30. Low medium/high (26): 17, 13, 19.
- Sonnet xhigh low tier cost $3.32, about 2x medium. Rerun total $11.20 (cap $9).
- Verification: of Haiku's 28 unmatched low-tier findings Sonnet confirmed 14, rejected 11, 3 unclear ($0.95). Haiku valid 43 of 55 (78%) vs Sonnet xhigh about 35 of 42 (85%). Review cost $0.52 vs $3.32.
- Medium (6 commits, 17 Opus findings, 11 medium): Haiku 7 (6 medium) $0.35, 15 of 19 valid. Sonnet xhigh 10 (9 medium) $2.10, 14 of 15 valid. Opus $4.09.
- Session total about $37 (earlier $29 at first sync).

## Validity
- Labels are circular: Opus findings, unverified in the low and medium replays.
- Replay 1 had 13-16 medium/high findings.
- The low tier was 8 docs-only and 4 test-only commits (the assistant first said 11 docs-only, then corrected).
- One run each. Sonnet's first run was at the wrong effort.
- Spend overran estimates ($27-37 vs $5-15).
- One invalid low-tier working-tree case.
- Replay 1 and the medium replay conflict (Sonnet 3 of 13 vs 9 of 11 medium), so there was no change to the medium tier beyond dropping Sonnet.

## Decision
- Low tier to Haiku xhigh. Inline mode removed.
- Sonnet review mode removed: medium and up go to Opus xhigh. Sonnet xhigh kept for fresh fix checks only.
- Worker and tester raised to Sonnet high and consult to Opus xhigh by user instruction ("sonnet worker/tester should be high rather than medium. consult should be opus xhigh"), no test.

## History
- 2026-10-14 — `35fb091e dx(review): review every change with opus only` and `13c6a0e2 dx(review): add light-reviewer tier`. Earlier review-model decisions this test revised.
- 2026-10-20 — `23662f0c dx(review): use sonnet for low-risk and fix checks`. The setup the replay measured.
- 2026-10-30 00:29 EDT — `e3ee004f dx(skills): cheaper review modes for small changes`. Added an inline mode for tiny docs-only changes. Before this session; not caused by it.
- 2026-10-30 13:43 — `10da7d14 dx(skills): review low-tier changes with haiku`. Low tier reviewed by Haiku.
- 2026-10-30 13:49 — `fe308270 dx(skills): keep audit skill under size limit, fix replay count`. Housekeeping on the audit skill after the replay numbers changed.
- 2026-10-30 14:26 — `212863cd dx(skills): drop inline review mode, send low tier to haiku`. Removes inline mode after the cost comparison.
- 2026-10-30 14:38 — `fd673112 dx(skills): review medium changes with opus, keep sonnet for fix checks`. Drops Sonnet as a review mode.
- 2026-10-30 14:43 — `d3d2dfb9 dx(agents): raise worker and tester effort, consult on opus`. By user instruction.
- 2026-11-03 — `23539612 dx(agents): run tester on haiku after probes` later moved the tester to Haiku (see that test). Not a review-mode change.
- Today: `review/exact_references/setup.md` sets mode `haiku` for tier `low` (docs, Markdown, comments, test files, under 400 lines; reviewer at `xhigh`) and `opus` for everything else. `review/SKILL.md` passes `model: haiku` for a haiku-mode review and reruns once with the default model on `Risk: high` or a surviving high bug. `delegation.md` states the replay numbers (55 findings, 43 valid for Haiku; Sonnet xhigh 42, about 35 valid at 6x the cost). Sonnet reviews only fresh fix checks. `34591586 dx(skills): update review and ticket rules` (2026-10-29), listed as adjacent in the old record, is about agt `kept_local` posting and is not related to this test.
