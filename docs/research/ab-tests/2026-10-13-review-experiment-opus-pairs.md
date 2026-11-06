# Review experiment: single Opus xhigh vs xhigh plus Sonnet vs xhigh plus Opus low

- Date: 2026-10-13  Sessions: 1602cbf2  Raw data: deleted (`~/.cache/agents/scratch/review-experiment/` removed; no run transcripts found under that name)

## Question
Opus xhigh alone vs Opus xhigh plus Sonnet medium vs Opus xhigh plus Opus low, on how many of 5 known findings a review of one work-repo MR catches.

## Setup
Original MR code, a fixed new brief with no author framing, 6 independent reviews: Opus xhigh x2, Sonnet medium x2, Opus low x2. Scored against 5 known findings: names, `##` split, resend, unordered writes, scanning untrusted results.

## Results
| Reviewer | Findings | Time | Tokens | Notes |
|---|---|---|---|---|
| Opus xhigh #1 | 3/5 (1, 2, 3) | 11.6 min | 199k | each with a failing test; plus a restore-notice bug and a tool-search question |
| Opus xhigh #2 | 3/5 (same 3) | n/a | n/a | plus an empty-text bug and a tool-search question |
| Sonnet medium #1 | 2/5 | 47 s | 31k | |
| Sonnet medium #2 | 2/5 | 53 s | 27k | 1 false positive |
| Opus low #1 | 0/5 | 38 s | 22k | spotted finding 1 but held it back |
| Opus low #2 | 1/5 | 30 s | 20k | |

- Combined: xhigh alone 3/5, plus Sonnet 3/5, plus Opus low 3/5.
- Findings 4 and 5 (performance and resource issues) were caught by none of the 6 reviews; the brief did not ask about them.
- xhigh also found 2 extra bugs (restore-notice, empty-text) in code the pushed fixes did not touch; unverified at the time.
- Opus xhigh cost about 7x the tokens and 13x the time of Sonnet medium.

## Validity
- One change, 2 runs per setup.
- No rerun on other MRs.
- Findings 4 and 5 were outside the brief, so the 3/5 ceiling applies to every arm.

## Decision
Opus xhigh alone for logic changes (Sonnet pairing dropped), a cost-and-resources check added to the reviewer steps, and a fixed reviewer brief with no author framing.

## Commits
- `368b535a dx(review): fix reviewer briefs and add review checks`
- `79eb7192 dx(review): always delegate to deep-review`
- `71ee6bb1 dx(review): use one reviewer and loop every fix`
