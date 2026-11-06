# Review experiment: single Opus xhigh vs xhigh plus Sonnet vs xhigh plus Opus low

- Date: 2026-10-13 (15:40-18:20 UTC; test about 16:10-16:25)  Sessions: 1602cbf2 (web-player)  Raw data: `~/.cache/agents/scratch/review-experiment/` is deleted (`test -e` fails). No run transcripts found under that name.
- Related: [Review misses and the deep review](../changes/2026-10-13-review-misses-deep-review.md), [Review loop](../changes/2026-10-13-review-loop.md), [Deep vs normal reviewer](2026-10-08-deep-vs-normal-reviewer.md), [Reviewer model A/B](2026-10-14-reviewer-model-opus-vs-sonnet.md)

## Question
Why did reviews miss 5 issues that a human reviewer ("DJ") found on MR 3 in claude-marketplace, and does a stronger or paired reviewer find them?

Cause found before the test (session, 15:54 UTC): the earlier review was set up badly, not run on a weak model. Its brief told the reviewer the hooks were "copied unchanged from a personal plugin already in use" and to focus on install and README issues. The deeper `deep-review` was skipped although the rules required it for this change (persistence, concurrency, trust boundaries, more than about 400 lines of logic). Only one Sonnet medium reviewer ran, and neither reviewer ran the code. The DJ review bot (https://gitlab.com/jwpconnatix/groups/aipoc/review-bot, read in the session) runs Opus 5.5 at xhigh on the diff only, with a fixed brief that never shows the author's reasons.

## Setup
Original MR code, a fixed new brief, 6 independent reviews: Opus xhigh x2, Sonnet medium x2, Opus low x2. Scored on 5 known findings: names, `##` split, resend, unordered writes, scanning untrusted results.

## Results
- Opus xhigh #1: 3/5 (11.6 min, 199k tokens), found findings 1, 2, 3, each with a failing test and evidence from the Claude Code binary; plus a restore-notice bug and a tool-search question.
- Opus xhigh #2: 3/5 (the same 3), plus an empty-text bug and a tool-search question.
- Sonnet medium #1: 2/5 (47 s, 31k tokens). Sonnet medium #2: 2/5 (53 s, 27k, 1 false positive).
- Opus low #1: 0/5 (38 s, 22k; spotted finding 1 but held it back). Opus low #2: 1/5 (30 s, 20k).
- Combined: xhigh alone 3/5, plus Sonnet 3/5, plus Opus low 3/5.
- Nobody caught findings 4 and 5 (performance and resource issues). The brief never asked about them; DJ's prompt lists `performance` and `resource-management`.
- xhigh also found 2 extra real bugs in code the pushed fixes did not touch (restore-notice, empty-text), unverified at the time.
- Cost about 7x the tokens and 13x the time of Sonnet.
- Assistant's reading: effort mattered more than model; Opus at low did worse than Sonnet at medium.

## Validity
The assistant: "one change with 2 runs per setup, treat as a strong hint, not proof". It offered a rerun on 2-3 more past MRs, not done. Web sources from this session are in the linked change doc.

## Decision
Option 1 applied: Opus xhigh alone for logic changes (drop the Sonnet pairing) plus a cost-and-resources check in the reviewer steps, and a fixed reviewer brief with no author framing.

## History
- 2026-10-13 — Experiment run in 1602cbf2.
- 2026-10-13 — `368b535a dx(review): fix reviewer briefs and add review checks` (body: "Use a fixed reviewer brief with no author framing, run one deep-review at xhigh for every logic change, and add checks for host contracts, cost, error handling, untrusted data, and a pre-flag test."): added "Check cost and resources" to `reviewer-steps.md`.
- 2026-10-13 — `79eb7192 dx(review): always delegate to deep-review`.
- 2026-10-13 — `71ee6bb1 dx(review): use one reviewer and loop every fix`: merged deep-review into a single `reviewer`.
- 2026-10-14 — The reviewer A/B ([link](2026-10-14-reviewer-model-opus-vs-sonnet.md)) kept Opus xhigh as the only reviewer, confirming the decision on real bugs.
- Today: `reviewer-steps.md` still has "**Check cost and resources.** On paths that run per call, event, request, or item, look for work that grows with input or history." (unchanged since `368b535a`). The reviewer is Opus xhigh.
