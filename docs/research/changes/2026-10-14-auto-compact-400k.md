# Auto-compact window: 400k for sub-agents, then all sessions

- Status (2026-11-06): changed. `home/.chezmoitemplates/claude-settings-modify.sh` line 142 sets `"autoCompactWindow": 433000` (checked). No agent file sets it. The 400k pick was "a reasoned pick, not a measured optimum".
- Topic: Context and compaction
- Related: [500k question](2026-10-07-auto-compact-500k-question.md), [compact-bench test](../ab-tests/2026-10-07-compact-bench-500k.md), [orchestrator context study](2026-10-13-orchestrator-context-study.md), [cache TTL and permission denies](2026-10-14-cache-ttl-and-permission-denies.md), [not adopted](not-adopted.md)

## Change
`autoCompactWindow: 400000` was added to the agent role files, then moved to one global `autoCompactWindow` in the managed Claude settings with the agent lines removed. The statusline context warning became relative to the window. A first try of `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60` was removed before commit.

Claude Code counts the window differently from the number set. It holds back 20k for output and a 13k buffer, so a window of `400000` compacted at 367k. The setting was raised to `433000` so compaction happens at 400k. The statusline and the context-lean `/context` report show 400k as the usable size.

## History
- 2026-10-14 — Session 01c1e1f7 asked whether agents auto-compact. A sub-agent read the docs and said yes. The user asked for 60%, then "3 undo it for everything" (the 60% override) and "400k cap for sub agents".
- 2026-10-14 — commit `77cc26cc dx(agents): compact subagents at 400k tokens`. Added `autoCompactWindow: 400000` to 7 role files (13:29 local). The session counted 8 roles; `light-reviewer` was not committed yet.
- 2026-10-14 — Session dda15a16 (main-session cost, studies, "let's try setting auto compact to 500k", "woul it be better at 450k?", "what's the sweet spot here?", then "ok set it to 400k"). Commit `a0a1ba46 dx(claude): auto-compact all sessions at 400k` (14:15) added a global `"autoCompactWindow": 400000` and removed the 7 agent lines.
- 2026-10-14 — Session 5821e33b (statusline). Commit `2e31908d dx(claude): warn relative to auto-compact window` (14:38) made the statusline warn against the window: yellow from 367k, red from 387k at first.
- 2026-10-14 — Same session. Commit `cb0c8a45 dx(claude): auto-compact at 400k, not 367k` (15:05) changed 400000 to 433000, because compaction fires 33k below the setting. The session then moved the statusline warnings to 380k and 400k and had context-lean report free space against 400k.
- 2026-10-14 — Related context-lean mod commits made `/context` match: `bb083771 fix(context-lean): size buffer from compact point`, `61c1bc4b feat(context-lean): cache token counts per model`, `09c62ead feat(context-lean): report /context in built-in style`.
- 2026-10-16 — commit `2145d42a dx(claude): trim output and compaction window` (16:32) changed 433000 to 200000 and added `BASH_MAX_OUTPUT_LENGTH=12000`, `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=1`, `LEFTHOOK_OUTPUT=failure,summary` and `NO_COLOR=1`. Deciding session not found (searched transcripts overlapping 16:32 local and the commit text).
- 2026-10-16 — commit `ce9f9ea6 dx(claude): keep the 433k compaction window` (16:36) put it back to 433000, four minutes later. The commit body is empty and no session was found. The other settings from 2145d42a stayed.
- 2026-10-20 — Neighbouring settings changed, window untouched: `907d4b39 dx(claude): default to sonnet high, halve bash output` set the default model to Sonnet and `BASH_MAX_OUTPUT_LENGTH` from 12000 to 6000.
- 2026-11-05 — `dab770cd dx(claude): turn on idle compaction setting` added `"idleCompaction": true` next to the window. The 433000 value was left as is.
- 2026-11-06 — Status checked: 433000 is still the live value.

## Results
No measurement of 400k or 433k against other windows. The pick came from studies and from the user's own transcripts, which showed 57% of cost came from calls over 200k context (about a third of all calls; a turn at 400k costs about 8x a turn at 50k).

The related local benchmark ([compact-bench](../ab-tests/2026-10-07-compact-bench-500k.md)) tested 500k, not 400k. Its first two rounds never reached 500k. In round 3, 500k cost $29.67 against $34.05 for the default, with one compaction, but it is n=1 and may be noise. Neither the benchmark nor any session ties it to the 400k pick.

Problems seen: the 400k setting compacted at 367k, which is why it became 433k. The `2145d42a` change to 200k lasted four minutes. The per-agent 400k was "not tested live"; the session said confirming it needs a sub-agent run past 400k, and the cap does nothing on a model whose window is 400k or smaller.

## Sources
- [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents.md) — sub-agents auto-compact on their own window; `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` applies to sub-agents; per-sub-agent `autoCompactWindow` frontmatter takes 100000 to 1000000 (since 2.1.296/2.1.299).
- [Claude Code env vars](https://code.claude.com/docs/en/env-vars.md) — `CLAUDE_CODE_AUTO_COMPACT_WINDOW` overrides the frontmatter value.
- [Claude Code CHANGELOG](https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md) — `autoCompactWindow` added in 2.1.296.
- [claude-code issue #63186](https://github.com/anthropics/claude-code/issues/63186) and [#36381](https://github.com/anthropics/claude-code/issues/36381) — `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` reportedly ignored when set in settings.json. This is why the 60% variant was dropped for the window setting.
- [CliffCompaction](https://arxiv.org/html/2609.26779) — up to 50% lower cost with bounded context; success held at moderate thresholds on Terminal-Bench.
- [Beyond Token Savings](https://arxiv.org/html/2609.32961v1) — fewer tokens does not always mean a lower bill; best method 0.71x cost, another lost 11 points.
- [LangWatch, The Context Tax](https://langwatch.ai/blog/context-tax-when-to-compact) and [Optimal Context Window](https://langwatch.ai/research/finding-the-optimal-context-window) — compact in the 250k to 450k range; corrections rise after a compaction. This was the basis for 400k.
- [SWE-Pruner](https://arxiv.org/pdf/2601.16746) — context pruning cuts cost.
- [Chroma Context Rot, W&B summary](https://wandb.ai/byyoung3/ml-news/reports/Chroma-Research-Warns-of-Context-Rot-as-LLMs-Falter-with-Long-Inputs--VmlldzoxMzczMjQ4MQ) — all 18 models degrade as input grows.
- [Compaction write-up (JetBrains figures, secondhand)](https://practiceoverflow.substack.com/p/compaction-the-hidden-trick-that) — hiding old tool output cut cost from $3.47 to $1.52 per task.
- [claudeissues.com #63627](https://claudeissues.com/issue/63627-auto-compact-ignores-claude-autocompact-pct-override-on-1m-context-opus-no-compa) — override ignored on 1M-context Opus.
- Local data: the user's own transcripts showed 57% of cost came from calls over 200k context.

## Evidence
- Session 01c1e1f7 (per-agent 400k) read the docs "from page summaries, not the raw docs text" and flagged that as unverified. The docs were fetched by a sub-agent through WebFetch extractions.
- Session dda15a16 (global 500k, then 400k) cited the papers from search summaries only: "I've only read the search summaries, not the full papers". Its note on `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` being ignored came from user bug reports, not a test.
- The 57% figure is local data from the user's transcripts (dda15a16).
- Session 01c1e1f7 also read the study ledger from the orchestrator context study (see [that doc](2026-10-13-orchestrator-context-study.md)).
- Session 5821e33b (the 433k correction) reasoned from the Claude Code binary and its `/context` code (window minus 20k output reserve minus a fixed buffer). The window math was reviewed by a sub-agent. No test against a long live session was found.
