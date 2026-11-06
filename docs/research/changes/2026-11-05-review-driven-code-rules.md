# Review-driven code and comment rules

- Status (2026-11-06): current. The rules live in `home/dot_config/exact_agents/exact_skills/exact_code-standards/exact_references/comments.md` and `code-quality.md`, and the review skill's `reviewer-steps.md` has "**Check added comments** against comments.md". All three were edited again on 2026-11-06 (see History). The shared `code-standards` reference is also loaded by path (see the path-loaded rules doc).
- Topic: Rules and instructions
- Related: [Path-loaded code-quality rules](2026-11-06-path-loaded-quality-rules.md), [Skill-creator tuning](2026-11-05-skill-creator-tuning.md), [Rule-loading probes](../ab-tests/2026-11-05-rule-loading-probes.md)

## Change
`6c059466` bans slop comments and needless tests. `6e11c86d` adds review-driven code rules (`code-quality.md`, `comments.md`). `7bd40559` makes review check added comments against the comment rules.

Rule wording added in `6c059466`: "Add a test only when it can fail for a defect the existing tests miss"; "Never write, in code or doc comments: why you added the item or how your caller uses it ...; a constant's justification with estimates ...; earlier behavior ('the old', 'previously', 'now', 'no longer'); or what the signature already shows"; match comment density in repos the user does not own; reread every added comment before each commit.

Added in `6e11c86d`: no `&&`/`and` to make a value conditional; make each argument's meaning clear at the call site (no `load(url, true, false)`); type data by its real shape; search history (`git log -S`) before re-adding a field, option, check or dependency; comments are 1-2 plain sentences, and before each commit list every comment the branch adds, diffed against the merge-base.

## History
- 2026-11-05 11:01 local — `6c059466 dx(code-standards): ban slop comments and needless tests`: adds the test-only-when-it-can-fail rule, comment bans and the reread-before-commit step to the `code-standards` skill and `comments.md`. The session was not identified; its time falls before session bee21a8b started.
- 2026-11-05 11:33 local — `7c42590c dx(code-standards): recheck all PR comments after review`: when a reviewer flags one comment, reread every comment the PR adds (rule line 11 of today's `comments.md`). Not in the original note; the session is not identified.
- 2026-11-05 13:40 to 14:50 local — session bee21a8b (hive). User: "look at comments for ... merge_requests/1167 and tell me what you think. Is there anything to add to my global rules to prevent comments like this?", then "add rules.", then "feels very specific to a language, consult opus xhigh on this". The Opus-level reviewer replied that C, D and E each prescribed a TypeScript remedy for a language-neutral principle, that A and F carried over but needed fixes, and that B's regex was broken in ways it reproduced.
- 2026-11-05 13:52 local — `6e11c86d dx(code-standards): add review-driven code rules`: the language-neutral version of the rules above.
- 2026-11-05 14:20 local — `7bd40559 dx(review): check added comments against the comment rules`: `reviewer-steps.md` lists every comment line a change adds and reports ones that fail the rules; directives tools read (shebangs, pragmas, license headers) are exempt.
- 2026-11-05 — `8706768f dx(agents): apply writing rules to commits and comments`: shared public-writing rules for commits, MR/PR text, review comments and code comments; related, not the same rule.
- 2026-11-06 — `f712b4a5 dx(rules): load and tighten code quality rules`: moves loading to a path-scoped rule; touches `code-quality.md` (see the path-loaded doc).
- 2026-11-06 — `2375c578 dx(agents): add tests only where they catch bugs`: "Recent rules asked for a test per case, table row, branch, and fixed site. Reviews flagged only missing tests. Agents wrote tests for things that did not need them." The test rule from `6c059466` now reads "a defect that matters to a caller" in `tests-and-lint.md`.
- 2026-11-06 — `b55b8a1c dx(code-standards): make code easier to read`: adds a Readability section, bans mode flags in shared code, requires comments where a reader would misread the code; reviews flag missing required comments.
- 2026-11-06 — `daaa939f dx(code-standards): match doc example to its rule`, `411191b2 dx(agents): clarify flag and comment rules` (ban only flags that switch shared code between two jobs; a reviewer may suggest a clearer name instead of a comment).

## Results
No measurement. Known instead: the evidence was the review comments on one internal GitLab MR (hive !1167, excluded host). In session bee21a8b the assistant dropped one reviewer comment as wrong ("the new test in `embed.test.js` only tests unchanged code"; the test guards a bug fixed earlier on the branch). The first draft of the rules was too TypeScript-specific, per the user's challenge and the Opus check, and was reworded in `6e11c86d`. The test rule from `6c059466` was tightened the next day because agents wrote tests that were not needed (`2375c578`). No re-measure of comment quality found.

## Sources
None external.

## Evidence
No web source. Session bee21a8b (2026-11-05, hive) produced `6e11c86d` and `7bd40559` by commit time (13:52 and 14:20 local fall inside the session's 13:40 to 14:50 local span). The session for `6c059466` was not identified (searched transcripts for the sha and subject).
