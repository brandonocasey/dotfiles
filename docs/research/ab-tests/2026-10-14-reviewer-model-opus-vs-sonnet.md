# Reviewer model A/B: Opus xhigh vs Sonnet xhigh, with Sonnet max and Opus high

- Date: 2026-10-14  Sessions: bc200b0a (sub-agents of that session built the cases)  Raw data: `~/.cache/agents/scratch/review-ab/` is deleted. 39 `review-ab` run transcript dirs survive as Claude project data. The real-bug keys survive at `~/.local/state/agents/answer-keys/review-inline-ab4/keys-real/r01.json` to `r25.json` (`test -e` ok; rebuilt later from the transcript for the inline-vs-sub-agent test).
- Related: [Light vs normal reviewer: tier added, then removed](../changes/2026-10-14-light-vs-normal-reviewer.md), [Main session reads nothing for review; read ranges](../changes/2026-10-14-review-read-ranges.md), [Review experiment: Opus pairs](2026-10-13-review-experiment-opus-pairs.md), [Deep vs normal reviewer](2026-10-08-deep-vs-normal-reviewer.md), [Effort trials](2026-11-02-effort-trials.md), [Inline vs sub-agent review](2026-10-28-inline-vs-subagent-review.md), [Agent starting-context audit](2026-10-13-agent-starting-context.md)

## Question
Can a cheaper reviewer replace Opus xhigh for normal changes?

## Setup
Reviewer role runs, graded by a blind Opus grader.
- Pilot: 1 diff with 4 known findings, 3 arms.
- Planted: 10 real commits from the user's repos (8 with 2 planted bugs each, 2 clean controls) plus 1 more diff, 5 rounds.
- Real: 25 bug-introducing commits found by SZZ from 1,158 fix-message commits (62 read, 25 accepted), with the later fix as the answer key, 1 run per case.
- Opus high was added later on the same 25 real cases.

## Results
- Pilot (4 known findings): Opus xhigh 4/4, $0.82, 2.8 min. Sonnet xhigh 3/4, $0.40, 1.7 min. Sonnet max 4/4, $1.86, 11.1 min (57 turns; wrote 8 empty files into the results dir).
- Planted, first 44 runs (11 diffs x 2): Opus 31/40 ($0.94, 2.9 min). Sonnet 32/40 ($0.49, 2.8 min). Only Opus caught a rule-text contradiction.
- Planted over 5 rounds: Opus 61/68 (89.7%), $0.97 per review. Sonnet 63/70 (90.0%), $0.46. Wrong findings: 0 vs 1.
- Real bugs (25 cases, 27 bugs):
  - Opus xhigh 24.5/27 (91%), $1.14 per review, $1.16 per bug.
  - Sonnet xhigh 20/27 (74%), $0.61 per review, $0.76 per bug, 1 wrong finding. Opus caught 4 bugs Sonnet missed; Sonnet caught 0 that Opus missed.
  - Opus high 21.5/27 (80%), $0.55 per review, $0.64 per bug, 1 wrong finding. It missed 3 that xhigh caught and caught none xhigh missed.
- Sonnet by diff size: up to 100 lines 8/9, 101-200 lines 7/8, over 200 lines 5/10. Opus: 9/9, 8/8, 7.5/10.
- Effort reached the model: output tokens 9.3k at high vs 21.2k at xhigh; all runs reported claude-opus-5-5.
- Cost: the test itself about $121 plus the Opus-high run. The session notes put the whole study at about $152 ($31 + $121 + the Opus-high run).

Sub-probes in the same session:
- ToolSearch vs connectors off for reviewer runs (2 runs per setup). Connectors off, no ToolSearch: 8,349 tokens per request ($0.067 cold, $0.021 warm). Connectors off plus ToolSearch: 8,230. ToolSearch plus context-lean with 10 connectors: 11,401 ($0.091 cold, $0.047 warm). Conclusion: keep connectors off for reviewers (about 27% smaller per request). No specific commit found.
- First-request context of every role through a logging proxy: main about 4,800 tokens, general-purpose about 4,670, cheap about 3,330, worker about 3,300, reviewer about 2,900, consult about 2,860, explorer about 2,740, tester about 2,320-2,360. The rules audit then found about 370 tokens per turn (5% of 7,400) to trim; 22 trims applied.
- Haiku helper for review setup: finished in 13 s for about 11k tokens.

## Validity
- Planted bugs were written by Opus. The planted-bug test tied and hid the real-bug gap.
- The real-bug test ran each case once.
- In 3 cases reviewers looked up the real upstream fix online (2 of them only Opus), so it was not fully blind.
- Two planted bugs were not bugs. One Opus run's review text was lost.
- Side effects: Opus added a test key to the real ssh-agent, Sonnet ran `ssh-keygen -h`, two parallel reviewers shared a scratch dir with a broad `pkill`.
- Opus-high cost is slightly understated (connectors were turned off for that run).
- The assistant said further Sonnet prompting (a do-not-dismiss rule) would recover about half of Sonnet's misses at best (20 to about 22/27). Sonnet medium effort was never tested. The user dropped Sonnet max after the pilot.
- Public benchmarks used as background are listed in [the light vs normal reviewer doc](../changes/2026-10-14-light-vs-normal-reviewer.md).

## Decision
Opus xhigh stays the only reviewer. The light-reviewer (Sonnet) tier added the same day was removed; the user said "alright let's remove the light reviewer role and sonnet as a reviewer". "Opus high is not worth the savings." The Codex reviewer default was set to gpt-6.1-sol xhigh before the test.

## History
- 2026-10-14 — Test run in bc200b0a.
- 2026-10-14 — `13c6a0e2 dx(review): add light-reviewer tier`: Sonnet medium light tier plus `--light`/`--normal` flags, added before the real-bug result.
- 2026-10-14 — `35fb091e dx(review): review every change with opus only` (body: "A real-bug A/B test caught 91% of bugs with Opus xhigh, 80% with Opus high, and 74% with Sonnet xhigh, so the light Sonnet tier is removed."): removed the light tier, 23 minutes after it was added.
- 2026-10-14 — `57bf3f9a dx(codex): prune removed agent roles on apply`: made chezmoi prune the removed Codex role file.
- 2026-10-14 — `3b98281a dx(codex): align subagent model tiers`: Codex reviewer moved from gpt-6.1-sol to gpt-6-astra (still xhigh).
- 2026-10-14 — Sub-probe commits: `345ba6eb dx(agents): compact rules and skill descriptions` (likely the 22 trims; the commit has no body) and `027f85c9 dx(review): hand review setup to a haiku helper`.
- 2026-10-20 to 2026-10-30 — Sonnet returned for low-risk and fix checks and Haiku for low-tier review (`23662f0c dx(review): use sonnet for low-risk and fix checks`, `e3ee004f dx(skills): cheaper review modes for small changes`, `10da7d14 dx(skills): review low-tier changes with haiku`, `212863cd dx(skills): drop inline review mode, send low tier to haiku`, `fd673112 dx(skills): review medium changes with opus, keep sonnet for fix checks`). The main `reviewer` stayed Opus xhigh.
- 2026-11-02 — `8a029ed0 dx(agents): lower opus reviewer to high effort` (body: "Trial: high found 6 of 11 high/medium bugs against 5 of 10 at xhigh, at half the cost and time.").
- 2026-11-02 — `569767d2 revert(agents): put opus reviewer back at xhigh` (body: "A larger trial on 27 paired changes found 20 of 31 known high/medium bugs at xhigh against 17 at high, so high likely misses about 1 in 10 serious bugs."). Also reverted `d6823e44 dx(agents): keep non-opus reviewers at xhigh`. See [Effort trials](2026-11-02-effort-trials.md).
- Today: `reviewer.md.tmpl` has `model: claude-opus-5-5`, `effort: xhigh`. The Codex reviewer is `gpt-6-astra` at xhigh.
