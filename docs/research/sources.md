# Sources behind agent-setup changes

Why each dotfiles agent-setup change was made, and what each source supported. Changes are grouped by topic, newest first within a group. Dates are commit dates in local time unless the entry says otherwise. A/B results are in [ab-tests.md](ab-tests.md).

Common caveats:
- "Fetched" means the page was fetched and a model summary of it supported the claim. WebFetch in these sessions summarized pages through a small model, and often said "excerpt truncated". It does not mean the raw page was quoted.
- "Snippet only" means the session saw WebSearch result text for that URL, not the page.
- Status was checked against the repo on 2026-11-06 where the entry says so. Otherwise it comes from the session notes.

## Context and compaction

### Auto-compact window 400k for sub-agents, then all sessions (2026-10-14)
- Change: `autoCompactWindow` 400k in the 8 agent files, then one global `autoCompactWindow` in settings with the agent lines removed. The statusline context warning became relative to the window. A first try of `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60` was removed before commit.
- Status: replaced. The window was tuned afterwards and `claude-settings-modify.sh` now sets `"autoCompactWindow": 433000` (checked). The 400k pick was "a reasoned pick, not a measured optimum".
- Commits:
  - `77cc26cc dx(agents): compact subagents at 400k tokens`
  - `a0a1ba46 dx(claude): auto-compact all sessions at 400k`
  - `2e31908d dx(claude): warn relative to auto-compact window`
  - `cb0c8a45 dx(claude): auto-compact at 400k, not 367k`
  - `2145d42a dx(claude): trim output and compaction window`
- Sources (session 01c1e1f7, per-agent 400k):
  - [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents.md) — sub-agents auto-compact on their own window; `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` applies to sub-agents; per-sub-agent `autoCompactWindow` frontmatter takes 100000 to 1000000 (since 2.1.296/2.1.299).
  - [Claude Code env vars](https://code.claude.com/docs/en/env-vars.md) — `CLAUDE_CODE_AUTO_COMPACT_WINDOW` overrides the frontmatter value.
  - [Claude Code CHANGELOG](https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md) — `autoCompactWindow` added in 2.1.296.
  - [claude-code issue #63186](https://github.com/anthropics/claude-code/issues/63186) and [#36381](https://github.com/anthropics/claude-code/issues/36381) — `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` reportedly ignored when set in settings.json. This is why the 60% variant was dropped for the window setting.
- Sources (session dda15a16, global 500k then 400k):
  - [CliffCompaction](https://arxiv.org/html/2609.26779) — up to 50% lower cost with bounded context; success held at moderate thresholds on Terminal-Bench.
  - [Beyond Token Savings](https://arxiv.org/html/2609.32961v1) — fewer tokens does not always mean a lower bill; best method 0.71x cost, another lost 11 points.
  - [LangWatch, The Context Tax](https://langwatch.ai/blog/context-tax-when-to-compact) and [Optimal Context Window](https://langwatch.ai/research/finding-the-optimal-context-window) — compact in the 250k to 450k range; corrections rise after a compaction. This was the basis for 400k.
  - [SWE-Pruner](https://arxiv.org/pdf/2601.16746) — context pruning cuts cost.
  - [Chroma Context Rot, W&B summary](https://wandb.ai/byyoung3/ml-news/reports/Chroma-Research-Warns-of-Context-Rot-as-LLMs-Falter-with-Long-Inputs--VmlldzoxMzczMjQ4MQ) — all 18 models degrade as input grows.
  - [Compaction write-up (JetBrains figures, secondhand)](https://practiceoverflow.substack.com/p/compaction-the-hidden-trick-that) — hiding old tool output cut cost from $3.47 to $1.52 per task.
  - [claudeissues.com #63627](https://claudeissues.com/issue/63627-auto-compact-ignores-claude-autocompact-pct-override-on-1m-context-opus-no-compa) — override ignored on 1M-context Opus.
  - Local data: the user's own transcripts showed 57% of cost came from calls over 200k context.
- Evidence: 01c1e1f7 read docs "from page summaries, not the raw docs text" and flagged that as unverified. dda15a16 cited the papers from search summaries only ("I've only read the search summaries, not the full papers"). The session 01c1e1f7 also read the study ledger from the orchestrator context study (see Sub-agents and orchestration).

### Auto-compact at 500k, benchmark question (2026-10-07)
- Change: none. The session answered "what are the negatives of auto-compact at ~500k", estimated cost, and ran a 3-round local A/B. Its attempt to set `autoCompactWindow` 500k in `~/.claude-two/settings.json` was blocked by the safety check, and its final report said "Your settings are unchanged".
- Status: no change made. The later 400k/433k commits are not tied to this benchmark in any transcript. See [ab-tests.md](ab-tests.md) for the numbers.
- Commits: none from this session.
- Sources (all WebSearch snippets, no WebFetch):
  - [Context Rot (Chroma, 2025)](https://research.trychroma.com/context-rot) — all 18 models tested degrade as input grows.
  - [Lost in the Middle (Liu et al., 2023)](https://arxiv.org/abs/2307.03172) — recall is best at the start and end of context.
  - [The Complexity Trap (JetBrains, 2025)](https://arxiv.org/abs/2508.21433) — hiding old tool output matched LLM summaries on SWE-bench-style tasks, both at about half the cost. The session marked its recollection that summaries "matched or beat" untouched history as "unverified: I haven't rechecked".
  - [Effective context engineering for AI agents (Anthropic)](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — attention budget and compaction guidance; no threshold recommended.
  - [Effective harnesses for long-running agents (Anthropic)](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — progress files and git commits for fresh or compacted contexts.
  - [Cookbook: automatic context compaction](https://platform.claude.com/cookbook/tool-use-automatic-context-compaction) — API threshold example; no recommended number.
  - [claudeissues.com #63627](https://claudeissues.com/issue/63627-auto-compact-ignores-claude-autocompact-pct-override-on-1m-context-opus-no-compa) — `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` sometimes ignored on 1M models. The session marked it "unverified" and chose `autoCompactWindow` instead.
  - [Claude pricing](https://platform.claude.com/docs/en/about-claude/pricing) — cost model for "$10-15 per long session". The session later corrected itself: "$12 per long session" assumed one context, and with helper agents sessions rarely get that big. The 835k default trigger was "unverified: third-party write-ups".
- Evidence: web claims from search snippets, several self-flagged unverified. Session 990ee95c (2026-10-07). The local A/B (6 sessions, about $135) is n=1 per arm.

## Review

### Review comments on own MRs: auto-mode rule and review skill (2026-10-15)
- Change: an auto-mode allow rule lets Claude post, reply to, resolve and reopen review comments on MRs/PRs the user authored, during a review the user asked for. Simplified to 8 entries, then dropped exceptions restored. The review skill posts signed review comments on own MRs and gates a second review on the first. Current allow text: "Review comments on MRs/PRs the user authored, during a review the user asked for in this session: post, reply, resolve, and reopen. Never on MRs/PRs others authored."
- Status: current (the rule text is in `claude-settings-modify.sh`). Review-skill wording changed later and was not re-checked.
- Commits:
  - `23c9c88c dx(review): post signed review comments on own MRs`
  - `1cc6cc7d dx(claude): simplify auto-mode rules`
  - `2f1ff037 dx(claude): restore dropped auto-mode exceptions`
  - `8467b67e dx(review): fix comment anchors, publish, and replies`
  - `36ad23ba dx(review): name repo and gate skips on open items`
  - `84d805cd dx(review): reopen only review-marked threads`
  - `bcc05cf3 dx(review): keep own open findings and skip early`
  - `8601b7ef dx(review): let review-again bypass skip, count open threads`
  - `fd0ca2cc dx(review): fix skip override and open count`
  - `06823c91 dx(review): count open GitHub general findings`
- Sources:
  - [Claude Code, configure auto mode](https://code.claude.com/docs/en/auto-mode-config) — `autoMode` environment/allow/deny; the classifier documents labels `Organization:`, `Trusted source control:`, `Trusted internal domains:`; deny and explicit ask rules run before the classifier.
  - [Claude Code permission modes](https://code.claude.com/docs/en/permission-modes) — auto mode behavior.
  - [GitLab draft notes API](https://docs.gitlab.com/api/draft_notes/) and [discussions API](https://docs.gitlab.com/api/discussions/) — posting and resolving threads.
  - [GitHub REST, create a review for a pull request](https://docs.github.com/en/rest/pulls/reviews?apiVersion=2022-11-28#create-a-review-for-a-pull-request) — creating a review.
- Evidence: docs fetched. Session 34dbf6d2 (2026-10-15/16). The reply said "Nothing has run on a real MR/PR yet; the posting commands come from the CLI help and API docs" and "I can't test [classifier recognition] without a live MR/PR".

### Main session reads nothing for review; reviewer reads ranges; Haiku setup helper (2026-10-14)
- Change: global read rule: find code with LSP/ast-grep/rg, read only those ranges with `sed -n`/`rg`, still read the whole changed function, callers and contracts. Current wording in `private_AGENTS.md`: "Read ranges with `sed -n` or `rg`; the file-read tool's line-numbered output costs more tokens." The reviewer role got the LSP tool. Review setup (checkout, deps, background checks, prompt writing) moved to a Haiku helper with its own setup.md. The main session passes only the target.
- Status: read-range rule current (checked in `private_AGENTS.md`). The reviewer's LSP tool was replaced by code-graph tooling in 19187158 (see "LSP-first lookup rule"). Haiku setup helper not re-checked.
- Commits:
  - `61818955 dx(agents): read ranges via sed and rg to save tokens`
  - `78752a06 dx(agents): give reviewer the LSP tool`
  - `027f85c9 dx(review): hand review setup to a haiku helper`
  - `c9da99d3 dx(review): skip reviewer checklist in main session`
  - `345ba6eb dx(agents): compact rules and skill descriptions`
- Sources: no web sources. Evidence is internal: a context audit through a logging proxy (agent first request 2.3k-3.3k tokens; review-steps file about 2,340 tokens; sub-agent role prompts 210-390 tokens; about 370 tokens per turn could be trimmed, about 5% of a 7,400-token fresh session).
- Evidence: measured token counts. The read-range rule was a user directive, not benchmarked. Unverified in the session: savings of partial reads of about 1.1-1.5k tokens per review, and whether the Agent tool can override effort. Session bc200b0a (2026-10-14).

### Light vs normal reviewer: tier added, then removed (2026-10-14)
- Change: a `light-reviewer` (Sonnet 5.5 medium; Codex gpt-6.1-sol low) was added for prose, cosmetic and small diffs, with `--light`/`--normal` flags, and Codex `reviewer` was set to gpt-6.1-sol xhigh. After a local A/B the user said "alright let's remove the light reviewer role and sonnet as a reviewer". Every change is reviewed by the Opus xhigh `reviewer`.
- Status: replaced. The tier was removed 23 minutes after it was added. Sonnet came back later for low-risk and fix checks (23662f0c, 10-20), then in the cheaper tiers (e3ee004f, 10da7d14, 212863cd, fd673112, 10-30). Opus `reviewer` was lowered to high by 8a029ed0 (11-02) and put back to xhigh by 569767d2 (11-02). See [ab-tests.md](ab-tests.md).
- Commits:
  - `13c6a0e2 dx(review): add light-reviewer tier`
  - `35fb091e dx(review): review every change with opus only` (body: "A real-bug A/B test caught 91% of bugs with Opus xhigh, 80% with Opus high, and 74% with Sonnet xhigh, so the light Sonnet tier is removed.")
  - `57bf3f9a dx(codex): prune removed agent roles on apply`
  - `23662f0c dx(review): use sonnet for low-risk and fix checks`
  - `e3ee004f dx(skills): cheaper review modes for small changes`
  - `10da7d14 dx(skills): review low-tier changes with haiku`
  - `212863cd dx(skills): drop inline review mode, send low tier to haiku`
  - `fd673112 dx(skills): review medium changes with opus, keep sonnet for fix checks`
  - `8a029ed0 dx(agents): lower opus reviewer to high effort`
  - `569767d2 revert(agents): put opus reviewer back at xhigh`
- Sources (the decision rests on the local A/B; web items were background):
  - Local A/B 1, planted bugs: Opus 61/68 (89.7%), Sonnet 63/70 (90.0%), $0.97 vs $0.46 per review. Planted bugs were written by Opus; 2 were not real bugs.
  - Local A/B 2, real bugs mined from the user's repo history: Opus xhigh 24.5/27 (91%) at $1.14, Opus high 21.5/27 (80%) at $0.55, Sonnet xhigh 20/27 (74%) at $0.61. Details in [ab-tests.md](ab-tests.md).
  - [CodeRabbit, Sonnet 5.5 vs Opus 5.5](https://www.coderabbit.ai/blog/sonnet-5-5-model-review) — Opus 10/13 issues vs Sonnet 8/13. The session said "only 13 cases, table partly garbled".
  - [Vellum, Sonnet 5.5 benchmarks](https://www.vellum.ai/blog/claude-sonnet-5-5-benchmarks-explained) — Sonnet 55.5% vs Opus 57.8% on CursorBench; not about review.
  - [Qodo, Which LLM should review your code?](https://www.qodo.ai/blog/which-llm-should-review-your-code/) — benchmark 1.0, 100 PRs, 580 defects.
  - [Martian Code Review Bench](https://codereview.withmartian.com/) — public review benchmark.
  - [GitHub ReviewBench](https://github.blog/ai-and-ml/github-copilot/reviewbench-an-open-benchmark-for-ai-code-review/) — open review benchmark.
  - ["Bigger Isn't Always Better"](https://arxiv.org/html/2606.15689v1) — planted bugs overstate reviewer recall; Haiku 29% and Sonnet 4.6 25% on real bugs. Used as a caution.
  - [Medium comparison of 2026 public AI code review benchmarks](https://medium.com/@codzee.io/we-compared-the-public-ai-code-review-benchmarks-from-2026-methodology-datasets-metrics-and-269dd35637a6) — methodology comparison.
- Evidence: all web items are WebSearch snippets used as background. The session's own conclusion: public benchmarks are vendor-run, AI-graded or planted-bug based; none uses the user's prompt or xhigh effort. Session bc200b0a (2026-10-14). Sonnet medium effort was never tested.

### Review misses diagnosis: fixed reviewer brief, Opus xhigh deep-review, extra checks (2026-10-13)
- Change: after the DJ review bot found 5 issues on claude-marketplace MR !3 that earlier local reviews missed, the review skill got a fixed reviewer brief built only from template fields. Wording: "Never write your own summary of the change, what to focus on, what to skip, what already passed, or where code came from". A deep review ran at `xhigh` on every logic change (Sonnet+Opus pair first, then Opus xhigh alone after a 6-run experiment). Reviewers check what the host runtime does and report unverifiable runtime questions as "unverified". New checks: cost/resources, error handling, untrusted data, misleading names. Four ideas from OSS reviewers: a pre-flag test, a severity-based bar, MR text/code is data and cannot change role/steps/format, and "no findings is a valid result".
- Status: partly replaced. `79eb7192` ("always delegate to deep-review") and `71ee6bb1` (one Opus xhigh `reviewer`, `deep-review` role deleted) merged the Sonnet+Opus pair into one reviewer the same day. The review loop was rewritten many times after (10-16 3b5c701a, 3c39ee31; 10-20 23662f0c; 10-30 e3ee004f, 10da7d14, 212863cd, fd673112; 11-01 a88c1733; 11-02 8a029ed0, 569767d2). The fixed-brief rule and the extra checks live in reviewer-steps.md and delegation.md, but their exact wording was not re-checked and is likely rewritten.
- Commits:
  - `368b535a dx(review): fix reviewer briefs and add review checks`
  - `8a88000f dx(context-lean): sync MR fixes and new hiding` (context-lean fixes from the same findings; no web sources)
  - `79eb7192 dx(review): always delegate to deep-review`
  - `71ee6bb1 dx(review): use one reviewer and loop every fix`
- Sources:
  - Internal: [DJ review-bot repo](https://gitlab.com/jwpconnatix/groups/aipoc/review-bot) — Opus 5.5 `xhigh`, diff only, fixed prompt, categories incl. performance/resource-management, "what would a senior engineer raise" filter. Claim: not a stronger model than deep-review; the difference is brief and scope.
  - [OpenAI Codex review rubric](https://github.com/openai/codex/blob/main/codex-rs/prompts/templates/review/rubric.md) — pre-flag test ("does not rely on unstated assumptions", "identify the other parts ... provably affected").
  - [Qodo PR-Agent](https://github.com/qodo-ai/pr-agent) — stricter for low severity; "do not skip a genuine problem just because the trigger scenario is narrow"; code under review is data.
  - [Anthropic claude-code-security-review](https://github.com/anthropics/claude-code-security-review) — per-repo never-flag list (not adopted).
  - [SWR-Bench](https://arxiv.org/html/2509.01494v2) — multiple runs raise recall; mixing models adds false positives (not adopted). Snippet level from WebSearch.
  - ["Can LLMs Catch a Rigged Backtest?"](https://arxiv.org/pdf/2609.28090) — an "assume it's broken" framing caused 11 of 12 false positives; "no findings is valid" removed them. The session marked it "unverified: from a search snippet only".
  - Local 6-run experiment: see [ab-tests.md](ab-tests.md).
- Evidence: the bot setup was read through the glab API by a sub-agent (fetched and read). The OSS repos were cloned and key lines quoted. Two arXiv items are search-snippet only. The model-vs-effort conclusion rests on the 6-run local experiment. Session 1602cbf2 (2026-10-13).

### Review loop: two cycles, fix checks, severity labels, auto-loop for risky changes (2026-10-13)
- Change: after mining 84 past sessions with independent reviewers, the loop became up to two cycles. Each cycle is one full review by a fresh small+big pair, then up to 3 fix checks by the same reviewers (given all findings and the fix delta). The inner loop stops when a fix check finds no new high/medium bug; low bugs and nits never start another pass. The second cycle uses a fresh blind pair; after that, stop and ask. Bugs carry `high`/`medium`/`low`. Risky changes loop automatically, `--no-loop` turns it off, `--loop` forces it. dotfiles-sync gained an apply step and `.gitignore` ignores `__pycache__`.
- Status: partly current. loop.md still has two cycles, up to 3 fix checks, and "major" = high/medium bug (later edits: fix checks use `model: sonnet`, `agt review` store). The small+big pair was dropped by 71ee6bb1, which made every fix loop. The risky-only auto-loop and `--no-loop` were rewritten by 3c21bbe7 and 71ee6bb1; `--no-loop` is not found in the current agents dir (checked).
- Commits:
  - `ea18c600 dx(review): loop in two cycles with fix checks`
  - `79352b6e dx(review): loop automatic reviews of risky changes`
  - `e6a8c2bf dx(dotfiles-sync): apply targets after push`
  - `9238f5d3 build: ignore python bytecode caches`
  - `71ee6bb1 dx(review): use one reviewer and loop every fix`
  - `3c21bbe7 dx(review): review only at task end points`
  - 5ff57cb2 "Update ..." was a stray chezmoi auto-commit that picked up 20 other files 4 seconds later; auto-commit was removed by `3f7ca652 dx(chezmoi): stop auto commit and push`.
- Sources:
  - Internal data (the main basis): 84 sessions with independent reviewers, 71 changes scored by 3 analysis agents. Round 1: 55/71 found something real (78%), 35 a bug (51%). Round 2: 23/36 (70%), 15 bugs. Round 3: 4/7. Round 4: 3/4. Round 5: 1/1. Only 19 of 71 ended on a clean round. The deep/Opus reviewer found a bug the plain one missed in at least 6 rounds. An earlier audit showed independent reviewers missed 72 of 394 issues (18%), and 40 of 114 misses were not visible in the diff. The session said the counts are model-scored and "approximate and likely high".
  - [Anchoring Bias in LLM-as-a-Judge](https://arxiv.org/pdf/2608.25869) — prior scores weaken the next judgment. Snippet only.
  - [Pride and Prejudice (ACL 2024)](https://aclanthology.org/2024.acl-long.826.pdf) — models favor their own output. Snippet only.
  - [AgentPatterns, self-review modernization failure](https://agentpatterns.ai/patterns/anti-patterns/self-review-modernization-failure/) — the producing model missed 31.7% of behavior changes. Marked "unverified: secondhand".
  - [Should we be going MAD? (ICML 2024)](https://proceedings.mlr.press/v235/smit24a.html) — debate doesn't reliably beat voting. Snippet only.
  - [Controlled debate study](https://arxiv.org/pdf/2511.07784) — same claim. Snippet only.
  - Session note: "None of these studies compares re-review by the same reviewer against a fresh one."
- Evidence: 2 WebSearch calls, all five URLs from result snippets, no fetches. The design came mostly from the local data and the user's own proposed flow ("OK so we change to ..."). The loop was dogfooded on its own change (11 issues, then 3 medium + 7 low). Session f9eb94ba (2026-10-13).

## Sub-agents and orchestration

### Orchestrator context study: agent result cap, checkpoints, bulk checks (2026-10-13)
- Change: the research session (no edits of its own) produced a 102-item ledger and 9 proposals for keeping the orchestrator session small. Session 66da602a applied 8 of 9 as `d813f42b`. Wording now in agent roles: agents write results over about 40 lines to a file and return at most 5 lines (path, counts, status). Other adopted items: bulk checking by a fresh verifier agent instead of "Re-validate every result", a shared brief file with a spot-check for open-ended work, a checkpoint at every phase of a multi-agent run. Proposal 8 (settings/hooks: SessionStart ledger hook, ~30% `/clear` checkpoint hook, `DISABLE_AUTO_COMPACT=1`, lower `MAX_MCP_OUTPUT_TOKENS`) was built, then fully removed before any commit ("D8 is fully removed... Auto-compact is back on").
- Status: current for the result cap and checkpoint wording. D8 never committed. Whether proposal 5 (output-style exception for orchestration tables) was among the 8 applied was not checked. Of three conflicting rules the session flagged ("Re-validate every result", "Verify each item yourself", output-style "Show data in full"), which were changed was not checked.
- Commits (made by session 66da602a, not by the research session):
  - `d813f42b dx(agents): trim rules and cap agent result size`
  - `94a473d1 dx(agents): trim rules and cap agent result size`
  - `7f68382c dx(claude): drop deny rules for a disabled plugin`
- Sources (sub-agents did WebFetch; final reply listed these 7):
  - [Claude Code workflows](https://code.claude.com/docs/en/workflows) — "Claude's context holds only the final answer"; script variables hold intermediate results.
  - [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) — role and spawn prompt result handling.
  - [Claude Code hooks](https://code.claude.com/docs/en/hooks) — hooks cannot trim background agent results; SessionStart reload.
  - [Building a C compiler (Anthropic)](https://www.anthropic.com/engineering/building-c-compiler) — headless loop pattern, but it runs with `--dangerously-skip-permissions` (the session said do not copy that).
  - [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — state on disk.
  - [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — sub-agents write to files and return references.
  - [Run long-horizon tasks with Codex](https://developers.openai.com/blog/run-long-horizon-tasks-with-codex) — plan and ledger files for Codex (fetched .md).
  - Also fetched but not in the final list: effective-context-engineering, context-window, settings-reference, env-vars, costs, headless, goal, cross-session-messaging, agent-teams, agent-sdk/subagents, ADK context, Letta MemGPT, Magentic-One, Cursor background agents, HF paper 2606.11213, primeintellect RLM blog, vantaige.io sub-agents blog, codex.danielvaughan.com context-window post.
- Evidence: fetched pages cited in a ledger of 102 items; 13 items rejected; none tested live. The session said: "Not checked: Jules, Google ADK compaction page, Cursor beyond search results. No hook was tested live." Research session acb7f610 (2026-10-13, open-ended skill, 4 of 6 rounds, 11 sub-agents); applied by session 66da602a (2026-10-13).

## Hooks

### Session titles: port, branch and part number via `sessionTitle` (2026-11-06)
- Change: hooks name sessions with the session's port, then by branch and "Part N"; clear the old name on `/clear`; skip headless runs; `/rename` wins over a pending branch name. On Oct 14 a hook retitled sessions after `/clear` and left user-set names alone.
- Status: current (`session-port.sh` and `auto-title.sh` exist in `home/dot_claude/hooks`; latest commit 0cc5217a).
- Commits:
  - `0cc5217a fix(claude): let /rename beat a pending branch`
  - `05cc1ad4 fix(claude): rename only on a move to another branch`
  - `24756ce6 fix(claude): fit branch names beside the port`
  - `e13918c7 feat(claude): name sessions by branch and part`
  - `b016cc17 fix(claude): keep headless runs out of session naming`
  - `d82235b3 fix(claude): drop the carried-over name on /clear`
  - `468dd076 feat(claude): start session names with the session's port`
  - `a23c3518 dx(claude): retitle sessions after /clear`
- Sources:
  - [Claude Code hooks reference](https://code.claude.com/docs/en/hooks) — SessionStart `sessionTitle` "Sets the session title, with the same effect as /rename. Applies when source is startup, resume, or fork". SessionStart input carries `session_title` ("a hook that emits sessionTitle can check this field first to avoid overwriting an existing custom title"). UserPromptSubmit `sessionTitle`: "Use to name sessions automatically based on the prompt content"; it also receives `session_title`.
  - Same page, CwdChanged — fires "when Claude executes a cd command", no matcher, no decision control. The doc does not say whether it fires for sub-agents.
  - Same page, print mode — a fetch asked whether SessionEnd/Stop fire in `claude -p`; the summary said the excerpt did not settle it (only `terminalSequence` is ignored in `-p`). b016cc17 (keep headless runs out of naming) is not backed by a doc quote.
  - [Claude Code sessions](https://code.claude.com/docs/en/sessions) — generated titles are not custom titles.
- Evidence: fetched and quoted by a sub-agent. "A hook cannot clear a title on /clear" was checked in the installed 2.1.299 binary, not from docs. Sessions 27c2f151 (2026-10-14), fb027f3e (2026-11-06, port prefix and /clear), 4d83f96c (2026-11-06, branch and part; fetched the CwdChanged text). Commits 468dd076, d82235b3, b016cc17 are matched to fb027f3e by commit time; 24756ce6, 05cc1ad4, 0cc5217a are matched to 4d83f96c by time and not seen in its transcript.

### Bash guard rewrites bad commands with PreToolUse `updatedInput` instead of blocking (2026-10-28)
- Change: `bash-guard.py` fixes quote-`=` words, trailing `echo $?`, `pgrep -f` self-match, missing `ToolSearch` in headless `--tools`, and foreground waits, and tells the model what it ran. It still blocks kills by name, `claude -p` in a handoff session, and anything unsafe to rewrite. The rewrite is returned without a `permissionDecision`.
- Status: current (`executable_bash-guard.py` exists; latest edits f16ba2e8 and 720906f9 after this change).
- Commits:
  - `9926b953 dx(bash-guard): fix bad commands, not block them`
  - `e30593bf fix(bash-guard): keep heredocs, groups, broad pkill safe`
  - `08c3e356 fix(bash-guard): parse-check fixes, scope wait &`
  - `838aef18 fix(bash-guard): strip & after a piped agt wait`
  - `ce908996 fix(bash-guard): refuse unsafe cuts, quoting, waits`
- Sources:
  - [Claude Code hooks reference, PreToolUse decision control](https://code.claude.com/docs/en/hooks) — `updatedInput` replaces the whole input; "Claude Code evaluates permission rules ... against the input your hook returns"; "Combine with allow to auto-approve, or ask to show the modified input"; "defer: ignored". The docs say nothing about `updatedInput` without a `permissionDecision`.
  - [claudeissues.com #79321, PreToolUse updatedInput ignored for Bash](https://claudeissues.com/issue/79321-bug-pretooluse-hook-updatedinput-is-silently-ignored-for-the-bash-tool) — the reporter saw rewrites dropped on v2.1.207 (Windows Git Bash) even with allow; closed "not planned" Sep 5 2026. It raised the risk that the rewrite may not apply.
  - [claudeissues.com #32060](https://claudeissues.com/issue/32060-feature-hooks-permissionrequest-and-pretooluse-support-updatedinput-without-requ) — request to allow `updatedInput` without `permissionDecision`; closed "not planned"; the page does not say what shipped.
- Evidence: docs and issues fetched (4 hook-doc fetches, the first two truncated before the section) and cited in the reply ("the docs only describe a rewrite paired with allow or ask"). The undocumented no-decision case was settled by a headless probe on 2026-10-28: "a rewrite with no decision applies, and permission checks still run against the new command". Review found 10 bugs, all fixed with tests. Session 157ecfb6 (2026-10-28).

### Tmux bell when Claude waits for input (2026-10-16)
- Change: a hook rings the tmux bell when Claude needs input.
- Status: current (`executable_tmux-bell.sh` exists).
- Commits:
  - `416f4d78 feat(claude): ring tmux bell when waiting for input`
- Sources:
  - [Claude Code hooks](https://code.claude.com/docs/en/hooks) — Stop "Does not run if the stoppage occurred due to a user interrupt"; Stop input fields `stop_hook_active`, `last_assistant_message`; Notification event (page truncated before it).
  - [Claude Code goal](https://code.claude.com/docs/en/goal) — `/goal` keeps turns going; checked so the bell does not ring mid-goal.
- Evidence: both pages fetched, partially truncated. The bell was tested on a separate tmux server with a real reply. Session d69dd9a4 (2026-10-16).

### Session names from the first prompt via a Haiku hook (2026-10-13)
- Change: a UserPromptSubmit hook sets `sessionTitle` from a short Haiku summary of the first prompt. The first design used `claude --bare`; `--bare` needs an API key (account login in use), so a lean non-bare call of 620 tokens is used. Scripted `claude -p` runs get no title.
- Status: replaced in part. The `auto-title.sh` hook was reworked for port and branch naming (see the Nov 6 entry above).
- Commits:
  - `0f5e9423 dx(claude): name sessions from the first prompt`
- Sources:
  - [eesel.ai, Claude Haiku 5.5 pricing](https://www.eesel.ai/blog/claude-haiku-5-5-pricing) — Haiku 5.5 price used to estimate per-title cost (about $0.00006 lean, $0.003 plain).
  - [apidog, Claude Haiku 5.5 pricing](https://apidog.com/blog/claude-haiku-5-5-pricing/) — same.
  - [letsdatascience, Haiku 5.5 price cut](https://letsdatascience.com/blog/claude-haiku-5-5-cut-prices-90-prompts-over-100k-pay-5x) — same.
- Evidence: cited in the reply and flagged by the assistant as "from third-party sites, not Anthropic's own pricing page". The `sessionTitle` capability came from the app binary ("I saw the field in the app code"), not a doc. Session 1aba7734 (2026-10-13).

## Skills

### Skill descriptions and bodies tuned with Anthropic's skill-creator guide (2026-11-05)
- Change: 20 skill descriptions got trigger contexts and several bodies were trimmed. The user then asked "is this worth doing? wont it be more tokens?", so descriptions were shortened and then restored. Net effect is 4 skills changed: `code-standards` (code-quality.md is now a link), `jenkins`, `ticket` (stale "as step 4 does" reworded), `ux-verify`. Descriptions are unchanged from before.
- Status: description work reverted by 5ac0362f. Body trims current.
- Commits:
  - `5ac0362f dx(skills): restore original skill descriptions`
  - `bdd83330 dx(skills): keep listed descriptions short`
  - `e34b4b20 docs(skills): drop misleading triggers from commit and explicit-only skills`
  - `fa0991a5 dx(skills): trim redundant body text and link code-quality reference`
  - `6240b6a6 docs(skills): add trigger contexts to skill descriptions`
- Sources:
  - Anthropic skill-creator SKILL.md (local plugin file): `/Users/bcasey/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md`, sections "Write the SKILL.md", "Skill Writing Guide", "Writing Style", "How to think about improvements" — descriptions state what and when with trigger contexts; all "when to use" text belongs in the description, not the body; imperative body; progressive disclosure with read-when pointers.
- Evidence: a local file named in the task prompt, read by the worker. No web fetch. The guide's "pushy descriptions" advice was explicitly not followed, and the token-cost objection led to the revert. Session d6a0632d (2026-11-05, user asked "run anthropic skill-creator over my skills to improve"); work done by worker session e1a8a39d (2026-11-05) from a task prompt written by d6a0632d. 31 skills reviewed.

## Rules and instructions

### Code-quality and verification rules loaded by path, with an edit gate (2026-11-06)
- Change: the always-loaded code-standards rule moved to a path-scoped rule `~/.claude/rules/code-standards.md` (`paths` globs for code and config). An edit hook (`rule-gate.py`) denies edits until the matching path rules were read. Follow-up fixes: same-batch edits, hang and state loss, interrupt note. Verify/ship/fix steps tightened; hooks made Python 3.9 safe.
- Status: current (`exact_rules/code-standards.md.tmpl` and `executable_rule-gate.py` exist).
- Commits:
  - `f712b4a5 dx(rules): load and tighten code quality rules`
  - `f9cfb60a dx(agents): tighten verify, ship, and fix steps`
  - `8e376208 dx(claude): gate edits until path rules are read`
  - `6ee5949f fix(claude): stop rule-gate hangs and state loss`
  - `8d85aee4 fix(claude): deny every same-batch edit of a file`
  - `a19316a5 refactor(claude): drop rule-gate record snapshot`
  - `627bdeda docs(claude): note rule-gate deny after interrupt`
  - `720906f9 fix(claude): run hooks on Python 3.9`
  - `58bcc745 ci: run hook tests on Python 3.9`
- Sources:
  - [Claude Code memory docs](https://code.claude.com/docs/en/memory.md) — `paths` frontmatter scopes a rule to matching files; user-level rules; a symlink target outside the working dir is an external import (grep of the .md).
  - [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) — `skills:` frontmatter injects the full skill content (first 32 names), not linked reference files. "Hooks from settings files ... also apply inside subagents ... a PreToolUse hook in settings.json also runs before every tool a subagent uses".
  - [Claude Code skills](https://code.claude.com/docs/en/skills) — no documented way to force-load a skill in the main session; `paths` loads a skill only "when working with files matching".
  - [Claude Code hooks](https://code.claude.com/docs/en/hooks) — PreToolUse `additionalContext` is delivered "in a system reminder"; `agent_id`/`agent_type` present in sub-agent hook input; PostToolBatch fires once per batch with `tool_calls`, no `agent_id` field listed (fetched 2026-11-06 for the rule-gate fix).
  - [Python tutorial, Compiled Python files](https://docs.python.org/3/tutorial/modules.html) — "it always recompiles and does not store the result for the module that's loaded directly from the command line" (hook scripts run directly are recompiled each run).
- Evidence: docs fetched and quoted by sub-agents. The primary evidence is local: a defect taxonomy built from reviewer reports, MR threads and CI failures across about 2,000 classified rows, plus loading probes on Claude Code 2.1.296 (see ab-tests.md, "Rule-loading probes"). Session 2697176b (2026-11-05 to 06, hive; user: "look into code quality and bug issues ... find out if we can improve the situation with rule tweaks").

### Review-driven code and comment rules (2026-11-05)
- Change: 6c059466 bans slop comments and needless tests; 6e11c86d adds review-driven code rules (code-quality.md, comments.md); 7bd40559 makes review check added comments against the comment rules.
- Status: current as of the session; not re-checked. code-quality.md became a link to a shared reference in the 11-05 skill pass.
- Commits:
  - `6e11c86d dx(code-standards): add review-driven code rules`
  - `6c059466 dx(code-standards): ban slop comments and needless tests`
  - `7bd40559 dx(review): check added comments against the comment rules`
- Sources: none external. The evidence is the review comments on an internal GitLab MR (hive !1167, excluded host).
- Evidence: no web source. Session bee21a8b (2026-11-05, hive; user: "look at comments for ... merge_requests/1167 ... anything to add to my global rules to prevent comments like this?") produced 6e11c86d. The session for 6c059466 was not identified.

### Run verification checks without asking (2026-11-05)
- Change: main rule line "run verification checks without asking".
- Status: current as of the session; not re-checked.
- Commits:
  - `b0a320cf dx(agents): run verification checks without asking`
- Sources:
  - [Claude Code issue #102653](https://github.com/anthropics/claude-code/issues/102653) — mod hook `prompt.attachment` bypassed by `cc-plugin-sec-default` (the context-lean bug); still open.
  - [Claude Code CHANGELOG](https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md) — no entry fixing it.
- Evidence: weak. The sources were cited for the context-lean question, not for this rule, and no source backs the rule. The rule was committed by `/dotfiles-sync` at the end of session 0fa0754d (2026-11-05, hive), whose task was checking whether the context-lean bug is fixed. The assistant also tested 2.1.318: "Confirmed: the bug is still there".

### Best-practices pass: two failed fixes then /clear, compaction note, code-intelligence plugins (2026-10-18)
- Change: ff6e4303 replaced "after three still-broken turns ask a question" with a two-tries-then-suggest-`/clear`-plus-rewritten-prompt rule, added a compaction rule (keep changed files, check commands, scratch paths), and dropped two duplicate lines. 4a1b8bfc enabled TypeScript/Python/Rust LSP plugins (the settings script had been resetting them) and installs `typescript-language-server`.
- Status: current as of the session; the `/clear` and compaction wording was not re-checked. Plugin enablement is a settings-script change.
- Commits:
  - `ff6e4303 dx(agents): apply claude code best practices`
  - `4a1b8bfc build(claude): enable code intelligence plugins`
  - `9da0e3d0 dx(agents): tighten waiting and handoff rules` (same session, not attributed to the guide)
- Sources:
  - [Claude Code best practices](https://code.claude.com/docs/en/best-practices) — after two failed corrections `/clear` and write a better prompt; add a compaction instruction; keep CLAUDE.md short; use code-intelligence plugins; manual-only for side-effect skills.
  - [Claude Code code-intelligence plugins](https://code.claude.com/docs/en/plugins/code-intelligence) — LSP plugins give type errors after each edit and symbol lookup.
  - [Claude Code skills](https://code.claude.com/docs/en/skills) and [sub-agents](https://code.claude.com/docs/en/sub-agents) — compared, no change. The assistant: "Unverified: the docs don't say whether a forked skill's text also stays in the main session".
  - [typescript-go lsp server source](https://raw.githubusercontent.com/microsoft/typescript-go/main/internal/lsp/server.go) — used for the follow-on TypeScript 7 diagnostics commits (1856cb43, 5959849, 54dd018, e89a26e), not for a rule.
- Evidence: doc fetched (best-practices read by a sub-agent) and cited in the reply ("The guide says after two, /clear and rewrite the prompt"). Gaps 1-5 in the reply were compared against live settings. Session bd2695fc (2026-10-18; user: "do we follow https://code.claude.com/docs/en/best-practices?").

### LSP-first lookup rule and LSP plugin enablement (2026-10-15)
- Change: after an A/B (3 runs per setup, tracing a shared-name `publish` method in the vitrine repo), the session enabled LSP plugins, added the LSP tool to explorer/worker/consult/tester roles, and set the rule: "For a named symbol's references or definition, use LSP first when available, loading it if deferred; otherwise ... `ast-grep` ... `rg -n`". Language servers were installed through mise plus a TypeScript 7 wrapper `typescript-language-server`.
- Status: replaced. 19187158 (10-16) removed the "use LSP first" wording and the LSP install script. 4a1b8bfc (10-18) re-added plugin enablement with a TS7 wrapper ("The settings script reset enabledPlugins on every apply, so the installed LSP plugins stayed off"). Current search.md has no "use LSP first" sentence.
- Commits:
  - `de2327e5 feat(lsp): enable Claude Code LSP plugins and servers`
  - `ed25d9dd dx(agents): use LSP first for symbol lookups`
  - `78752a06 dx(agents): give reviewer the LSP tool`
  - `19187158 dx(agents): replace lsp with code graph tooling`
  - `4a1b8bfc build(claude): enable code intelligence plugins`
- Sources: no web sources as support. A sub-agent WebFetch of code.claude.com settings and tools-reference docs established that the LSP tool exists and that `ENABLE_LSP_TOOL` is not documented (the session first claimed it, then retracted). The local A/B is in [ab-tests.md](ab-tests.md).
- Evidence: small local A/B, self-labelled "direction only", "unverified: 3 runs each, within noise". Session bc200b0a (2026-10-14).

### Copy output via `/copy` (2026-10-13)
- Change: copyable-output rule: put each copyable item in its own code block, keep it in the final reply, end Claude Code replies with "Run `/copy`". Codex keeps copy-file steps.
- Status: current as of the session; the shared copyable-output reference was not re-checked.
- Commits:
  - `3daf877f dx(agents): copy via /copy instead of copy files` (committed later than the session by another sync)
- Sources:
  - [Claude Code interactive mode](https://code.claude.com/docs/en/interactive-mode) — keybindings; `/copy` copies the last reply with a picker for code blocks.
  - [Codex CLI slash commands](https://developers.openai.com/codex/cli/slash-commands) — Codex `/copy` has no code-block picker, so the rule is Claude-only.
  - [Codex TUI shortcuts (third party)](https://codex.danielvaughan.com/2026/04/08/codex-cli-tui-shortcuts-slash-commands/) and [potato-ai.xyz](https://potato-ai.xyz/codex-cli-copy-last-response-first-use/) — Codex copy behavior.
- Evidence: cited in the reply; "None of the sources I found mention a picker" for Codex. A reviewer found 5 wording problems, all fixed. Session 20d262f0 (2026-10-13).

### Main-session rules moved into a custom output style (2026-10-12)
- Change: main-session-only rules moved out of the shared AGENTS.md into `~/.claude/output-styles/main.md` (`keep-coding-instructions: true`), and role bodies are shared across Claude and Codex.
- Status: current (`home/dot_claude/output-styles/main.md.tmpl` exists).
- Commits:
  - `0248759e dx(agents): move main-session rules to output style`
  - `700218a6 dx(agents): share role bodies across claude and codex`
- Sources:
  - [Claude Code output styles](https://code.claude.com/docs/en/output-styles) — a custom output style sets role and tone for a whole session. The assistant concluded: "Output styles reach the main session and forks, but not other sub-agents".
  - [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) — sub-agents skip CLAUDE.md (`omitClaudeMd`).
  - [Codex config reference](https://learn.chatgpt.com/docs/config-file/config-reference) (also under developers.openai.com/codex/...) — `developer_instructions`. "Every role file must set its own, which replaces the main one (per the docs; I haven't tested it)".
- Evidence: cited in the reply with an explicit "haven't tested" for the Codex half. Session d1531dd8 (2026-10-12, borg; `/llm-setup-audit`, then "can we add a file that only the main session reads?").

## Settings, permissions and security

### Agent summary suppression via BUN_OPTIONS preload (2026-10-29)
- Change: `no-agent-summary.js` is preloaded through `BUN_OPTIONS` in fish and sh env, with guards for HOME with spaces and Bun-unparseable paths. Rejected alternatives: `CLAUDE_CODE_FORK_SUBAGENT=0` (removes the fork agent, may not stop all summaries) and `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`.
- Status: current (`home/private_dot_local/share/no-agent-summary.js` exists and `env.sh` still documents the `BUN_OPTIONS` preload).
- Commits:
  - `23fc8b60 dx(claude): cut agent summary token use`
  - `5b93ea28 fix(fish): keep one preload when HOME has spaces`
  - `349f0b6e fix(shell): skip preload paths Bun cannot parse`
- Sources:
  - [flamerix-ai gist](https://gist.github.com/flamerix-ai/c3905705cc4205e5de3011fa2e74efce) — the preload script and a claim of 15-20% savings. The savings figure was not verified ("these calls aren't saved in session logs").
  - [Anthropic Consumer Terms](https://www.anthropic.com/legal/consumer-terms) — §3 no reverse engineering or "bypassing any of our systems or protective measures"; the assistant read the script as doing neither.
  - [Anthropic Commercial Terms](https://www.anthropic.com/legal/commercial-terms) — D.4 "reverse engineer or duplicate the Services".
  - [Claude Code legal and compliance](https://code.claude.com/docs/en/legal-and-compliance) — the rule that the Claude Code binary must not be modified applies to companies embedding it.
  - [Bun zig-clap source](https://raw.githubusercontent.com/oven-sh/bun/bun-v1.3.3/src/deps/zig-clap/clap.zig) and [cli.zig](https://raw.githubusercontent.com/oven-sh/bun/bun-v1.3.3/src/cli.zig) — used for the Bun argument-parsing bug (`bun init`, `bun info`, `bun upgrade` misread args under the preload); fixes in 5b93ea28 and 349f0b6e.
- Evidence: terms cited in the reply with "This is not legal advice"; ToS risk "low in my reading". The preload was tested on macOS after install; Bun was not installed, so the space-in-path case was never run. Session 77d6ff05 (2026-10-29).

### Pin Claude Code 2.1.296 so context-lean hooks run (2026-10-27)
- Change: Claude Code installs are pinned at 2.1.296 (from 2.1.299 the context-lean hooks stop working).
- Status: current (a "Keep Claude Code on 2.1.296" comment is in `1-env.fish` and `env.sh`). Re-checked on 2.1.318 on 2026-11-05: still broken, no change.
- Commits:
  - `3c765545 build(claude): pin 2.1.296 so context-lean hooks run`
  - `53605426 fix(shell): pin claude code installs to 2.1.296`
- Sources:
  - [Claude Code issue #102653](https://github.com/anthropics/claude-code/issues/102653) — still open.
  - [Claude Code CHANGELOG](https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md) — "changelogs for 2.1.302 through 2.1.311 contain no fix".
- Evidence: cited in the reply, plus a test of 2.1.308 and 2.1.311 against the 2.1.296 baseline (Haiku-run test). Sessions ac897b20 (2026-10-27) and 0fa0754d (2026-11-05).

### Prompt-cache TTL, credential-read denies, no blanket Bash/Task allows, cold-cache hook (2026-10-14)
- Change: `promptCacheTtl: "1h"`; `Read` denies for ~/.netrc, ~/.ssh, glab/gh/aws config; removed blanket `Bash`/`Task` allows; auto-mode environment labels; a SessionStart hook warning about a cold cache on resume; statusline cache-expiry display.
- Status: current (`"promptCacheTtl": "1h"` in `claude-settings-modify.sh`; `executable_cold-cache-warn.sh` exists).
- Commits:
  - `fe42308a dx(claude): force 1h cache, deny credential reads`
  - `c2ea58e0 dx(statusline): show prompt cache expiry, drop last-message time`
  - `5151ac26 dx(commit): inject git snapshot at skill load` (same session, not attributed)
- Sources: about 45 Claude Code doc pages fetched by sub-agents (settings, settings-reference, env-vars, prompt-caching, statusline, permission-modes, hooks, sub-agents and others) and the Claude Code CHANGELOG. Per-claim attribution was not kept.
- Evidence: claimed from docs plus binary inspection ("promptCacheTtl 1h ... Verified in binary", "Statusline prompt_cache field ... Verified in binary"); no quotes in the reply. The user replied "dont do 1/2. idlecompact in tandem with keepalive. do others", declining items 1 and 2. Session 7e8db009 (2026-10-14; `/open-ended` "are there any claude code features im not using but should be", 5 rounds, 48 features found).

### Setup audit against current Claude Code and Codex docs: sandbox, auto mode, Codex guard (2026-10-13)
- Change: global Claude sandbox turned off, blanket `Bash`/`Task` allows and narrow merge/approve allows removed so the auto-mode classifier sees them, and an `autoMode` rule restoring auto-merge after push. A Codex force-push guard hook; Codex `web_search = "cached"`; session logs chmod 600. Earlier (Oct 12) the read-only allow rules and a sandbox with auto-allow were added (f8b0eb32, 8ee8f585, session 67edba11) and then reversed by this audit.
- Status: current. `"sandbox": {"enabled": false}` is in `claude-settings-modify.sh` (checked).
- Commits:
  - `91ef45c3 security(claude): route merges and approvals through auto mode`
  - `d67738e3 security(claude): route merges and approvals through auto mode` (same subject as 91ef45c3)
  - `ac18047a security(codex): deny force pushes the rules cannot prompt`
  - `1c69eb92 security(codex): use cached web search under full access`
  - `f8b0eb32 dx(claude): allow common read-only commands`
  - `8ee8f585 dx(claude): route outward commands to auto mode`
- Sources (session bd76000a, fetched by audit sub-agents; per-claim quotes not preserved):
  - [Claude Code settings](https://code.claude.com/docs/en/settings), [permissions](https://code.claude.com/docs/en/permissions), [permission modes](https://code.claude.com/docs/en/permission-modes), [sandboxing](https://code.claude.com/docs/en/sandboxing) — blanket `Bash` allow rules are ignored in auto mode and skip checks outside it; narrow allow rules bypass the auto-mode classifier; `autoMode.classifyAllShell` (a managed-settings table shows it "honored even when a managed source sets false").
  - [Codex config reference](https://developers.openai.com/codex/config-reference), [agent approvals and security](https://developers.openai.com/codex/agent-approvals-security), [config reference (learn.chatgpt.com)](https://learn.chatgpt.com/docs/config-file/config-reference) — `web_search` defaults to live under full access; `sandbox_mode = "read-only"` in agent files is ignored (agents get the parent's access).
  - [tree-sitter-bash node types](https://raw.githubusercontent.com/tree-sitter/tree-sitter-bash/master/src/node-types.json) — used to write the Codex force-push guard (later rewritten to avoid shell parsing).
- Sources (session 67edba11):
  - [Claude Code sandboxing (docs.anthropic.com)](https://docs.anthropic.com/en/docs/claude-code/sandboxing) — built-in sandbox with auto-allow removes most prompts on macOS.
  - [Claude Code dev container](https://docs.anthropic.com/en/docs/claude-code/devcontainer) — reference container with a network firewall.
- Evidence: bd76000a was audit style with sub-agent doc reads, an 82-case guard test and two reviews (6 audit rounds, 37 confirmed findings). The assistant stated one open point, "I didn't confirm how auto mode treats the bare Bash rule", which bd76000a later resolved. The sandbox decision was reversed within a day. Sessions bd76000a (2026-10-13/14) and 67edba11 (2026-10-12, borg; VM vs sandbox question and `/fewer-permission-prompts`).

### Codex rules file to prompt for merges, approvals and force pushes (2026-10-13)
- Change: a Codex `.rules` file prompts for merge, approve, force-push, `rm -rf` and Jira writes. The Codex approval policy changed from "never ask" to "ask when needed" so prompts are possible.
- Status: current (`home/dot_codex/rules/private_guard.rules` exists). The force-push guard was later reinforced by ac18047a.
- Commits:
  - `1bedc409 security(codex): prompt for merges and force pushes`
  - `ac18047a security(codex): deny force pushes the rules cannot prompt`
- Sources:
  - [Codex rules docs](https://developers.openai.com/codex/rules) (redirects to https://learn.chatgpt.com/docs/agent-configuration/rules) — `.rules` under `rules/` next to an active config layer; `prefix_rule(pattern, decision allow|prompt|forbidden)`; most restrictive wins; `bash -lc` is split only for plain `&&`/`||`/`;`/`|` chains, otherwise evaluated as one string.
  - [Codex source exec_policy.rs](https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/src/exec_policy.rs) — maps a rule `prompt` to an approval request.
- Evidence: docs fetched and quoted. The doc does not cover `approval_policy = "never"` with `prompt`, so exec_policy.rs was read to fill the gap. The assistant noted the rules matched on test commands. Session 16e40ee2 (2026-10-13; `/open-ended` "other things I should work on improving").

### Datadog MCP loaded only via `claude-dd` (2026-10-08)
- Change: removed the Datadog connector deny from settings; new fish `claude` and `claude-dd` functions added a per-session `--settings` deny.
- Status: removed. The fish functions and the defer-tools marketplace file were deleted in 71b04d5c.
- Commits:
  - `525098eb dx(claude): load datadog mcp only via claude-dd`
  - `71b04d5c Update .chezmoitemplates/claude-settings-modify.sh Remove .claude/local-mods/defer-tools/.claude-plugin/marketplace.json Remove .config/fish/functions/claude-dd.fish Remove .config/fish/functions/claude.fish`
- Sources:
  - [Claude Code managed MCP](https://code.claude.com/docs/en/managed-mcp.md) — deny lists from every source are combined, so a per-session deny can be added but one cannot be lifted.
  - [Claude Code settings](https://code.claude.com/docs/en/settings.md) — same.
- Evidence: cited in the reply ("the docs say deny lists from every source are combined"); the result was tested (Datadog shows connected under `claude-dd`). Session cf8d0588 (2026-10-08, web-player).

## Terminal and UI

### Statusline links, ports and agent rows (2026-10-16)
- Change: the statusline project name links to the repo; session IP and port block; usage links; agent name and activity in agent rows.
- Status: current (`executable_statusline-command.sh` exists). Minor UX, not a rule.
- Commits:
  - `bbf24743 dx(claude): show agent name and activity in agent rows`
  - `6db0af13 dx(claude): compact statusline and show session ip`
  - `f97640fb dx(claude): give each session its own port block`
- Sources:
  - [Claude Code statusline docs](https://code.claude.com/docs/en/statusline) — status line input has only the main session's model, context and transcript. The reply: "Per the docs ... Unverified: I checked the docs and changelog for 2.1.296, not the live input while you view a subagent".
  - [Ghostty copy_url_to_clipboard #4676 (mirror commit)](https://git.uoc.run.place/Applied-Software/ghostty/commit/5e8ce20e71eaf149949ec54e4897d65ab287d47d) — OSC 8 links and click behavior in Ghostty.
  - [OSC 8 copy fix #7491 (mirror commit)](https://git.uoc.run.place/Applied-Software/ghostty/commit/f599f8c867efb0e4d7bd21873d6415ad9e4f33aa) — OSC 8 links and click behavior in Ghostty.
- Evidence: cited in the reply. Sessions 46d4871f (2026-10-15) and e8cb296d (2026-10-16).

### Tmux hyperlink passthrough for Ghostty (2026-10-15)
- Change: the tmux config passes OSC 8 hyperlinks through in Ghostty so mouseover links work.
- Status: current as of the session; not re-checked.
- Commits:
  - `b0c8a1b8 fix(tmux): pass hyperlinks through in ghostty`
- Sources:
  - [tmux feature table (tty-features.c)](https://raw.githubusercontent.com/tmux/tmux/master/tty-features.c) — which terminals get the `hyperlinks` feature.
  - [Ghostty link hover with mouse reporting (mirror commit)](https://git.uoc.run.place/Applied-Software/ghostty/commit/318641f5a19699cfdace5dfe5afc3051fd681722) — hover works under mouse reporting only with the modifier.
  - [claudeissues.com #90026](https://claudeissues.com/issue/90026-feature-fullscreen-tui-show-hover-feedback-on-links) — fullscreen TUI link hover.
- Evidence: read from source and cited with a printf repro line in the reply. Session 0d03d739 (2026-10-15).

## Incidental doc use (the change was not driven by the source)

### tmux plugins installed on apply (2026-10-13)
- Change: tmux plugins are installed and updated on apply. The change itself is not doc-backed.
- Status: current as of the session; not re-checked.
- Commits:
  - `14786152 build(tmux): install and update plugins on apply`
- Sources:
  - [Claude Code fullscreen docs](https://code.claude.com/docs/en/fullscreen) — used only to diagnose scroll-to-bottom; the docs "don't cover mobile terminals".
- Evidence: incidental. Session c1cbdea2 (2026-10-13).

### BambooHR days to calendar out-of-office (2026-10-15)
- Change: a script feature syncs BambooHR days to calendar out-of-office. Not a rule.
- Status: current as of the session; not re-checked.
- Commits:
  - `55c2f931 feat(time-off): sync BambooHR days to calendar out-of-office`
- Sources:
  - [Google Calendar API, event types](https://developers.google.com/workspace/calendar/api/guides/event-types) — out-of-office event type. A calendar-status guide and a Slack help article on out-of-office were also read; their URLs were not preserved.
- Evidence: a probe showed Google's servers can read the BambooHR feed. Session 71a657ca (2026-10-15).

### Rule trims driven by a local audit (2026-10-13)
- Change: duplicate rules deduped and rare paths moved out; allows for retired tools dropped (LS, MultiEdit, NotebookRead were redundant under bare allows); deny rules for a disabled plugin dropped. See also the orchestrator context study.
- Status: current as of the session; not re-checked.
- Commits:
  - `5e950389 dx(agents): dedupe rules and move rare paths out`
  - `1f3461c4 dx(claude): drop allows for retired tools`
  - `94a473d1 dx(agents): trim rules and cap agent result size`
  - `7f68382c dx(claude): drop deny rules for a disabled plugin`
- Sources: Claude Code permission and settings docs were fetched (URLs not preserved), but the trims were driven by a local multi-round audit. The "retired tool allows" finding came from the audit ledger, not from a doc quote.
- Evidence: incidental. Sessions 15ffc530 and 66da602a (2026-10-13).

### Codex tester sandbox and log access (2026-10-21 to 10-27)
- Change: the Codex tester was first given write access for logs and caches; a read-only sandbox change was tried and reverted because "Codex ignores the sandbox setting in agent files", shown by local Codex logs.
- Status: replaced. d32fe99a was reverted by c9e0bbcc (10-21). c32dc76b (10-27) let the tester write logs and caches instead.
- Commits:
  - `d32fe99a dx(codex): let the tester write logs on macOS`
  - `c9e0bbcc Revert "dx(codex): let the tester write logs on macOS"`
  - `c32dc76b dx(codex): let the tester write logs and caches`
  - `3301fe10 dx(agents): cut duplicate rules and fix conflicts`
  - `727c4ce5 dx(review): prefer rg in reviewer search steps`
  - `2929fd0b dx(agents): restore the cheaper sonnet handoff`
  - `d2ba1443 dx(review): fix setup gaps and split tester steps`
  - `bd887691 dx(agents): fix skill steps found by setup audit`
- Sources:
  - [Codex sandboxing docs](https://learn.chatgpt.com/docs/sandboxing) — read-only "can inspect files, but can't edit files or run commands without approval"; the page is silent on sub-agents.
  - Codex protocol and spawn source and the Codex security docs were also fetched (session 446ca2ba and audit sessions 4b282477 and e0777840). The security docs page "doesn't answer your question".
- Evidence: the tester sandbox change was settled by a local test ("old read-only sandbox refused writes ... Operation not permitted"), so it is probe-backed. Sessions 7ed59b69 (2026-10-21), 446ca2ba, 4b282477, e0777840. The sha dbb88769 named in the notes does not exist and was removed. 3301fe10, 727c4ce5, 2929fd0b are audit-session commits from 446ca2ba.

## Not adopted
- Review misses (1602cbf2): DJ-style `.bots/review.yaml` per repo; skipping complexity, architecture and naming-taste categories from DJ's list; a per-repo never-flag list ([Anthropic claude-code-security-review](https://github.com/anthropics/claude-code-security-review)); several runs with merged findings ([SWR-Bench](https://arxiv.org/html/2509.01494v2)); a 1-10 confidence score; PR-Agent two-model ranker; Shippie/ai-codereviewer; the Google human review checklist; security-review's "don't run bash". The Sonnet+deep pairing was adopted then dropped after the 6-run experiment.
- 500k auto-compact (990ee95c): setting `autoCompactWindow` 500k (blocked, not done); a round 4 with a larger task. Sources: the Context Rot, Lost in the Middle, Complexity Trap and Anthropic context-engineering links listed above.
- Orchestrator study (acb7f610): proposal 5 (output-style "Show data in full" exception) and the rules flagged as conflicting needed the user's decision; D8 settings/hooks built then removed. Sources: [Claude Code hooks](https://code.claude.com/docs/en/hooks), [Claude Code workflows](https://code.claude.com/docs/en/workflows).
- Review loop (f9eb94ba): raising the cap to 4; looping until clean ("may never get clean"); removing `--loop`; model debate between reviewers ([Should we be going MAD?](https://proceedings.mlr.press/v235/smit24a.html), [controlled debate study](https://arxiv.org/pdf/2511.07784): studies do not support it).
- Light reviewer (bc200b0a): Sonnet xhigh/max as normal reviewer (A/B: 74% vs 91%); Opus high (80%); a "dismissed section" Sonnet prompt test (about $30, not run); topic checklists; per-file split reviews; narrowing size/type thresholds for a light tier; the light tier itself (removed). An unrequested gpt-6.1-sol review run was stopped by the user.
- 400k window (01c1e1f7): `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60` (removed because [#63186](https://github.com/anthropics/claude-code/issues/63186) and [#36381](https://github.com/anthropics/claude-code/issues/36381) suggest settings.json is ignored); global `CLAUDE_CODE_AUTO_COMPACT_WINDOW=300000` not added.
- 400k window (dda15a16): `worker` role to Haiku (rejected, judgment work); `autoCompactWindow` 500k (superseded by 400k); main session on Sonnet (left to the user).
- Agent summaries (77d6ff05): `CLAUDE_CODE_FORK_SUBAGENT=0` and `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` (not chosen); the 15-20% savings claim from the [flamerix-ai gist](https://gist.github.com/flamerix-ai/c3905705cc4205e5de3011fa2e74efce) was never verified.
- Reviewer benchmarks (c974856b, 2026-10-30): [AACR-Bench](https://arxiv.org/html/2601.19494v1), [CR-Bench](https://arxiv.org/html/2603.11078v1), [Sphinx](https://arxiv.org/pdf/2601.04252), Qodo PR-Review-Bench, CodeFuse-CR-Bench and MacroscopeBench were surveyed to benchmark Haiku vs Sonnet reviewers. "I only read search snippets, so everything below is unverified". No benchmark was run from them and no config change was made; the Haiku routing edits in that session rest on the A/B probes.
- Disk cleanup tools (ecfe1795, 2026-10-12): `tonz` ([github.com/axect/tonz](https://github.com/axect/tonz)) and `disky` ([docs.rs/crate/disky](https://docs.rs/crate/disky/latest)) were added then removed before commit 02e043ba as untested.
- Codex tester read-only sandbox (7ed59b69): reverted, see "Codex tester sandbox and log access".
- Prompt-cache and settings (7e8db009): items 1 and 2 (`autoCompactWindow` for Opus, narrow WebFetch allow) declined by the user ("dont do 1/2"); item 6 (idleCompaction vs keepalive) was left ambiguous.
- Setup audit (bd76000a): CC-2 (narrow sandbox domains) and C1 (enforce Codex read-only) not fixed; the sandbox was turned off instead.
