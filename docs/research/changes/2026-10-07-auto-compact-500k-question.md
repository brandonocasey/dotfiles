# Auto-compact at 500k: negatives, cost estimate and local benchmark

- Status (2026-11-06): never made. No `autoCompactWindow` of 500k was ever committed. The live setting is 433000 (`home/.chezmoitemplates/claude-settings-modify.sh`, set by a later change). The session's own settings edit was blocked and its report said "Your settings are unchanged".
- Topic: Context and compaction
- Related: [auto-compact 400k](2026-10-14-auto-compact-400k.md), [compact-bench test](../ab-tests/2026-10-07-compact-bench-500k.md), [not adopted](not-adopted.md)

## Change
None. The session answered "what are the negatives of auto-compact at ~500k", gathered studies and Anthropic guidance, estimated the cost saving, and ran a local A/B on web-player. Its attempt to set `autoCompactWindow` 500k in `~/.claude-two/settings.json` was blocked by the auto mode classifier (reason shown: Self-Modification), and the settings stayed as they were.

## History
- 2026-10-07 — Session 990ee95c (17:21Z to 21:57Z). The user asked about negatives, studies, Anthropic guidance, dollar savings ("12$ per session?"), and whether quality drops after a compact. Then: "is there any way that we can benchmark something like this locally ... you do it in the web-players repo with a big task. I want to compare cost, quality, and time taken. I want to make sure that we don't allow sessions to cheat off of one another."
- 2026-10-07 — Three rounds ran (see the [test doc](../ab-tests/2026-10-07-compact-bench-500k.md)). The user asked to "do round 3" and later "delete" the 13 GB of scratch copies.
- 2026-10-07 — Commits: none from this session. A search of `git log --grep=compact` found `a0a1ba46`, `2145d42a` and `ce9f9ea6`, which are the later 400k/433k commits with no link to this benchmark.
- 2026-10-14 — The 400k change was made in other sessions (01c1e1f7, dda15a16). See [auto-compact 400k](2026-10-14-auto-compact-400k.md).

## Results
The cost estimate in the session (Opus 5.5 API prices, one long session of 400 tool calls at about 5k new tokens each): about $57 at the default trigger (~835k) against about $45 at 500k, so roughly $10-15 saved, with the 835k default marked "unverified: third-party write-ups". The session later said this applies only to very long sessions: under about 90 calls (peak under 500k) the saving is $0; about 150 calls saves about $4-5; about 400 calls about $12. It corrected itself on the $12 figure: it assumed one context, and with helper agents sessions rarely get that big.

The local A/B is in [compact-bench](../ab-tests/2026-10-07-compact-bench-500k.md). In short: rounds 1 and 2 never reached 500k, so they tested nothing about compaction. Round 3 (helper agents off) cost $29.67 with 500k against $34.05 for the default, about 13% less, with 9 more minutes. It is n=1 per arm, so the saving could be noise. Total about $135 for 6 sessions. Quality was about equal. The session concluded that a 500k trigger would rarely fire in the user's normal setup, where main context peaked at 200-304k.

Problems seen: one default-arm session in round 2 wrote files outside its own copy (its partner never read them). The assistant deleted `~/.cache/agents/scratch/rv/` by mistake (6 files, about 830 KB, no backup).

## Sources
All WebSearch snippets, no WebFetch:
- [Context Rot (Chroma, 2025)](https://research.trychroma.com/context-rot) — all 18 models tested degrade as input grows.
- [Lost in the Middle (Liu et al., 2023)](https://arxiv.org/abs/2307.03172) — recall is best at the start and end of context.
- [The Complexity Trap (JetBrains, 2025)](https://arxiv.org/abs/2508.21433) — hiding old tool output matched LLM summaries on SWE-bench-style tasks, both at about half the cost. The session marked its recollection that summaries "matched or beat" untouched history as "unverified: I haven't rechecked".
- [Effective context engineering for AI agents (Anthropic)](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — attention budget and compaction guidance; no threshold recommended.
- [Effective harnesses for long-running agents (Anthropic)](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — progress files and git commits for fresh or compacted contexts.
- [Cookbook: automatic context compaction](https://platform.claude.com/cookbook/tool-use-automatic-context-compaction) — API threshold example; no recommended number.
- [claudeissues.com #63627](https://claudeissues.com/issue/63627-auto-compact-ignores-claude-autocompact-pct-override-on-1m-context-opus-no-compa) — `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` sometimes ignored on 1M models. The session marked it "unverified" and chose `autoCompactWindow` instead.
- [Claude pricing](https://platform.claude.com/docs/en/about-claude/pricing) — cost model for "$10-15 per long session". The session later corrected itself: "$12 per long session" assumed one context, and with helper agents sessions rarely get that big. The 835k default trigger was "unverified: third-party write-ups".

## Evidence
Web claims came from search snippets, and the session marked several unverified. Session 990ee95c (2026-10-07). The local A/B (6 sessions, about $135) is n=1 per arm. The session said that no study it found measures detail lost per compaction, and that the studies used older models.
