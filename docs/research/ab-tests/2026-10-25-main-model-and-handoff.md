# Main-session model and effort, and handoff A/B

- Date: 2026-10-25  Sessions: da2716d2 (2026-10-25 03:02-23:26 UTC)  Raw data: 102 headless run transcripts survive as Claude project dirs named `*main-model-ab*`. No results file found in `~/.cache/agents/output/`.
- Related: [pipeline vs inline](2026-10-23-pipeline-vs-inline.md) (the probes that introduced the 15-file handoff), [reruns review on/off](2026-10-29-reruns-review-on-off.md), [orchestrator context study](../changes/2026-10-13-orchestrator-context-study.md)

## Question
Sonnet or Opus (and which effort) as the main session, and orchestrate/handoff vs inline. The user asked: "i want you to ab test to fin out whether i should use sonnet or opus as my main session and what effort. i want to know about orchestrate vs inline too." and "are you testing with reviewer and qa testet?"

## Setup
- A stock app fixture with a question, a bug fix, a hard 2-bug task (22 hidden tests) and a 22-file feature (40 tests).
- Variants: Sonnet med/high and Opus low/med/high/xhigh.
- Pilot 20 runs, second round 15 hard plus 10 handoff runs.
- Real rules, so the QA tester and the Opus xhigh reviewer run.
- Cost about $104 (pilot $42, round 2 $62).

## Results
Cost for question / bug fix / hard bug / feature, and how often the full review ran:
- Sonnet med $0.10 / $0.64 / $0.17 / $1.58, review 2 of 11.
- Sonnet high $0.13 / $0.73 / $1.03 / $3.27, 6 of 8.
- Opus low $0.17 / $0.51 / $0.32 / $2.72, 1 of 8.
- Opus med $0.22 / $1.30 / $1.53 / $4.92, 11 of 11.
- Opus high $0.30 / $1.44 / - / $6.97, 2 of 2.
- Opus xhigh $0.41 / $2.12 / $2.52 / $7.66, 8 of 8.

Other results:
- All 54 coding runs passed every hidden test.
- Sonnet med skipped review in 7 of 11 runs, Opus low in 4 of 8. The QA tester was skipped in 3 of 14 pilot runs.
- Handoff vs inline: Opus med $4.92 inline vs $3.31 handoff (-33%). Sonnet med $1.58 vs $2.35 (+49%). All 6 handoffs 40/40.
- The 15-file rule never fired on its own in 2 free-choice runs (22 files).
- After the rule edit: the "count files first" rule handed off 3 of 3 feature runs (40/40) and 0 of 3 small fixes.
- A later guard-less version nested handoffs (3-21 nested sessions, $6.66 outlier, 51 min) and was reverted.
- With the guard (`AGENT_HANDOFF=1` blocks `claude -p`), 4 of 4 live runs handed off exactly once.

## Validity
- The first hard task leaked both bugs in a commit message (rebuilt; only rebuilt runs count).
- No task separated models on quality.
- 5 of 6 handoff costs are estimates (transcript pricing x1.25).
- Question and bug-fix cells are n=1.
- Some background sessions hit the usage limit.

## Decision
Keep Opus medium as the main session. Fix the handoff rule to fire (count files early). Block nested handoff sessions. Make handoff sessions record review. The user's follow-ups were "try 1" (fix the rule), "1" (add a re-check, then "1" skip it as tests showed it was not needed), "3" (push the undo, then build a mechanical guard and retry the rule) and "block? fix other issues".

## History
- 2026-10-23/24 — The 15-file handoff came from the pipeline probes (`6b7d127e`, `2929fd0b`, see [pipeline vs inline](2026-10-23-pipeline-vs-inline.md)).
- 2026-10-25 10:26 EDT — `62f15c64 dx(agents): count files early so handoff fires`. `main-rules.md` line "Before an implementation that will change 15 or more files: `orchestrate`" becomes "For an implementation request, first estimate the files it will change, counting tests and docs ... At 15 or more, load `orchestrate`".
- 2026-10-25 12:28 — `1d31fa4c revert(agents): undo handoff rule that nests`. Back to the old line, because the handoff session read the same rules and handed off again.
- 2026-10-25 12:38 — `1aa4319c dx(agents): block nested handoff sessions`. `bash-guard.py` denies `claude -p` when `AGENT_HANDOFF=1`; tests added; `handoff.md` sets the variable.
- 2026-10-25 12:38 — `65e51bcb dx(agents): count files early so handoff fires`. Reapplies the 62f15c64 wording, now safe with the guard.
- 2026-10-25 13:09 — `2e2e177a test(agents): cover a backgrounded nested handoff`. Adds a guard test case.
- 2026-10-25 14:20 — `3985f4bd fix(agents): make handoff sessions record review`. Stage 4 of `handoff.md` runs `review-fix` with its tester, reviewer and `agt review` records; the report includes `reviewed` and `unreviewed_commits`.
- 2026-10-25 14:48 — `b8a3a6ab fix(agents): catch more headless flag forms`. Ends a flag at any character that cannot continue its name, so `-p"x"` and `-p2>&1` still block in a handoff session. This matches the "missed flag forms" item of the last user turn.
- 2026-11-01 — `e4a6c07c dx(agents): stop loops on no progress, richer handoff` and `d33b4b01 fix(agents): stop handoff killing its reviewer`. Later handoff edits. Their messages do not cite this test, so no link is claimed. The "unexplained kills" item of the last user turn may match d33b4b01 by title only.
- Today: `home/.chezmoitemplates/main-rules.md` line 23 still starts "For an implementation request, first estimate the files it will change, counting tests and docs ... At 15 or more, load `orchestrate` and follow it." The `bash-guard.py` handoff guard and `orchestrate/references/handoff.md` are live. The main model is a user setting: the template default is `"model": "sonnet"` with `effortLevel` high and per-model `modelSettings` (Opus medium, Sonnet high, Haiku xhigh), all in `KEEP_KEYS`, so a user's live choice is kept. The live main model is not recorded in the repo.
