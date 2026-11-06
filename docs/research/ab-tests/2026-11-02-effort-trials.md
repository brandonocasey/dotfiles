# Effort trials: Haiku roles medium vs xhigh; Opus reviewer high vs xhigh

- Date: 2026-11-02  Sessions: not found  Raw data: none found (numbers come from commits 750e9971, 8a029ed0, 569767d2 and a2a3d053 and from `roles.md`)

## Question
Haiku roles (cheap, explorer) at medium vs xhigh effort, and the Opus reviewer at high vs xhigh, on tasks matched, known high/medium bugs found, time and cost.

## Setup
Known only from commit messages. Trial 1: cheap and explorer tasks at medium vs xhigh. Trial 2: the reviewer on 11 changes with known high/medium bugs (high vs xhigh). Trial 3: 27 paired changes.

## Results
- Cheap and explorer (trial 1): medium matched xhigh on 20 of 20 tasks; 6.6 s vs 11.1 s (40% faster).
- Reviewer trial 2: high found 6 of 11 high/medium bugs vs 5 of 10 at xhigh, at half the cost and time.
- Reviewer trial 3: 20 of 31 known high/medium bugs at xhigh vs 17 at high; cost $2.11 vs $1.13 per review.

## Validity
- No transcript or session found; the commits are dated 2026-11-02 09:29-14:35 EST.
- The 27-change set may derive from the real-bug set of the [Oct 14 reviewer A/B](2026-10-14-reviewer-model-opus-vs-sonnet.md) (unverified).
- Trials 2 and 3 disagree on direction (high 6/11 vs xhigh 5/10, then high 17 vs xhigh 20 of 31).

## Decision
Haiku roles (cheap, explorer) lowered to medium. Reviewer lowered to high, then reverted to xhigh within 5 hours. Non-Opus reviewers (Haiku review, Sonnet fix checks) keep xhigh by explicit override.

## Commits
- `61727b38 dx(claude): set per-model effort, cheap at xhigh` (baseline)
- `750e9971 dx(agents): lower haiku roles to medium effort`
- `8a029ed0 dx(agents): lower opus reviewer to high effort`
- `d6823e44 dx(agents): keep non-opus reviewers at xhigh`
- `569767d2 revert(agents): put opus reviewer back at xhigh` (reverts 8a029ed0 and d6823e44)
- `a2a3d053 docs(agents): state reviewer trial cost exactly`
