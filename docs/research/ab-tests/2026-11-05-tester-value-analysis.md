# Tester value analysis, 203 historical tester runs

- Date: 2026-11-05  Sessions: 7d274c5f (2026-11-05 19:09-19:38 UTC, work repo)  Raw data: `~/.cache/agents/output/tester-value/result1..6.md`, `chunk1..6.txt`, `finals.txt`, `flagged.txt`, `last.txt`, `metas.txt` survive (checked with `test -e`)
- Related: [tester on Haiku vs Sonnet](2026-11-03-tester-haiku-vs-sonnet.md) (the tester model, chosen two days earlier), [rule-loading probes](2026-11-05-rule-loading-probes.md) (same day, other evidence analysis)

## Question
Does the tester find worthwhile issues? This is an evidence analysis, not an A/B.

## Setup
Final reports of 203 tester runs since mid-October were pulled. 176 reports that mention a failure or open question were sorted by 6 helpers into real, minor, setup-or-flaky, and false alarm. The user opened with: "has the tester in my workflow actually find worth-while issues?"

## Results
- Real bug in the change: 41 runs (20%). About 5 were deliberately broken toy code, so about 36 were real work.
- Small nit: 24 (12%).
- Setup, flaky or already broken: 27 (13%).
- All passed: 107 (53%).
- False alarm: 1. No final report: 3.
- After a challenge, "setup" runs were reclassified: only 3 of 27 checked nothing.
- Setup causes: 10 agt process-detection tests failing in the sandbox (6 runs), Safari-only UI focus test (6), errors already on master (6), missing deps (4), Node 26 (2), machine load (2), tester's own watchers (1).
- Top catches: a UI focus bug with non-English labels (failed 8 of 8 cases), gzip stored under a brotli key, a release-script token visible in process args (the fix broke rollback lookup), a demo setting lost on reload, one MR's lint error and an always-failing test.
- Follow-up in the same session (final assistant messages): the 10 agt tests failed because of the machine's time zone, not the sandbox. A fix was already on main (commit `d2c1c9a` in the agt repo, Oct 25; not in the chezmoi repo, so not verified here). The assistant made no agt change. For a Safari-only UI test the user chose "whatever you recommend"; the assistant committed a skip that applies only when Safari's window is not focused (work-repo commit `c4cd6dbda` on a test branch, unpushed at session end, not verified here). The review of that fix caught that the first version skipped in every browser, which would have turned a scheduled CI job green.

## Validity
- Some "real" findings were reasoned from code, not reproduced.
- It did not check whether the reviewer would also have caught them.
- The 13% setup share was overstated at first, before the reclassification.
- Classification was by agents reading final reports, with no human spot-check recorded.

## Decision
The tester was kept. Fixing the two repeat noise sources (agt process tests, Safari-only UI test) was offered as options 1-5 and then done as described above. No tester role or rule change came from this session: no commit in this repo cites it (searched `git log` for the session id and "tester value").

## History
- 2026-10-21 — `f0943031 dx(review): test with a tester before review`. The tester step the analysis later measured.
- 2026-10-27 — `d2ba1443 dx(review): fix setup gaps and split tester steps`.
- 2026-11-01 — `0d544939 dx(agents): give tester an oracle and bounded coverage`. Related and earlier. Edits `tester-steps.md`, `testing.md` and the shared tester body.
- 2026-11-03 — `23539612 dx(agents): run tester on haiku after probes` (see the Haiku vs Sonnet test).
- 2026-11-05 — Analysis run in session 7d274c5f.
- 2026-11-06 — `f9cfb60a dx(agents): tighten verify, ship, and fix steps`. Edits `tester-steps.md`. Its message cites repeat review findings, not this analysis. Not stated as caused by it.
- Today: the tester role (`home/dot_config/exact_agents/exact_agents/tester.md.tmpl`) is `claude-haiku-5-5`, effort `high`, read-only (no Edit, Write, NotebookEdit, Agent). The `review` skill runs it before every review.
