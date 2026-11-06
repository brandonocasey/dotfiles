# Pipeline probes: agent pipeline vs inline

- Date: 2026-10-23 to 2026-10-24  Sessions: abc9c8a3 (2026-10-23 04:42 to 2026-10-24 01:54 UTC), 446ca2ba (2026-10-24 21:25 to 2026-10-25 01:33 UTC, re-reads the results in a setup audit)  Raw data: 85 headless run transcripts survive as Claude project dirs named `*pipeline-probe*`. The scratch dirs `pipeline-probe` and `pipeline-probe2` are deleted and no summary under `~/.cache/agents/output/` was found.
- Related: [main-session model and handoff A/B](2026-10-25-main-model-and-handoff.md) (next test; tuned the 15-file rule), [orchestrator context study](../changes/2026-10-13-orchestrator-context-study.md)

## Question
Should the main session delegate every step (implement, QA-fix loop, review-fix loop, docs, reader) to agents? The user proposed: "doesnit make sense to always delegatevto agents from the main session? im thinking, implement agent, followed by qa agent -> fix agent loop, then review agent -> fix loop. then document agent -> review fix", then "verify all of this with agent probes before we commit to anything".

## Setup
- Fixtures built by sub-agents: todo app; medium task (5 files, 14 hidden tests plus 4); small 1-file fix; large 2,350-line app with a 31-file reference change and 63 secret tests; ambiguous-spec task; 18-file task with 34 tests.
- Claude `-p` runs through agent-probe, reported at n=1 then n=3 or 4.
- Total spend about $100 for rounds 1-2, plus about $42 round 3 and about $10 round 4.

## Results
- Calibration: Claude's own cost total includes sub-agents (probe tool columns undercount).
- Medium task: inline $1.41 (n=3) vs pipeline $2.19 (n=4), all 14/14 (+55%). Opus vs Sonnet implementer $2.54 vs $2.19 (n=3).
- Small task: the size gate chose inline 3 of 3, rules loaded still +18% ($1.28 vs $1.08), forced pipeline +76%.
- Decisions file: without it 3 of 3 fix agents changed protected design choices, with it 0 of 3.
- Reader pass: tester 3.3 of 4 planted doc bugs, cheap 3.0 of 4, under $0.10 each.
- Resume vs fresh fix agent: after 6.7 min idle resumed $0.02 vs fresh $0.04-0.06. After 65 min resumed $0.11 vs fresh $0.05 (cache warm at 6.7 min, cold at 65).
- Docs-before-review $2.52 vs $2.19.
- QA reuse: review skipped retesting in 2 of 2.
- Large task (31 files): inline Opus $5.74 mean (61/63 x3). Pipeline Opus main $6.40 (+11%, 62/63). Pipeline Sonnet main $4.94 (-14%; $4.37 / -24% excluding one run that broke the rule). Handoff from Opus to a background Sonnet session $4.34 (-24%; 61, 63, 62 of 63).
- Exact-wording test: $2.20, 62/63, but 2 live-wording bugs (double review in 3 of 4 runs, about $2 each; a shared scratch folder let two sessions edit one repo).
- Ambiguous spec: all 4 built without asking, safe default, 3 of 4 reported it.
- 18-file task, 15-file threshold: pre-fix $2.20 / $3.76 vs $2.94-3.34 inline. After fixes handoff $2.40 vs $3.15 inline (-24%), all 34/34, Sonnet skipped QA or review in 1 of 3.

## Validity
- 6 of the 9 first-round tests were n=1.
- A runner bug lost the Opus cost for 2 of 3 handoff runs (1 measured, $0.66).
- The first resume test was invalid (finding already handled). The "$0.17" resume cost was corrected to $0.02.
- Background sessions deleted their own cost files.

## Decision
Adopt only what proved value: the decisions file, the doc reader pass (tester), and the large-task handoff (15+ files) to a background Sonnet orchestrator with a fresh mktemp dir and no second review. Rejected the full pipeline and the size gate. On Oct 24 `pipeline.md` was removed in a refactor and the handoff was restored as an `orchestrate` mode citing these probes. In session 446ca2ba the user said "orchestrate should cover spliting off to a single task or whatever saved money" and "1 if thats what the ab test concluded".

## History
- 2026-10-23 19:56 EDT — `9056caba dx(sub-agents): add decisions file and doc reader pass`. Adds the `decisions.md` rule to `sub-agents/SKILL.md` (agent writes choices, why, what must not change; later fix agents get the path) and the tester reader pass to `write-docs` and `roles.md`.
- 2026-10-23 19:56 — `6b7d127e dx(sub-agents): hand large tasks to a sonnet orchestrator`. Adds `sub-agents/references/pipeline.md` and the 15-file line in `main-rules.md` and `when-to-run.md`.
- 2026-10-23 20:06 — `80af617b dx(sub-agents): fix handoff prompt, reader pass, review check`. Edits `pipeline.md`, `when-to-run.md` and `write-docs`. The message has no body; it likely addresses the live-wording bugs from the exact-wording test (not stated).
- 2026-10-23 20:10 — `b6fa8a6e dx(sub-agents): use the timing skip test after handoff`. Review after handoff uses the Timing skip test in `when-to-run.md`, `pipeline.md` and `write-docs` (the double-review bug is the likely reason; not stated in the message).
- 2026-10-24 17:19 EDT — `b8a32ee7 dx(agents): orchestrate split work in worktrees`. Deletes `pipeline.md` and `split-task`; adds the `orchestrate` skill.
- 2026-10-24 18:59 — `3301fe10 dx(agents): cut duplicate rules and fix conflicts`. Removes the stale "15 or more files: `sub-agents/references/pipeline.md`" line from `main-rules.md` (the setup audit in session 446ca2ba).
- 2026-10-24 19:00 — `2929fd0b dx(agents): restore the cheaper sonnet handoff`. Message: "one background Sonnet session cost 24% less than inline at 18 and 31 files". Adds `orchestrate/references/handoff.md` and the `main-rules.md` line.
- 2026-10-25 — Follow-up test and rule changes in [main-session model and handoff](2026-10-25-main-model-and-handoff.md): `62f15c64`, `1d31fa4c`, `1aa4319c`, `65e51bcb`, `3985f4bd`.
- Today: the decisions-file rule is in `sub-agents/SKILL.md` (now with check commands, rejected options and files left alone). The reader pass is in `write-docs/SKILL.md` and `roles.md`. The handoff is `orchestrate/references/handoff.md`, triggered by the `main-rules.md` 15-file line. The full pipeline and size gate do not exist.
