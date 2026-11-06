# Review loop: two cycles, fix checks, severity labels, auto-loop

- Status (2026-11-06): partly current. `exact_review/exact_references/loop.md` still has up to two cycles, up to 3 fix checks per cycle, and "major" meaning a `high` or `medium` bug. Later edits: fix checks start with `model: sonnet` (effort xhigh), state is kept in the `agt review` store, and the second cycle is skipped when the first review found no surviving `high` major finding. The small+big reviewer pair was dropped by `71ee6bb1`. The risky-only auto-loop and `--no-loop` flag are gone (`--no-loop` and `--loop` are not found in `home/dot_config/exact_agents`).
- Topic: Review
- Related: [review misses](2026-10-13-review-misses-deep-review.md), [review comments on own MRs](2026-10-15-review-comments-own-mrs.md), [light vs normal reviewer](2026-10-14-light-vs-normal-reviewer.md), [not adopted](not-adopted.md), [reworded review rule](../ab-tests/2026-10-28-reworded-review-rule.md)

## Change
After mining 84 past sessions with independent reviewers, the loop became up to two cycles. Each cycle is one full review by a fresh small+big reviewer pair, then up to 3 fix checks by the same reviewers (given all findings and the fix delta). The inner loop stops when a fix check finds no new high/medium bug; low bugs and nits never start another pass. The second cycle uses a fresh blind pair; after that, stop and ask. Bugs carry `high`/`medium`/`low`. Risky changes loop automatically, `--no-loop` turns it off, `--loop` forces it. dotfiles-sync gained an apply step and `.gitignore` ignores `__pycache__`.

## History
- 2026-10-13 — Session f9eb94ba (13:45Z to 15:25Z). The user: "How many review rounds does it take from blind reviews before all issues are goung and fixed? can we automate to this number?", then asked whether the same reviewers can re-review cheaper, whether studies exist, whether reviewers should classify findings, and "will using the same reviewer cause issues? would it be better to have the new reviewers only look at the most recent changes". The user then wrote the flow: "OK so we change to 1. some session sends full reviewers `<little-a>` and `<big-a>` ... 4. hands back to `<little-a>` and `<big-a>` for re review", asked "should we have a fer rounds of 3-5 if 5 keeps having issues?" (not done: cap stayed 2), "is this the default? can/should we remove --loop?" and "hide pycacvhe".
- 2026-10-13 — `ea18c600 dx(review): loop in two cycles with fix checks` (11:08 local). `5ff57cb2` ("Update ...", 11:08) was a stray chezmoi auto-commit that picked up 20 other files 4 seconds later (per the session notes); auto-commit was later removed by `3f7ca652 dx(chezmoi): stop auto commit and push` (16:49).
- 2026-10-13 — `79352b6e dx(review): loop automatic reviews of risky changes` (11:19), `e6a8c2bf dx(dotfiles-sync): apply targets after push` (11:20), `9238f5d3 build: ignore python bytecode caches` (11:22).
- 2026-10-13 — Session 8c70841e: "loop should be default, it will only re-run if actually big issues are found on first review right?" and "--fix should imply --loop". `71ee6bb1 dx(review): use one reviewer and loop every fix` (16:47) dropped the pair, made every fix loop, and removed `--no-loop`. `7e438c9f fix(review): keep ship merge flow and gate step 7 on the loop` (17:00).
- 2026-10-14 — `3c21bbe7 dx(review): review only at task end points` (16:43) limited when a review runs (when-to-run.md).
- 2026-10-14 to 2026-11-02 — Loop file edits (from `git log --follow`): `027f85c9`, `23c9c88c`, `3b5c701a` (state moved to the agent-review store), `6b54d1bf`, `3c39ee31`, `42af36ab`, `8369aed9`, `23662f0c dx(review): use sonnet for low-risk and fix checks` (10-20), `f0943031 dx(review): test with a tester before review`, `206ba7f7 dx(review): review testing-stage fixes before review` (10-21), `3a77d9ec`, `a88c1733`, `8a029ed0`, `569767d2`.
- 2026-11-06 — Status checked in loop.md as in the Status line.

## Results
The internal data below was the main basis. The session said the counts are model-scored and "approximate and likely high".

- 84 sessions with independent reviewers; 71 changes scored by 3 analysis agents.
- Round 1: 55/71 found something real (78%), 35 a bug (51%). Round 2: 23/36 (70%), 15 bugs. Round 3: 4/7. Round 4: 3/4. Round 5: 1/1. Only 19 of 71 ended on a clean round.
- The deep/Opus reviewer found a bug the plain one missed in at least 6 rounds.
- An earlier audit showed independent reviewers missed 72 of 394 issues (18%), and 40 of 114 misses were not visible in the diff.

The new loop was dogfooded on its own change: 11 issues, then 3 medium + 7 low. The session note: "None of these studies compares re-review by the same reviewer against a fresh one." No later measurement of the loop itself was found. What changed later is design, not outcome data: the pair was replaced by one reviewer, fix checks moved to Sonnet, and the loop is skipped until task end points.

## Sources
- Internal data (the main basis): see Results.
- [Anchoring Bias in LLM-as-a-Judge](https://arxiv.org/pdf/2608.25869) — prior scores weaken the next judgment. Snippet only.
- [Pride and Prejudice (ACL 2024)](https://aclanthology.org/2024.acl-long.826.pdf) — models favor their own output. Snippet only.
- [AgentPatterns, self-review modernization failure](https://agentpatterns.ai/patterns/anti-patterns/self-review-modernization-failure/) — the producing model missed 31.7% of behavior changes. Marked "unverified: secondhand".
- [Should we be going MAD? (ICML 2024)](https://proceedings.mlr.press/v235/smit24a.html) — debate doesn't reliably beat voting. Snippet only.
- [Controlled debate study](https://arxiv.org/pdf/2511.07784) — same claim. Snippet only.
- Session note: "None of these studies compares re-review by the same reviewer against a fresh one."

## Evidence
2 WebSearch calls, all five URLs from result snippets, no fetches. The design came mostly from the local data and the user's own proposed flow ("OK so we change to ..."). The loop was dogfooded on its own change (11 issues, then 3 medium + 7 low). Session f9eb94ba (2026-10-13).
