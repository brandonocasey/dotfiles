# Light vs normal reviewer: tier added, then removed

- Status (2026-11-06): replaced. No `light-reviewer` role exists (`home/dot_config/exact_agents/exact_agents/` holds cheap, consult, explorer, reviewer, tester, worker). The `reviewer` role is `model: claude-opus-5-5`, `effort: xhigh`. Review tiers today: low-tier changes go to a Haiku reviewer at xhigh, medium and up to the Opus xhigh `reviewer`; Sonnet xhigh is kept for fresh fix checks (`exact_review/SKILL.md`, `setup.md` "review mode").
- Topic: Review
- Related: [reviewer model A/B](../ab-tests/2026-10-14-reviewer-model-opus-vs-sonnet.md), [Haiku/Sonnet review replays](../ab-tests/2026-10-30-review-replays-vs-opus.md), [Haiku delegation probes](../ab-tests/2026-10-30-haiku-delegation-probes.md), [Nov 2 effort trials](../ab-tests/2026-11-02-effort-trials.md), [deep vs normal reviewer](../ab-tests/2026-10-08-deep-vs-normal-reviewer.md), [review misses](2026-10-13-review-misses-deep-review.md), [review loop](2026-10-13-review-loop.md), [not adopted](not-adopted.md)

## Change
A `light-reviewer` (Sonnet 5.5 medium; Codex gpt-6.1-sol low) was added for prose, cosmetic and small diffs, with `--light`/`--normal` flags, and the Codex `reviewer` was set to gpt-6.1-sol xhigh. After a local A/B the user said "alright let's remove the light reviewer role and sonnet as a reviewer in my skill". Every change was reviewed by the Opus xhigh `reviewer`. Cheaper tiers came back later through Haiku and Sonnet modes, driven by new replays.

## History
- 2026-10-14 — Session bc200b0a. The user: "I want to bring back the cheap reviewer for simple changes or even no reviewer", then "actaully we should always do a review, just either light or normal", "use gpt-6.1-sol xhigh", and "should we do reviews with sonnet xhigh? can we do an abtest against sonnet xhigh and opus xhigh. I want cost factored in. i'm even willing to consider sonnet max". The A/B ran with a pilot, planted-bug rounds and 25 real bugs; later "can we test against opus high? don't re-run opus xhigh". The user also stopped an unrequested gpt-6.1-sol review run ("no don't do a gpt-6.1-sol review, just set the default reviewer to that").
- 2026-10-14 — `13c6a0e2 dx(review): add light-reviewer tier` (14:15 local). Added the Claude and Codex `light-reviewer` roles, `--light`/`--normal`, and a rewrite of when-to-run.md.
- 2026-10-14 — The user asked "would it be reasonable to have a light reviewer that uses sonnet xhigh for easier to review changes? what should the threshold be", then at about 18:23Z decided: "alright let's remove the light reviewer role and sonnet as a reviewer in my skill".
- 2026-10-14 — `35fb091e dx(review): review every change with opus only` (14:38, 23 minutes after the add). Body: "A real-bug A/B test caught 91% of bugs with Opus xhigh, 80% with Opus high, and 74% with Sonnet xhigh, so the light Sonnet tier is removed." Deleted both light-reviewer files and the tier text.
- 2026-10-14 — `57bf3f9a dx(codex): prune removed agent roles on apply` (14:38). Moved Codex agent files into an `exact_` directory so removed roles are pruned on apply (the user: "we should be syncing codex too").
- 2026-10-20 — `23662f0c dx(review): use sonnet for low-risk and fix checks` (15:38). Sonnet came back for low-risk reviews and fix checks. No deciding session found (searched transcripts overlapping the commit time).
- 2026-10-30 — Session 8bcc0704 ("we need to cut down on review costs without losing quality. maybe more sonnet xhoght reviews and more inline reviews for simple changes", then "do all recommended"): `e3ee004f dx(skills): cheaper review modes for small changes` (00:29 local).
- 2026-10-30 — Session 80b76ea2 (continuing "Explore Haiku cost-saving task delegation", replays against stored reviews; the user asked "sonnet should have used xhigh to review.."): `10da7d14 dx(skills): review low-tier changes with haiku` (13:43); `212863cd dx(skills): drop inline review mode, send low tier to haiku` (14:26); `fd673112 dx(skills): review medium changes with opus, keep sonnet for fix checks` (14:38). The user's last questions were "how did sonnet fair vs opus for medium?" and "is sonnet even worth using at all then?".
- 2026-11-02 — `8a029ed0 dx(agents): lower opus reviewer to high effort` (09:29 local), `d6823e44 dx(agents): keep non-opus reviewers at xhigh` (09:35), then `569767d2 revert(agents): put opus reviewer back at xhigh` (14:31). The revert body: "Reverts 8a029ed and d6823e4. A larger trial on 27 paired changes found 20 of 31 known high/medium bugs at xhigh against 17 at high, so high likely misses about 1 in 10 serious bugs." No session found; the trials are in the [effort trials doc](../ab-tests/2026-11-02-effort-trials.md).
- 2026-11-06 — Status checked: reviewer is Opus xhigh; no light tier.

## Results
Measured, from [the reviewer A/B](../ab-tests/2026-10-14-reviewer-model-opus-vs-sonnet.md):
- Planted bugs (written by Opus; 2 were not real bugs): Opus 61/68 (89.7%) at $0.97 per review; Sonnet 63/70 (90.0%) at $0.46.
- Real bugs mined from the user's repo history (25 cases, 27 bugs): Opus xhigh 24.5/27 (91%) at $1.14; Opus high 21.5/27 (80%) at $0.55; Sonnet xhigh 20/27 (74%) at $0.61. Opus caught 4 bugs Sonnet missed; Sonnet caught none Opus missed.
- Sonnet by diff size: up to 100 lines 8/9, 101-200 lines 7/8, over 200 lines 5/10, against Opus 9/9, 8/8, 7.5/10.
- Sonnet medium effort was never tested.

Later problems: the tier was removed 23 minutes after it was added, and Sonnet and Haiku came back within 6 days after the replays in the [10-30 doc](../ab-tests/2026-10-30-review-replays-vs-opus.md) (Haiku found 13 of 86 Opus-labelled findings against 8 for Sonnet medium in replay 1, with labels that are circular). The Opus high setting was tried on 2026-11-02 and reverted the same day after the 27-change trial showed 17 against 20 of 31 bugs.

## Sources
The decision rests on the local A/B; web items were background:
- Local A/B 1, planted bugs: Opus 61/68 (89.7%), Sonnet 63/70 (90.0%), $0.97 vs $0.46 per review. Planted bugs were written by Opus; 2 were not real bugs.
- Local A/B 2, real bugs mined from the user's repo history: Opus xhigh 24.5/27 (91%) at $1.14, Opus high 21.5/27 (80%) at $0.55, Sonnet xhigh 20/27 (74%) at $0.61.
- [CodeRabbit, Sonnet 5.5 vs Opus 5.5](https://www.coderabbit.ai/blog/sonnet-5-5-model-review) — Opus 10/13 issues vs Sonnet 8/13. The session said "only 13 cases, table partly garbled".
- [Vellum, Sonnet 5.5 benchmarks](https://www.vellum.ai/blog/claude-sonnet-5-5-benchmarks-explained) — Sonnet 55.5% vs Opus 57.8% on CursorBench; not about review.
- [Qodo, Which LLM should review your code?](https://www.qodo.ai/blog/which-llm-should-review-your-code/) — benchmark 1.0, 100 PRs, 580 defects.
- [Martian Code Review Bench](https://codereview.withmartian.com/) — public review benchmark.
- [GitHub ReviewBench](https://github.blog/ai-and-ml/github-copilot/reviewbench-an-open-benchmark-for-ai-code-review/) — open review benchmark.
- ["Bigger Isn't Always Better"](https://arxiv.org/html/2606.15689v1) — planted bugs overstate reviewer recall; Haiku 29% and Sonnet 4.6 25% on real bugs. Used as a caution.
- [Medium comparison of 2026 public AI code review benchmarks](https://medium.com/@codzee.io/we-compared-the-public-ai-code-review-benchmarks-from-2026-methodology-datasets-metrics-and-269dd35637a6) — methodology comparison.

## Evidence
All web items are WebSearch snippets used as background. The session's own conclusion: public benchmarks are vendor-run, AI-graded or planted-bug based; none uses the user's prompt or xhigh effort. Session bc200b0a (2026-10-14). Sonnet medium effort was never tested.
