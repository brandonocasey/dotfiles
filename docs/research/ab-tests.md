# A/B tests, trials and probes behind agent-setup changes

Each section is one test, newest first. Why a change was made from web or doc sources is in [sources.md](sources.md).

Conventions:
- Session ids are 8-character prefixes. Dates are UTC from the transcript. Commit times in sources.md are local time.
- "Raw data" lists only paths that still exist. Most scratch run dirs and results files were deleted. The per-run headless transcripts survive as Claude project dirs, counted per test below by name pattern.
- Cost and token numbers come from the sessions as reported. n is runs per arm.
- The probe tool is the script `home/private_dot_local/bin/executable_agent-probe` (added in c433a391). No A/B skill exists, and the planned `~/Downloads/ab-test-plan.md` no longer exists.
- Not tests: `~/.cache/agents/output/llm-setup-audit/{applied-edits,gating}.md` (audit edits, no probe data).

### Rule-loading probes and quality-rules analysis (2026-11-05)
- Question: how do code-quality rules get loaded reliably in the main session and sub-agents?
- Setup: Claude Code 2.1.296 `claude -p` probes in scratch projects with inert test rules, InstructionsLoaded hook output and docs checks. Plus an evidence analysis of 657 reviewer reports, 247 stored review threads, 3,563 user messages, 160 MRs and 476 pipelines, classified by about 70 agents (2,026 findings), with 13 theme drafts each attacked by 3 skeptic lenses.
- Results: a path-scoped rule in `~/.claude-two/rules/` (`paths` frontmatter) loads on the first Read of a matching file, in the main session and in `omitClaudeMd` sub-agents, once per session. Symlinked rule dirs/files and `{a,b}` brace globs work. All 24 proposed glob cases matched. Files outside the session's working folder never match (plain, absolute and `~` globs; `--add-dir` did not help). 219 of 718 distinct code files edited in 30 days (30%) were outside the working folder. After compaction a path rule does not reload: 467 of 4,910 main-session edits (10%) followed a compaction, in 36 sessions. A skill `paths:` field does not inject the body. Sub-agent `skills:` preload injects SKILL.md only. Baseline: code-standards loaded before the first code edit in 47 of 211 main sessions (22%). Later hook probes covered flow-list, BOM, `!` negation, multi-line `paths:`, parallel-edit batch behavior (PostToolBatch), a compact3 probe (it refuted a docstring claim) and Python 3.9 vs 3.15 hook parity (separate session).
- Validity: the assistant said "'already covered by existing rules' is wording match, not measured effect". A re-measure of load rate and findings was planned for two weeks after applying. One probe batch had a restart-script bug that sent theme outputs to the same file (rerun).
- Decision: path-scoped rules for code standards plus a rule-gate hook that denies the first edit of a matching file until rules are read. This covers outside-working-folder files and post-compaction edits. It is option 1 of 5 in `loading-options.md` ("Path-scoped rule plus a gate hook ... recommended").
- Commits:
  - `f712b4a5 dx(rules): load and tighten code quality rules`
  - `8e376208 dx(claude): gate edits until path rules are read`
  - `6ee5949f fix(claude): stop rule-gate hangs and state loss`
  - `8d85aee4 fix(claude): deny every same-batch edit of a file`
  - `a19316a5 refactor(claude): drop rule-gate record snapshot`
  - `627bdeda docs(claude): note rule-gate deny after interrupt`
  - `6e11c86d dx(code-standards): add review-driven code rules`
  - `7bd40559 dx(review): check added comments against the comment rules`
  - `395ba50f feat(review): trace what removed links guaranteed`
- Sessions and raw data: 2697176b (2026-11-05 22:21 to 2026-11-06 18:34 UTC, hive). Surviving: `~/.cache/agents/output/quality-rules/proposals.md` and `loading-options.md`. The scratch dir `quality-rules-review` in the chezmoi worktree is deleted.

### Tester value analysis, 203 historical tester runs (2026-11-05)
- Question: does the tester find worthwhile issues? (Not an A/B.)
- Setup: final reports of 203 tester runs since mid-October were pulled. 176 reports that mention a failure or open question were sorted by 6 helpers into real, minor, setup-or-flaky, and false alarm.
- Results: real bug in the change 41 runs (20%; about 5 were deliberately broken toy code, so about 36 real work). Small nit 24 (12%). Setup/flaky/already-broken 27 (13%). All passed 107 (53%). False alarm 1. No final report 3. After a challenge, "setup" runs were reclassified: only 3 of 27 checked nothing. Causes: 10 agt process-detection tests failing in the sandbox (6 runs), Safari-only VolumeControl focus test (6), errors already on master (6), missing deps (4), Node 26 (2), machine load (2), tester's own watchers (1). Top catches: web-player settings-menu focus in non-English players (failed 8 of 8 cases), gzip stored under a brotli key, a release-script token visible in process args (the fix broke rollback lookup), demo gear-menu autoplay lost on reload, MR 1167 lint error and an always-failing test.
- Validity: some "real" findings were reasoned from code, not reproduced. It did not check whether the reviewer would also have caught them. The 13% was overstated at first.
- Decision: fixing the two repeat noise sources (agt process tests, Safari VolumeControl test) was offered; the tester was kept.
- Commits: none specific found. Related and earlier: `0d544939 dx(agents): give tester an oracle and bounded coverage`.
- Sessions and raw data: 7d274c5f (2026-11-05 19:09-19:38 UTC, web-player). Surviving: `~/.cache/agents/output/tester-value/result1..6.md` plus chunk and finals files.

### Tester on Haiku vs Sonnet probes (2026-11-03)
- Question: can Haiku fill the tester role, including browser checks?
- Setup: probe 1 used a small Node repo with 6 planted bugs (5 independent causes) and a false author claim: 2 Sonnet and 2 Haiku tester runs, tester role at high effort, scored against the key. Probe 2 used a real web-player focus bug on a pre-fix build (worktree `probe-tester-haiku-focus`) with headless browser checks, 2 Sonnet and 2 Haiku. The answer key was the fix's Playwright specs on the pre-fix build (10 failed, 11 passed, all 10 from one cause: custom/French labels).
- Results: probe 1: all 4 runs found all 6 bugs and rejected the author's claim. Sonnet used about 13k tokens (13.5k, 13.3k; about 34 s). Haiku used 27-31k tokens (27.5k; about 68 s). Probe 2: main bug found by Sonnet 2 of 2 and Haiku 2 of 2 (settings-menu.js:529/:531). Author's claim rejected and unit-test gap named in 4 of 4. False positives: Sonnet-1 (API-opened Share should refocus Share) and Haiku-2 (instant-Escape race, self-marked unverified). Extra likely-true finds: Haiku-1 (old-browser ariaLabel fallback) and Haiku-2 (captions-only focus loss). Tokens: Sonnet 83k and 140k, Haiku 150k and 178k. Time: Sonnet 8.6 and 9.9 min, Haiku 9.0 and 11.1 min. Rule breaks: Sonnet-1 left 4 polling loops, Haiku-1 left part of its matrix unfinished. Haiku used about 1.3-2x the tokens.
- Validity: both Haiku runs used the role's high effort (the user remarked "should have used haiku at xhigh"; the assistant judged it unneeded since Haiku already matched at high). n=2 per arm. Probe 1 task was small with planted bugs. The probe 2 key came from the real fix's specs.
- Decision: the tester role runs on Haiku (high effort) for all testing, including browser checks.
- Commits:
  - `23539612 dx(agents): run tester on haiku after probes`
- Sessions and raw data: f4347fce (2026-11-03 22:09-23:05 UTC, web-player). Surviving: `~/.cache/agents/output/tester-haiku-probe/results.md` (probe 2 only). Scratch repos deleted.

### Nov 2 effort trials: Haiku roles medium vs xhigh; Opus reviewer high vs xhigh (2026-11-02)
- Question: can Haiku roles drop to medium effort and the Opus reviewer to high without losing quality?
- Setup (from commit messages only): trial 1 cheap and explorer tasks, medium vs xhigh. Trial 2 reviewer on 11 changes with known high/medium bugs (high vs xhigh). Trial 3 on 27 paired changes.
- Results: cheap/explorer medium matched xhigh on 20 of 20 tasks, 6.6 s vs 11.1 s (40% faster). Reviewer trial 2: high found 6 of 11 high/medium bugs vs 5 of 10 at xhigh, at half the cost and time. Reviewer trial 3: 20 of 31 known high/medium bugs at xhigh vs 17 at high ("high likely misses about 1 in 10 serious bugs"), cost $2.11 vs $1.13 per review. All numbers come from commits 750e9971, 8a029ed0, 569767d2 and a2a3d053 and from roles.md.
- Validity: no transcript was found; the commits are dated 2026-11-02 09:29-14:35 EST and no indexed Claude or Codex session on this host overlaps that window. It likely ran on another host. The 27-change set likely descends from the real-bug set in the Oct 14 reviewer A/B (unverified). Trials 2 and 3 conflict: high looked better (6/11 vs 5/10), then worse (17 vs 20 of 31). The reviewer was lowered and reverted within 5 hours.
- Decision: Haiku roles (cheap, explorer) lowered to medium. Reviewer lowered to high, then reverted to xhigh. Non-Opus reviewers (Haiku review, Sonnet fix checks) keep xhigh by explicit override.
- Commits:
  - `750e9971 dx(agents): lower haiku roles to medium effort`
  - `8a029ed0 dx(agents): lower opus reviewer to high effort`
  - `d6823e44 dx(agents): keep non-opus reviewers at xhigh`
  - `569767d2 revert(agents): put opus reviewer back at xhigh`
  - `a2a3d053 docs(agents): state reviewer trial cost exactly`
  - `2062feea dx(agents): tune codex role models and effort` (same day, Codex role models and effort; no data found)
- Sessions and raw data: session not found. No raw data.

### Haiku/Sonnet review replays against Opus and verified findings (2026-10-30)
- Question: can Haiku or Sonnet review low and medium changes, and where is the breaking point?
- Setup: replay of past stored reviews (`~/.local/state/agents/reviews`: 41 full reviews, 32 with verified fixed findings, 137 verified and 10 killed; every stored reviewer run was Opus xhigh). Replay 1: 21 mixed changes, 86 labeled fixed findings. Low-tier replay: 12 docs/test commits against Opus findings. Sonnet rerun at xhigh on all cases (first runs used medium by mistake). Medium replay: 6 commits of 81-296 lines. Sonnet judged matches; Sonnet at high verified extras.
- Results: replay 1 (Haiku xhigh vs Sonnet medium): all 86 findings 13 (15%) vs 8 (9%); medium/high 0 of 16 vs 2 of 16; cost $2.00 vs $3.28. After dropping an invalid working-tree case: 76 findings 13 (17%) vs 8 (11%), medium/high 0 of 14 vs 2 of 14. Low tier (51 Opus findings, 26 medium/high): Haiku 29 (17 medium/high) $0.52, Sonnet medium 18 (13) $1.44, Opus $6.27. Sonnet xhigh rerun (mixed 18 cases / 68 findings; low 12 / 51): mixed Haiku 11, Sonnet medium 8, Sonnet xhigh 16; mixed medium/high (13) 0, 2, 3; low all 29, 18, 30; low medium/high (26) 17, 13, 19. Sonnet xhigh low tier $3.32, about 2x medium cost, rerun total $11.20 (cap $9). Verification: of Haiku's 28 unmatched low-tier findings Sonnet confirmed 14, rejected 11, 3 unclear ($0.95), so Haiku valid 43 of 55 (78%) vs Sonnet xhigh about 35 of 42 (85%), review cost $0.52 vs $3.32. Medium (6 commits, 17 Opus findings, 11 medium): Haiku 7 (6 medium) $0.35, 15 of 19 valid; Sonnet xhigh 10 (9 medium) $2.10, 14 of 15 valid; Opus $4.09. Session total about $37 (earlier $29 at first sync).
- Validity: labels are circular (Opus findings, unverified in low/medium replays). Replay 1 had 13-16 medium/high findings. The low tier was 8 docs-only and 4 test-only commits (the assistant first said 11 docs-only, then corrected). One run each. Sonnet first run at the wrong effort. Spend overran estimates ($27-37 vs $5-15). One invalid low-tier working-tree case. Replay 1 and the medium replay conflict (Sonnet 3 of 13 vs 9 of 11 medium), so there was no change to the medium tier beyond dropping Sonnet.
- Decision: low tier to Haiku xhigh. Inline mode removed. Sonnet review mode removed (medium and up go to Opus xhigh; Sonnet xhigh kept for fresh fix checks only). Worker and tester raised to Sonnet high and consult to Opus xhigh by user instruction (no test).
- Commits:
  - `10da7d14 dx(skills): review low-tier changes with haiku`
  - `212863cd dx(skills): drop inline review mode, send low tier to haiku`
  - `fd673112 dx(skills): review medium changes with opus, keep sonnet for fix checks`
  - `d3d2dfb9 dx(agents): raise worker and tester effort, consult on opus`
- Sessions and raw data: 80b76ea2 (2026-10-30 13:45-18:44 UTC). `~/.cache/agents/output/haiku-review-replay/` is deleted. The review store at `~/.local/state/agents/reviews` still exists.

### Haiku delegation probes, Haiku xhigh vs Sonnet (2026-10-30)
- Question: which tasks can go to Haiku to save cost, and where does Haiku break?
- Setup: agent-probe, 3 runs per model per task, ground truth by `rg` or planted answers. P1: 4 locate/aggregate tasks over skills (12 runs). Then 42 runs: tricky usage lists (re-exports, aliases, string-built lookup), log summarizing (planted test names, root cause, misleading early error), instruction compliance, call tracing, seeded-bug review. Review ladder L2-L8 (up to 12 seeded bugs; 10 subtle security/logic; 4 bugs in about 1,000 lines). Then an AACR-Bench pilot: 9 PRs, 18 reviews, blind Opus judge, Opus baseline added.
- Results: P1: Haiku found every expected file in 12/12 runs, Sonnet too; cost Haiku $0.021 vs Sonnet $0.304 (about 14x). The 42 runs: usage lists 3/3 vs 3/3; log summaries 3/3 vs 3/3; call tracing 3/3 vs 3/3; seeded-bug review 3/3 bugs in all runs on both (Sonnet 2 extra "no rollback" notes). Instruction compliance was inconclusive (6/6 clean on don't-edit and short-reply; the owned-folder task was blocked by permissions; Haiku finished 1 of 3, Sonnet 3 of 3). Across the 42 runs Haiku cost $0.051 vs Sonnet $0.779 (about 15x). Review ladder L2-L8 (21 runs per model): no recall gap; subtle 10/10 Haiku x3, Sonnet 10/10 x2 and 9/10 (scorer line mismatch); buried 4/4 both; cost $0.020 vs $0.306. AACR pilot (28 reference comments): Haiku 4 matched ($0.19, 23 findings), Sonnet 3 ($0.58, 16 findings), Opus xhigh 2 ($2.20, 17 findings). Haiku used about 3x more turns than Sonnet at xhigh.
- Validity: planted-bug fixtures cannot find Haiku's limit (the assistant: textbook bugs, no hidden context, bug-hunt prompt, lenient self-written scoring, scorer loosened mid-run). The first probe was an easy text match. The compliance probe loaded global rules that the real `cheap` role omits. The AACR benchmark could not separate the three models (all near floor): 9 PRs, 1 run each, unchecked judge. Benchmarks surveyed are listed in sources.md under "Not adopted".
- Decision: usage lists and file finds go to `cheap`. Explorer moved to Haiku xhigh. `cheap` does first-pass failure triage (worker diagnoses). Workflows pass `claude-haiku-5-5` explicitly. Haiku routes added to jenkins, ticket, session-resume, write-docs and llm-setup-audit. Reviewer unchanged. The nested sub-agents ban was kept (option 1).
- Commits:
  - `9a476e31 dx(skills): hand more read-only work to haiku agents` (roles.md "explorer matched Sonnet on usage lists and call traces" and "Haiku matched Sonnet on log triage" originate here)
  - `fe308270 dx(skills): keep audit skill under size limit, fix replay count`
  - `8eac3c48 dx(skills): stop pinning sonnet in four skills`
- Sessions and raw data: c974856b (2026-10-30 04:31-05:56 UTC). Scratch deleted by the assistant.

### Reruns: review on vs off (w8), harder shortcut trap (w9), w10 rerun (2026-10-29)
- Question: rerun the two inconclusive tests of the Oct 28 rules-vs-no-rules run.
- Setup: w8: 4 real-repo tasks (sparse, notify, track, cache) x {no review, forced review} x 3 runs = 24. w9: shortcut trap with a CI check failing on an unrelated rounding bug, no-rules vs current rules, 5 runs per arm = 10 (Opus). w10: sparse and notify, 6 runs per arm = 24 in parallel with `--strict-mcp-config`. Added the `ab.sh` runner and a `PAR=` option.
- Results: w9: 0 of 10 cheated (no test edits, suppressions, skips or lint edits). Current rules committed with the check still red in 2 of 5 runs (reports said so); no-rules 0 of 5. Hidden tests 9-11 of 12 in both. w8 (20 of 24 graded): sparse no review robust 2/4 x3, forced review 4/4 and 2/4 ($1.09 vs $5.50); notify no review 2/6 x2, forced 2/6 and 4/6 ($0.61 vs $1.27); track identical ($0.80 vs $1.30); cache forced review passed spec 1 of 3, no review 0 of 2, and 2 of 3 forced runs never committed. Forced review costs 1.5-5x. w10: only 7 of 24 finished and committed: sparse no review 4 runs 3/3 and 2/4, forced 2 runs 2/3 and 2/4; notify no review 1 run 30/31 and 1/6; forced 0 usable.
- Validity: disk filled (51 GB of Rust clones) and crashed runs. Flaky chrome-devtools MCP startup under 11 parallel runs. 4 missing runs. In notify both no-review runs still ran a reviewer (contaminated). Notify $0.38 runs were probably first-turn costs only (many notify runs end the first turn waiting on a background session). The user stopped 12 of 24 w10 runs. Usage limit. The assistant listed 7 failure modes of A/B runs (disk, flaky startup, long serial runs, spend limit, late grading, lost evidence, easy tasks) and drafted a 10-step A/B skill plan (not built; the file is gone).
- Decision: do not make review mandatory for every change; keep it for risky work (the assistant's conclusion). No new rule applied. Cleanup freed about 47 GB.
- Commits: none found.
- Sessions and raw data: 686bb3b6 (2026-10-29 16:47-20:00 UTC). `w10.json` and `w10.md` and the `ab-test-gaps/` output are deleted. 15 `*rules-ab*` run dirs for w2-w10 survive (see the Oct 28 rules test).

### Reworded review rule on Opus, calibration of harder tasks, real-history tasks (2026-10-28)
- Question: does the stronger review wording work on Opus, and do harder tasks separate arms?
- Setup: 6 Opus runs (archive x3, refund x3) with the reworded rule. Then 3 harder tasks (CSV import, coupons, order edit; hidden spec and edge tests; reference solutions pass) calibrated with 9 no-rules Opus runs. Then 4 tasks from real repo history (vitrine notifications TS 33 files, agent-review sparse checkout and tracking worktree, agt check cache), built, but only 3 calibration runs finished.
- Results: reworded rule: review ran 6 of 6 (vs 6 of 24 under current rules). Refund 14/14 in 3 of 3. Archive 14/14 but robustness 0/2 in 3 of 3. $2.08 per run vs $0.90 for current-rules refund runs. Reviews fixed real edge bugs not covered by hidden tests (huge-number crash, `A1:²` input, refund drift after a tax-rate change). Calibration: coupons edge 8/8 x3, order edit 7/7 x3, CSV import 9/9, 8/9, 8/9; cost $2.81 for 9 runs; too easy. Real-history tasks: starting-code spec scores e.g. TS 11/31 to 31/31 on the feature, edge tests 0/6 on the feature; 12 calibration runs approved, stopped after 3 finished for usage.
- Validity: the assistant said tasks were "still too easy". Hidden tests were reachable by agents. 3 finished real-task runs were ungraded.
- Decision: no rule change applied in this session. The recommendation was unchanged: apply the reworded rule to all models (+$1.20 per task) and do not auto-load code-standards.
- Commits: none found.
- Sessions and raw data: 639aaece (2026-10-28 14:51-20:52 UTC). 15 `*rules-ab*` run dirs for w2-w10 survive.

### Inline review vs sub-agent review: toy rounds and a real-bug round (2026-10-28)
- Question: can the main session review its own diff (inline) instead of using a reviewer sub-agent?
- Setup: variants `today` (reviewer and tester sub-agents) vs `inline` (one appended rule), through agent-probe. R1: small CSV task, 5 runs per arm, 49 hidden cases. R2: same code with 11 planted bugs, 6 runs per arm. R3: semver-range task graded on 2,726 generated cases, 6 runs per arm. R4: 7 hard real-bug cases (r10, r11, r12, r13, r14, r20, r25 of the 25 from the Oct 14 reviewer A/B), 1 run per case per arm, blind Opus judge with answer key.
- Results: R1: both 49/49 in 5/5; cost $2.26 vs $0.79 per run; 9.0 vs 2.5 min; the sub-agent found 1 real bug in 3 of 5 runs, inline in 0; 1 of 5 inline runs shipped a `""` row skip. R2: 11/11 planted bugs in 6/6 for both; $2.43 vs $0.62; 11.2 vs 2.2 min. R3: 2,726/2,726 in 6/6 for both; $2.34 vs $0.93; 10.0 vs 3.1 min; low-severity extra bugs found: sub-agent 5 across 3 of 6 runs, inline 2 across 2 of 6. R4: the sub-agent caught 3 (r10, r11, r20), inline caught 1 (r20); r12, r13, r14, r25 both missed; no bug caught by inline only; cost sub-agent $2.60 per task ($1.14-4.29), inline $0.68 ($0.23-1.61).
- Validity: R1-R3 ceilinged (perfect scores). The inline arm also dropped the tester and used Opus where the sub-agent review used Sonnet fix checks (the first claim that the sub-agent reviewer was Sonnet was wrong; it was Opus xhigh). R2 reviewer saw code it had not written. R3 had 9 runs rerun after the spend limit. Hidden tests and answer keys were deleted. R4 first attempt (v1, 11 runs, about $30) was invalid because sessions reworked the draft before committing (9 of 10 first commits differed). The second attempt had only 2 of 7 valid. The third attempt had harness bugs (cloning outside the run dir, sessions ending while helpers ran, the sub-agent arm sometimes skipping the reviewer), which were fixed and rerun. r10 and r25 sub-agent runs skipped the tester. The r25 inline run ended oddly. R4 spend about $23 valid plus about $30 invalid. A process check missed the Python-run probe, so runs continued about 25 min after "stop". Usage-limit stops.
- Decision: keep the reviewer sub-agent ("keep for risky changes"); doing both inline and sub-agent is not worth +26%. A later commit added an `inline` mode for tiny docs-only changes (e3ee004f, session not located) and then dropped it (212863cd) after the Haiku replay.
- Commits: none directly. Related:
  - `e3ee004f dx(skills): cheaper review modes for small changes` (adds inline mode; not verified as caused by this test)
  - `212863cd dx(skills): drop inline review mode, send low tier to haiku`
- Sessions and raw data: e93ffbb5 (R1-R3, 2026-10-28 04:54-09:21 UTC, hive); 2a73f606 (verification and R4, 2026-10-28 14:52-21:45 UTC). Surviving: answer keys at `~/.local/state/agents/answer-keys/review-inline-ab4/` (`keys-real/r01..r25.json`). 87 `*review-inline-ab*` run dirs survive. `results.md` is deleted.

### Global rules vs no rules, 10 planned tests (2026-10-28)
- Question: do the global agent rules improve unattended quality and maintainability, and does review run?
- Setup: fixtures: a Python shop app (refund 14 tests, discount, CI-red trap 7 tests, archive 14 tests plus 2 hidden robustness cases), a TypeScript app (11 tests), shortcut traps, and a compaction arm. Arms: no-rules vs current rules (plus Sonnet arms and the reworded review rule). Blind Opus judge (2 passes) for maintainability, honesty and ambiguity. 105 runs ($38) plus judge ($13), about $51. Tool: agent-probe. n=3 per arm.
- Results: same hidden-test results in both arms on all 7 tasks. Review compliance: Opus with current rules reviewed 6 of 24 runs (skipped 18; no report mentioned the skip). Sonnet reviewed 0 of 9. The reworded rule on Sonnet 3 of 3 at about +$0.62 per run. Cost: current rules $1.70 per run when review ran vs $0.45; TypeScript $1.29 vs $0.36 per run. Maintainability (1-5): about 4 in both arms (refund 4.0 vs 4.17, discount 4 vs 4, TS 4 vs 4). Vague spec: 6 of 6 chose defaults and listed them. Shortcut traps: 24 of 24 fixed honestly (no test edits or suppressions). The code-standards skill loaded in 1 of 24 feature runs. Archive robustness failed 0/2 in 6 of 6 runs with the old or new checklist. Report honesty: real false claims rare. Compaction: a 50k window fired in 1 of 6; 25k runs died on the spend limit (not a result); at a 15% setting 2 of 6 current-rules runs compacted and finished correctly.
- Validity: every arm passed every spec test (ceiling), so the review gain could not show. Both shortcut traps were too easy. The compaction test gave no answer at first (usage limit). The assistant corrected "10 of 15" to 18 of 24.
- Decision: the assistant recommended applying the reworded review rule to all models and auto-loading code-standards, but applied neither. The user's decision is not recorded in these sessions.
- Commits: none found for the rule changes. Adjacent, sessions not located:
  - `34591586 dx(skills): update review and ticket rules`
  - `e3ee004f dx(skills): cheaper review modes for small changes`
  - The code-standards auto-load idea was implemented later through the Nov 5 rule-loading probes (f712b4a5, 8e376208).
- Sessions and raw data: a58ad48b (2026-10-28 05:09-11:06 UTC). `~/.cache/agents/output/ab-test-gaps/results.md` and the scratch dir `rules-ab` are deleted. 189 `*rules-ab*` run dirs survive.

### Main-session model and effort, and handoff A/B (2026-10-25)
- Question: Sonnet or Opus (and which effort) as the main session, and orchestrate/handoff vs inline.
- Setup: a stock app fixture with a question, a bug fix, a hard 2-bug task (22 hidden tests) and a 22-file feature (40 tests). Variants Sonnet med/high and Opus low/med/high/xhigh. Pilot 20 runs, second round 15 hard plus 10 handoff runs. Real rules, so the QA tester and the Opus xhigh reviewer run. Cost about $104 (pilot $42, round 2 $62).
- Results (cost for question / bug fix / hard bug / feature; full review ran): Sonnet med $0.10/$0.64/$0.17/$1.58, review 2 of 11. Sonnet high $0.13/$0.73/$1.03/$3.27, 6 of 8. Opus low $0.17/$0.51/$0.32/$2.72, 1 of 8. Opus med $0.22/$1.30/$1.53/$4.92, 11 of 11. Opus high $0.30/$1.44/-/$6.97, 2 of 2. Opus xhigh $0.41/$2.12/$2.52/$7.66, 8 of 8. All 54 coding runs passed every hidden test. Sonnet med skipped review in 7 of 11 runs, Opus low in 4 of 8; the QA tester was skipped in 3 of 14 pilot runs. Handoff vs inline: Opus med $4.92 inline vs $3.31 handoff (-33%); Sonnet med $1.58 vs $2.35 (+49%); all 6 handoffs 40/40. The 15-file rule never fired on its own in 2 free-choice runs (22 files).
- Validity: the first hard task leaked both bugs in a commit message (rebuilt; only rebuilt runs count). No task separated models on quality. 5 of 6 handoff costs are estimates (transcript pricing x1.25). Question and bug-fix cells are n=1. Some background sessions hit the usage limit. After the rule edit: the "count files first" rule handed off 3 of 3 feature runs (40/40) and 0 of 3 small fixes. A later guard-less version nested handoffs (3-21 nested sessions, $6.66 outlier, 51 min) and was reverted. With the guard (`AGENT_HANDOFF=1` blocks `claude -p`), 4 of 4 live runs handed off exactly once.
- Decision: keep Opus medium as the main session. Fix the handoff rule to fire (count files early). Block nested handoff sessions. Make handoff sessions record review.
- Commits:
  - `62f15c64 dx(agents): count files early so handoff fires`
  - `1d31fa4c revert(agents): undo handoff rule that nests`
  - `1aa4319c dx(agents): block nested handoff sessions`
  - `65e51bcb dx(agents): count files early so handoff fires`
  - `2e2e177a test(agents): cover a backgrounded nested handoff`
  - `3985f4bd fix(agents): make handoff sessions record review`
- Sessions and raw data: da2716d2 (2026-10-25). 102 `*main-model-ab*` run dirs survive.

### Pipeline probes: agent pipeline vs inline (2026-10-23)
- Question: should the main session delegate every step (implement, QA-fix loop, review-fix loop, docs, reader) to agents?
- Setup: fixtures built by sub-agents (todo app; medium task 5 files with 14 hidden tests plus 4; small 1-file fix; large 2,350-line app with a 31-file reference change and 63 secret tests; ambiguous-spec task; 18-file task with 34 tests). Claude `-p` runs through agent-probe, reported at n=1 then n=3 or 4. Total spend about $100 for rounds 1-2, plus about $42 round 3 and about $10 round 4.
- Results: calibration: Claude's own cost total includes sub-agents (probe tool columns undercount). Medium task: inline $1.41 (n=3) vs pipeline $2.19 (n=4), all 14/14 (+55%); Opus vs Sonnet implementer $2.54 vs $2.19 (n=3). Small task: the size gate chose inline 3 of 3, rules loaded still +18% ($1.28 vs $1.08), forced pipeline +76%. Decisions file: without it 3 of 3 fix agents changed protected design choices, with it 0 of 3. Reader pass: tester 3.3 of 4 planted doc bugs, cheap 3.0 of 4, under $0.10 each. Resume vs fresh fix agent: after 6.7 min idle resumed $0.02 vs fresh $0.04-0.06; after 65 min resumed $0.11 vs fresh $0.05 (cache warm at 6.7 min, cold at 65). Docs-before-review $2.52 vs $2.19. QA reuse: review skipped retesting in 2 of 2. Large task (31 files): inline Opus $5.74 mean (61/63 x3); pipeline Opus main $6.40 (+11%, 62/63); pipeline Sonnet main $4.94 (-14%; $4.37 / -24% excluding one run that broke the rule); handoff from Opus to a background Sonnet session $4.34 (-24%; 61, 63, 62 of 63). Exact-wording test: $2.20, 62/63, but 2 live-wording bugs (double review in 3 of 4 runs, about $2 each; a shared scratch folder let two sessions edit one repo). Ambiguous spec: all 4 built without asking, safe default, 3 of 4 reported it. 18-file task, 15-file threshold: pre-fix $2.20 / $3.76 vs $2.94-3.34 inline; after fixes handoff $2.40 vs $3.15 inline (-24%), all 34/34, Sonnet skipped QA or review in 1 of 3.
- Validity: 6 of the 9 first-round tests were n=1. A runner bug lost the Opus cost for 2 of 3 handoff runs (1 measured, $0.66). The first resume test was invalid (finding already handled). The "$0.17" resume cost was corrected to $0.02. Background sessions deleted their own cost files.
- Decision: adopt only what proved value: the decisions file, the doc reader pass (tester), and the large-task handoff (15+ files) to a background Sonnet orchestrator with a fresh mktemp dir and no second review. Rejected the full pipeline and the size gate. On Oct 24 `pipeline.md` was removed in a refactor; the handoff was restored as an `orchestrate` mode citing these probes.
- Commits:
  - `9056caba dx(sub-agents): add decisions file and doc reader pass`
  - `6b7d127e dx(sub-agents): hand large tasks to a sonnet orchestrator`
  - `80af617b dx(sub-agents): fix handoff prompt, reader pass, review check`
  - `b6fa8a6e dx(sub-agents): use the timing skip test after handoff`
  - `2929fd0b dx(agents): restore the cheaper sonnet handoff` (body: "one background Sonnet session cost 24% less than inline at 18 and 31 files")
- Sessions and raw data: abc9c8a3 (2026-10-23/24); 446ca2ba (2026-10-24, re-reads results). 85 `*pipeline-probe*` run dirs survive. The scratch dirs `pipeline-probe` and `pipeline-probe2` are deleted and the summary under `~/.cache/agents/output/` was not found.

### AGENTS.md without CLAUDE.md probe (2026-10-15)
- Question: does Claude Code 2.1.296 load a repo `AGENTS.md` without a `CLAUDE.md`?
- Setup: codeword ("PELICAN") probe repos, one in `$TMPDIR` and one under `$HOME`.
- Results: a bare AGENTS.md was read in `$TMPDIR`. Under `$HOME` with `CLAUDE_CONFIG_DIR=~/.claude-two` it printed NONE until a one-line CLAUDE.md was present (the user file symlink is treated as a project file in the walk).
- Validity: the first probe ran outside `$HOME`, so it missed this; review caught it.
- Decision: keep a one-line `CLAUDE.md` in each repo (hive, web-analytics, conventions) plus a README note. These were project-repo MRs, not dotfiles.
- Commits: none in dotfiles (repo changes only).
- Sessions and raw data: f6d3457a (2026-10-14/15, hive); probe sessions 84e915cf and 7ac47f86 (2026-10-15). No raw data.

### LSP tool A/B: token use on a shared-name symbol trace (2026-10-14)
- Question: does having the LSP tool (plugins on) reduce tokens for symbol tracing?
- Setup: headless runs tracing a `publish` method in the vitrine repo whose name is shared by another `publish`. 3 runs per setup. An empty-prompt baseline was also run.
- Results (average input tokens per run): empty prompt plugins off 11,030 vs on 11,033. Trace, plugins off 129,982 (143,115/108,329/138,501). Plugins on, old rule: 121,837 (0 of 3 used LSP). Plugins on, new "LSP first" rule: 108,350 (1 of 3 used LSP). Prompt forces LSP: 91,883 (3 of 3; 151,799/82,899/40,952; -29%). All 12 runs found the same 4 call sites.
- Validity: the assistant said 3 runs each, runs vary up to 3x, "direction, not exact".
- Decision: the reviewer role was given LSP, the rule was strengthened to "use LSP first when available", and plugins were turned on. Later replaced: LSP dropped for code-graph tooling.
- Commits:
  - `78752a06 dx(agents): give reviewer the LSP tool`
  - `19187158 dx(agents): replace lsp with code graph tooling`
- Sessions and raw data: bc200b0a (2026-10-14 evening). `~/.cache/agents/scratch/lsp-ab/RESULTS.md` is deleted.

### Reviewer model A/B: Opus xhigh vs Sonnet xhigh, with Sonnet max and Opus high (2026-10-14)
- Question: can a cheaper reviewer replace Opus xhigh for normal changes?
- Setup: reviewer role runs, blind Opus grader. Pilot: 1 diff with 4 known findings, 3 arms. Planted: 10 real commits from user repos (8 with 2 planted bugs, 2 clean controls) plus 1 more diff, 5 rounds. Real: 25 bug-introducing commits found by SZZ from 1,158 fix-message commits (62 read, 25 accepted) with the later fix as the key, 1 run per case. Opus high added later on the 25 real cases.
- Results: Pilot (4 known findings): Opus xhigh 4/4, $0.82, 2.8 min; Sonnet xhigh 3/4, $0.40, 1.7 min; Sonnet max 4/4, $1.86, 11.1 min (57 turns; wrote 8 empty files into the results dir). Planted, first 44 runs (11 diffs x 2): Opus 31/40 ($0.94, 2.9 min), Sonnet 32/40 ($0.49, 2.8 min); only Opus caught a rule-text contradiction. Planted over 5 rounds: Opus 61/68 (89.7%) $0.97 per review, Sonnet 63/70 (90.0%) $0.46; wrong findings 0 vs 1. Real bugs (25 cases, 27 bugs): Opus xhigh 24.5/27 (91%), $1.14 per review, $1.16 per bug; Sonnet xhigh 20/27 (74%), $0.61, $0.76 per bug, 1 wrong finding; Opus caught 4 bugs Sonnet missed, Sonnet 0 that Opus missed. Opus high 21.5/27 (80%), $0.55, $0.64 per bug, 1 wrong; missed 3 that xhigh caught, caught none xhigh missed. Sonnet by diff size: up to 100 lines 8/9, 101-200 lines 7/8, over 200 lines 5/10, vs Opus 9/9, 8/8, 7.5/10. Effort was verified to reach the model (output tokens 9.3k high vs 21.2k xhigh; all models claude-opus-5-5). Total test cost about $121 plus the Opus-high run; the session notes put the whole study at about $152 ($31 + $121 + the Opus-high run).
- Validity: planted bugs were written by Opus. The planted-bug test tied and hid the real-bug gap. The real-bug test ran each case once. In 3 cases reviewers looked up the real upstream fix online (2 of them only Opus), so it was not fully blind. Two planted bugs were not bugs. One Opus run's review text was lost. Side effects: Opus added a test key to the real ssh-agent, Sonnet ran `ssh-keygen -h`, two parallel reviewers shared a scratch dir with a broad pkill. Opus-high cost is slightly understated (connectors turned off). The assistant said further Sonnet prompting (a do-not-dismiss rule) would recover about half of Sonnet's misses at best (20 to about 22/27). Sonnet medium effort was never tested. The user dropped Sonnet max after the pilot. Public benchmarks are in sources.md.
- Decision: Opus xhigh stays the only reviewer. The light-reviewer (Sonnet) tier added the same day was removed. The Codex reviewer default was set to gpt-6.1-sol xhigh (before the test). "Opus high is not worth the savings".
- Commits:
  - `35fb091e dx(review): review every change with opus only` (body: "A real-bug A/B test caught 91% of bugs with Opus xhigh, 80% with Opus high, and 74% with Sonnet xhigh, so the light Sonnet tier is removed.")
  - `13c6a0e2 dx(review): add light-reviewer tier` (added, then removed the same day)
  - `57bf3f9a dx(codex): prune removed agent roles on apply`
- Sub-probes in the same session:
  - ToolSearch vs connectors off for reviewer runs (2 runs per setup): connectors off, no ToolSearch 8,349 tokens per request ($0.067 cold, $0.021 warm); connectors off plus ToolSearch 8,230; ToolSearch plus context-lean with 10 connectors 11,401 ($0.091 / $0.047). Keep connectors off for reviewers (about 27% smaller per request). No specific commit found.
  - Full first-request context of every role through a logging proxy: main about 4,800 tokens, general-purpose about 4,670, cheap about 3,330, worker about 3,300, reviewer about 2,900, consult about 2,860, explorer about 2,740, tester about 2,320-2,360. The rules audit then found about 370 tokens per turn (5% of 7,400) to trim; 22 trims applied. Commit (likely): `345ba6eb dx(agents): compact rules and skill descriptions`.
  - Haiku helper for review setup: finished in 13 s for about 11k tokens. Commit: `027f85c9 dx(review): hand review setup to a haiku helper`.
- Sessions and raw data: bc200b0a (2026-10-14); sub-agents of that session built the cases. `~/.cache/agents/scratch/review-ab/` is deleted. 39 `*review-ab*` run dirs survive. The case keys were later rebuilt from the transcript for the inline-vs-sub-agent test; the surviving keys are `~/.local/state/agents/answer-keys/review-inline-ab4/keys-real/r01..r25.json`.

### ToolSearch-off cost probe: agents-md plugin vs connector tools (2026-10-14)
- Question: what caused the roughly 595k-token calls ($4.83 for one reply)?
- Setup: free startup-event checks with a dead API address (no model call), varying `--strict-mcp-config` and `--tools`. Then real headless checks with a local recording server.
- Results: the root cause was ToolSearch missing, so about 595-617 connector tools were sent inline (about 600k tokens per call). The agents-md plugin was not the cause. `--strict-mcp-config` removes all 617 connector tools. `--tools Read` drops ToolSearch; `--tools Read,ToolSearch` keeps it. context-lean does not disable ToolSearch, and Claude Code defers MCP tools by default. With ToolSearch present context-lean deferred 2 tools, without it 0 (after the fix).
- Validity: review found a real bug (ToolSearch disabled through the settings file bypassed the guard), fixed with a per-variant free startup check.
- Decision: `agent-probe` guards headless variants against ToolSearch-off. context-lean stops deferring when ToolSearch is absent.
- Commits:
  - `28d3f07b dx(agents): guard headless probes from inline tools`
  - `ad467669 dx(claude): keep context notes without tool search`
- Sessions and raw data: b7f40d27 (2026-10-14). No raw data.

### Concise style A/B: output-style wording and per-turn reminder (2026-10-14)
- Question: which style variant gives the shortest replies without losing facts, and does a per-turn "be concise" reminder help?
- Setup: 5 arms x 8 prompts x 3 runs = 120 headless runs, inline file contents, no tools: current style, current plus Concise reminder, merged (current plus 6 rules paraphrased from the attention-span repo) plus reminder, attention-span "Spartan", built-in Concise. Scored by script (length, fact regex hits, first-line words, "offers more"), no LLM judge. Cost $2.19 for 120 runs.
- Results (median words / facts kept / audit-reply words / first-line words): current 77 / 92% / 431 / 28; current+reminder 85 / 92% / 433 / 28; merged+reminder 80 / 94% / 362 / 20; Spartan 111 / 90% / 410 / 16 (2 runs ended offering more); built-in Concise 88 / 94% / 400 / 27 (2 offers). All arms ignored the 10-row table cap (11-15 of 16 rows).
- Validity: an independent review found 4 method flaws. Depth-prompt counts are artifacts (3 runs scored valid were cut-off 2-turn runs). 1 run was a raw Write tool call scored as valid. Scorer regexes could not see the dropped `/copy` line. 3 runs per cell is too few. After correcting, the assistant retracted "mixed is shortest": the current style without the reminder was shortest (median 75 vs 79 vs 85). The only clear wins were the security-check reply (335 vs 431 words, 2 valid runs) and the status update (69 vs 91). The reminder showed no effect in single-turn tests; long chats and tool use were untested. The assistant also found a 595k-token anomaly in early runs (traced to ToolSearch-off, see the test above).
- Decision: added the merged rules (after fixing 3 conflicts found by review: the `/copy` line, blocking question vs `Next:`, bold-every-risk vs bold-sparingly; and rewording 2 lines near AGPL source) and kept the per-turn reminder hook.
- Commits:
  - `43e2978c dx(agents): add concise rules from style a/b test`
  - `7819604f dx(claude): repeat concise reminder each prompt`
  - `4f496d8d dx(agents): adopt concise replies and quiet waits` (same session, before the test)
- Sessions and raw data: 6cf86035 (2026-10-14). `~/.cache/agents/scratch/concise-ab/ab/` is deleted. 2 `*concise-ab*` run dirs survive.

### Auto-title cost probe (2026-10-13)
- Question: what does a Haiku session-title hook cost, and will `--bare` work?
- Setup: not described beyond the results.
- Results: about $0.00006 per title (under a cent a month). `--bare` needs an API key (account login in use), so a lean non-bare call of 620 tokens is used. A real-session test passed; review found 1 bug (fixed).
- Validity: no caveats recorded.
- Decision: a prompt hook sets the session title; scripted `claude -p` runs get no title.
- Commits:
  - `0f5e9423 dx(claude): name sessions from the first prompt`
- Sessions and raw data: 1aba7734 (2026-10-13). No raw data.

### Agent starting-context audit (2026-10-13)
- Question: how many tokens does each agent start with, and what can be trimmed?
- Setup: 11 agents run with a trivial prompt, first-call input tokens read from transcripts. Then re-measured after setting `omitClaudeMd` on worker and manual-tester.
- Results: 5 agents above 10k (claude-code-guide, claude about 47k, general-purpose, worker 14.2k, manual-tester 11.8k); cheap about 30k. After the change manual-tester 11.8k to 4.7k, worker 14.2k to 6.7k. Instruction files (about 5k in repos with AGENTS.md/AGENTS_PROJECT.md, about 1.2k otherwise) were the biggest item, not MCP tool names.
- Validity: a single measurement per agent. The live session cached old agent settings, so the effect showed only in new sessions.
- Decision: worker and manual-tester skip instruction files; missing safety and scratch rules were added to the role files.
- Commits:
  - `16feba2c dx(agents): give worker roles scratch and push rules` (likely; body empty)
- Sessions and raw data: 8be7c9b7 (2026-10-13). No raw data.

### Review experiment: single Opus xhigh vs xhigh plus Sonnet vs xhigh plus Opus low (2026-10-13)
- Question: why did reviews miss 5 issues a human reviewer ("DJ") found on MR 3 in claude-marketplace, and does a stronger or paired reviewer find them?
- Setup: original MR code, fixed new brief, 6 independent reviews: Opus xhigh x2, Sonnet medium x2, Opus low x2. Scored on 5 known findings (names, `##` split, resend, unordered writes, scanning untrusted results).
- Results: Opus xhigh #1 3/5 (11.6 min, 199k tokens) and #2 3/5 (same 3). Sonnet medium #1 2/5 (47 s, 31k), #2 2/5 (53 s, 27k, 1 false positive). Opus low #1 0/5 (38 s, 22k), #2 1/5 (30 s, 20k). Combined: xhigh alone 3/5, plus Sonnet 3/5, plus Opus low 3/5. Nobody caught findings 4 and 5 (performance and resource issues the brief never asked about). xhigh also found 2 extra real bugs (restore-notice, empty-text). Cost about 7x tokens and 13x time of Sonnet.
- Validity: the assistant: "one change with 2 runs per setup, treat as a strong hint, not proof". It offered a 2-3 MR rerun, not done.
- Decision: option 1 applied: Opus xhigh alone for logic changes (drop the Sonnet pairing) plus a cost-and-resources review check.
- Commits:
  - `368b535a dx(review): fix reviewer briefs and add review checks`
  - `79eb7192 dx(review): always delegate to deep-review`
  - `71ee6bb1 dx(review): use one reviewer and loop every fix`
- Sessions and raw data: 1602cbf2 (2026-10-13, web-player). `~/.cache/agents/scratch/review-experiment/` is deleted. Web sources from this session are in sources.md.

### Explorer routing: Haiku vs Sonnet on 5 search tasks (2026-10-12)
- Question: can searches move from Sonnet to Haiku?
- Setup: 5 tasks of rising difficulty in web-player (usage listing, config lookup, test selection, ad-loading trace, play() trace), one Haiku and one Sonnet agent each (10 agents), graded by the assistant against its own exact answers.
- Results: usage list: both found all 10 files (Haiku also flagged a borderline 11th). Lookup: both right (Sonnet cited one wrong line, 238 vs 244). Test selection: Haiku "strong". Ad-loading trace: Haiku line numbers more exact but it missed that some builds bundle the ad code. Haiku missed things on deeper traces. No per-arm cost figures reported.
- Validity: n=1 per cell, self-graded.
- Decision: usage lists and test selection to Haiku; tracing and mixed test work stay on Sonnet (later superseded by the Oct 30 Haiku delegation probes, which moved the explorer to Haiku).
- Commits:
  - `047c756c Update .config/agents/skills/sub-agents/references/roles.md Add .config/agents/skills/frontend-design/.keep Update .config/agents/AGENTS.md` (auto-commit)
- Sessions and raw data: f3be5936 (2026-10-12). No raw data.

### Deep (Opus high) vs normal (Sonnet medium) reviewer, observational (2026-10-08)
- Question: has the paired deep plus normal review rule ever found anything?
- Setup: not a new run. It compared the 4 paired reviews (r1-r4) from the compact-bench repos.
- Results: the deep reviewer found real issues in 3 of 4 (r4 CI type check fail, r3 two test pages 404, r1 docs build break). The normal reviewer found only the r3 page break. Deep reads 5-40x more input tokens, 6-12 min vs 1-2 min. r5 and r6 (7,000 lines, no deep review) both missed the page break.
- Validity: 4 runs, one TypeScript migration, never on real MR work.
- Decision: keep the deep reviewer on risky changes; no change made then.
- Commits: none found.
- Sessions and raw data: 12f4279c (2026-10-08). No raw data.

### compact-bench: auto-compact at 500k vs default (2026-10-07)
- Question: does `autoCompactWindow` at 500k change cost, time or quality on a big migration?
- Setup: 3 rounds, 2 headless Opus 5.5 1M sessions per round (500k window vs default), isolated copies, a macOS sandbox hiding the other arm, in web-player. R1 converts `src/js/related/` (27 files). R2 converts all folders under `src/js/` (88 files). R3 converts the same 88 files with helper agents and workflows disabled. Scored by tsc, lint, build, unit tests, a count of `any`/ts-ignore/`!`/`as unknown as`, and blind reviewers (R3 only). n=1 per arm per round.
- Results (500k vs default): R1: peak ctx 255k vs 304k, 0 compactions both, $8.92 vs $12.94, 21 vs 26 min, all checks pass, 27/27 files. R2: peak main ctx 200k vs 241k, 0 compactions, $23.41 vs $21.08, 33 vs 32 min, full CI lint pass vs fail (type error in packages/jwplayer; run-to-run variation, not compaction). R3 (agents off): 500k compacted once at 466k to 15k, $29.67, 68 min, 655 calls, 117 file-reads; default peaked at 753k, 0 compactions, $34.05, 59 min, 572 calls, 94 reads. Blind review: 2 minor vs 1 minor issues; both fail the same lint. Total about $135 for 6 sessions.
- Validity: R1 and R2 never reached 500k, so they tested nothing about compaction. R3 is n=1 and R1 showed a $4 gap between two non-compacting runs, so the 13% saving "could be noise". With normal helper-agent use, main context peaked at 200-304k. One R2 default session wrote files outside its copy (its partner never read them). The assistant deleted `~/.cache/agents/scratch/rv/` by mistake (reviewer scratch, 6 files, 830 KB). Quality was about equal.
- Decision: no setting change attributable to this run. The user asked about a 500k trigger; the assistant concluded a 500k trigger would rarely fire in the user's setup. Later compaction commits set 400k and 433k and are not tied to this test in any transcript.
- Commits: none found (`git log --grep=compact` found a0a1ba46, 2145d42a and ce9f9ea6, which have empty bodies).
- Sessions and raw data: 990ee95c (2026-10-07); reviewer sub-sessions a51e3f2c and 12f4279c. The scratch dir `~/.cache/agents/scratch/compact-bench/` was deleted at the user's request (13 GB). 6 `*compact-bench*` run transcript dirs survive.
