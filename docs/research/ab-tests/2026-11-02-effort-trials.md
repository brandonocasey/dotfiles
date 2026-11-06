# Nov 2 effort trials: Haiku roles medium vs xhigh; Opus reviewer high vs xhigh

- Date: 2026-11-02 (commits 09:29-14:35 EST)  Sessions: not found  Raw data: none found
- Related: [Haiku delegation probes](2026-10-30-haiku-delegation-probes.md) (set explorer and cheap to Haiku xhigh), [tester on Haiku vs Sonnet](2026-11-03-tester-haiku-vs-sonnet.md) (the next day), [Oct 14 Opus vs Sonnet reviewer test](2026-10-14-reviewer-model-opus-vs-sonnet.md)

## Question
Can the Haiku roles drop to medium effort and the Opus reviewer to high without losing quality?

## Setup
From commit messages only. Trial 1 ran cheap and explorer tasks at medium vs xhigh. Trial 2 ran the reviewer on 11 changes with known high/medium bugs (high vs xhigh). Trial 3 ran on 27 paired changes.

## Results
- Cheap and explorer: medium matched xhigh on 20 of 20 tasks. 6.6 s vs 11.1 s (40% faster).
- Reviewer trial 2: high found 6 of 11 high/medium bugs vs 5 of 10 at xhigh, at half the cost and time.
- Reviewer trial 3: 20 of 31 known high/medium bugs at xhigh vs 17 at high ("high likely misses about 1 in 10 serious bugs"). Cost $2.11 vs $1.13 per review.
- All numbers come from commits 750e9971, 8a029ed0, 569767d2 and a2a3d053 and from `roles.md`.

## Validity
- No transcript was found. The commits are dated 2026-11-02 09:29-14:35 EST (14:29-19:35 UTC). No indexed Claude or Codex session on this host overlaps that window with this topic (checked: work-repo sessions f040bfa2 and 92dbd1b7 overlap in time but are about an MR resume and a bundle check). It likely ran on another host.
- The 27-change set likely descends from the real-bug set in the Oct 14 reviewer A/B (unverified).
- Trials 2 and 3 conflict: high looked better (6/11 vs 5/10), then worse (17 vs 20 of 31).
- The reviewer was lowered and reverted within 5 hours.

## Decision
Haiku roles (cheap, explorer) lowered to medium. Reviewer lowered to high, then reverted to xhigh. Non-Opus reviewers (Haiku review, Sonnet fix checks) keep xhigh by explicit override.

## History
- 2026-10-14 — `61727b38 dx(claude): set per-model effort, cheap at xhigh`. Earlier effort baseline for the roles.
- 2026-10-30 — `9a476e31 dx(skills): hand more read-only work to haiku agents`. Explorer moved to Haiku xhigh (see delegation probes).
- 2026-11-02 09:29 — `750e9971 dx(agents): lower haiku roles to medium effort`. cheap and explorer to medium, citing the 20 of 20 trial.
- 2026-11-02 09:29 — `8a029ed0 dx(agents): lower opus reviewer to high effort`. Reviewer to high, citing 6 of 11 vs 5 of 10; Haiku reviews and Sonnet fix checks pass xhigh explicitly.
- 2026-11-02 09:35 — `d6823e44 dx(agents): keep non-opus reviewers at xhigh`. Review skill and roles keep xhigh for non-Opus reviewers.
- 2026-11-02 14:31 — `569767d2 revert(agents): put opus reviewer back at xhigh`. Reverts 8a029ed and d6823e4 after the 27-change trial (20 vs 17 of 31).
- 2026-11-02 14:35 — `a2a3d053 docs(agents): state reviewer trial cost exactly`. Fixes the cost figures in `roles.md`.
- 2026-11-02 16:23 — `2062feea dx(agents): tune codex role models and effort`. Same day: Codex explorer to gpt-6-luna xhigh, Codex tester and worker to high. No data found for it.
- Today: `cheap` and `explorer` are `claude-haiku-5-5`, effort `medium`. `reviewer` and `consult` are `claude-opus-5-5`, `xhigh`. `worker` is `claude-sonnet-5-5`, `high`. `roles.md` states the 20 of 20 trial, the 20 vs 17 of 31 trial and $2.11 vs $1.13 per review. No later commit changed these efforts.
