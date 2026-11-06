# Pipeline probes: agent pipeline vs inline

- Date: 2026-10-23 to 2026-10-24  Sessions: abc9c8a3, 446ca2ba (re-read the results in a setup audit)  Raw data: 85 headless run transcripts survive as Claude project dirs named `*pipeline-probe*`; scratch dirs `pipeline-probe` and `pipeline-probe2` deleted, no summary under `~/.cache/agents/output/`

## Question
Cost and hidden-test score of delegating every step (implement, QA-fix loop, review-fix loop, docs, reader) to agents (pipeline) vs doing the work inline in the main session.

## Setup
- Fixtures built by sub-agents: todo app; medium task (5 files, 14 hidden tests plus 4); small 1-file fix; large 2,350-line app with a 31-file reference change and 63 secret tests; ambiguous-spec task; 18-file task with 34 tests.
- Claude `-p` runs through agent-probe, reported at n=1 then n=3 or 4.
- Cost from Claude's own cost total (includes sub-agents; the probe tool's columns undercount).
- Total spend about $100 for rounds 1-2, about $42 for round 3, about $10 for round 4.

## Results
- Medium task: inline $1.41 (n=3) vs pipeline $2.19 (n=4), all 14/14 (+55%). Opus vs Sonnet implementer $2.54 vs $2.19 (n=3).
- Small task: size gate chose inline 3 of 3, rules loaded still +18% ($1.28 vs $1.08); forced pipeline +76%.
- Decisions file: without it 3 of 3 fix agents changed protected design choices; with it 0 of 3.
- Reader pass: tester 3.3 of 4 planted doc bugs, cheap 3.0 of 4, under $0.10 each.
- Resume vs fresh fix agent: after 6.7 min idle resumed $0.02 vs fresh $0.04-0.06; after 65 min resumed $0.11 vs fresh $0.05.
- Docs-before-review $2.52 vs $2.19.
- QA reuse: review skipped retesting in 2 of 2.
- Large task (31 files): inline Opus $5.74 mean (61/63 x3). Pipeline Opus main $6.40 (+11%, 62/63). Pipeline Sonnet main $4.94 (-14%; $4.37 / -24% excluding one run that broke the rule). Handoff from Opus to a background Sonnet session $4.34 (-24%; 61, 63, 62 of 63).
- Exact-wording test: $2.20, 62/63; 2 live-wording bugs (double review in 3 of 4 runs, about $2 each; a shared scratch folder let two sessions edit one repo).
- Ambiguous spec: all 4 built without asking, safe default, 3 of 4 reported it.
- 18-file task, 15-file threshold: pre-fix $2.20 / $3.76 vs $2.94-3.34 inline. After fixes handoff $2.40 vs $3.15 inline (-24%), all 34/34; Sonnet skipped QA or review in 1 of 3.

## Validity
- 6 of the 9 first-round tests were n=1.
- A runner bug lost the Opus cost for 2 of 3 handoff runs (1 measured, $0.66).
- The first resume test was invalid (finding already handled); its "$0.17" resume cost was corrected to $0.02.
- Background sessions deleted their own cost files.

## Decision
Adopted: the decisions file, the doc reader pass (tester), and the large-task handoff (15+ files) to a background Sonnet orchestrator with a fresh mktemp dir and no second review. Rejected: the full pipeline and the size gate.

## Commits
- `9056caba dx(sub-agents): add decisions file and doc reader pass`
- `6b7d127e dx(sub-agents): hand large tasks to a sonnet orchestrator`
- `80af617b dx(sub-agents): fix handoff prompt, reader pass, review check`
- `b6fa8a6e dx(sub-agents): use the timing skip test after handoff`
- `b8a32ee7 dx(agents): orchestrate split work in worktrees`
- `3301fe10 dx(agents): cut duplicate rules and fix conflicts`
- `2929fd0b dx(agents): restore the cheaper sonnet handoff` (body: "one background Sonnet session cost 24% less than inline at 18 and 31 files")
- Follow-ups: see [main-session model and handoff](2026-10-25-main-model-and-handoff.md)
