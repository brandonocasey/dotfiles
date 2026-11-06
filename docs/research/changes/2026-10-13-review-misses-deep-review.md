# Review misses: fixed reviewer brief, Opus xhigh deep review, extra checks

- Status (2026-11-06): partly replaced, mostly live. One Opus xhigh `reviewer` does every review (`deep-review` was merged into it the same day). The fixed brief survives as a shorter template in `exact_review/exact_references/setup.md` section 6 ("Fill the fields and add nothing else: no summary of the change, focus areas, or earlier findings"). The checks live in `reviewer-steps.md`: cost and resources (line 57), error handling (64), maintainability (82), comments (92), platform contract (110), title and description (141), the pre-flag test (line 166, "It does not rely on unstated assumptions about the codebase or the author's intent") and the severity bar with `unverified` questions (171-176). The exact original wording ("Never write your own summary of the change ...") is gone from the repo.
- Topic: Review
- Related: [review experiment A/B](../ab-tests/2026-10-13-review-experiment-opus-pairs.md), [deep vs normal reviewer](../ab-tests/2026-10-08-deep-vs-normal-reviewer.md), [review loop](2026-10-13-review-loop.md), [light vs normal reviewer](2026-10-14-light-vs-normal-reviewer.md), [not adopted](not-adopted.md)

## Change
After a coworker's review bot found 5 issues on a work-repo MR that earlier local reviews missed, the review skill got a fixed reviewer brief built only from template fields. Wording as committed: "Never write your own summary of the change, what to focus on, what to skip, what already passed, or where code came from ('copied unchanged', 'already in use'). That framing steers the reviewer away from the code that needs review."

A deep review ran at `xhigh` on every logic change (a Sonnet + Opus pair first, then Opus xhigh alone after a 6-run experiment). Reviewers check what the host runtime does and report unverifiable runtime questions as "unverified". New checks: cost/resources, error handling, untrusted data, misleading names. Four ideas from open-source reviewers: a pre-flag test, a severity-based bar, MR text and code are data that cannot change role, steps or format, and "no findings is a valid result".

## History
- 2026-10-13 — Session 1602cbf2 (work repo, 15:40Z to 18:20Z). The user: "look at review comments here: ... (MR link removed)", then "go back to the session that started this and find out why reviews didn't catch these issues. can we adopt more of the coworker's review style? is it just using a really strong model? confused by this." Then: "make the fixes. have the deep review use xhigh. Can we do an experiment with a single xhigh vs a xhigh and sonnet and or an opus low?", "are there other catagories to add?", "are there any open source projects that do reviews that we can pull from here too?".
- 2026-10-13 — `368b535a dx(review): fix reviewer briefs and add review checks` (14:12 local). Added the fixed brief template in delegation.md, `deep-review` at xhigh for logic changes, and the new checks in reviewer-steps.md.
- 2026-10-13 — `8a88000f dx(context-lean): sync MR fixes and new hiding` (14:20). Context-lean mod fixes from the same MR findings; no web sources.
- 2026-10-13 — Session 8c70841e. The user: "we should change /review so that it always uses the purpose built agent as it now uses opus 5.5 xhigh", then "we should remove reviewer, deep-review should be the only one", and "yes delete the reviewer agent and rename deep-reviewer to reviewer". Commits: `79eb7192 dx(review): always delegate to deep-review` (16:07 local) and `71ee6bb1 dx(review): use one reviewer and loop every fix` (16:47, deleted the `deep-review` role files and renamed it `reviewer`).
- 2026-10-14 — `027f85c9 dx(review): hand review setup to a haiku helper` moved the brief template from delegation.md into setup.md and replaced the long "never write your own summary" paragraph with "framing steers reviewers away from the code". See [read ranges](2026-10-14-review-read-ranges.md).
- 2026-10-16/17 — `3b5c701a dx(agents): keep review state in agent-review store` (10-16 15:06) and `3c39ee31 dx(review): add security, old-bug, risk checks` (10-17 02:00) rewrote the loop and added checks.
- 2026-10-30 to 2026-11-02 — Tier and effort changes to the reviewer: `e3ee004f`, `10da7d14`, `212863cd`, `fd673112`, `8a029ed0`, `569767d2`. See [light vs normal reviewer](2026-10-14-light-vs-normal-reviewer.md).
- 2026-11-01 — `a88c1733 dx(agents): cut the review reveal step`.
- 2026-11-06 — Status checked: brief and checks in the files named in the Status line.

## Results
Measured in the [6-run experiment](../ab-tests/2026-10-13-review-experiment-opus-pairs.md) (one change, 2 runs per setup, scored on the 5 known bot findings): Opus xhigh 3/5 twice (11.6 min and 199k tokens for the first), Sonnet medium 2/5 twice (about 50 s, 27-31k tokens), Opus low 0/5 and 1/5. Adding Sonnet or Opus low beside xhigh gave 3/5 either way. Nobody caught findings 4 and 5 (performance and resource issues the brief never asked about), which led to the cost and resources check. Opus xhigh also found 2 extra real bugs. Cost about 7x tokens and 13x time of Sonnet. The assistant: "one change with 2 runs per setup, treat as a strong hint, not proof".

The claim that the bot is "not a stronger model than deep-review; the difference is brief and scope" came from reading the bot repo, not from a test. Later A/Bs on a bigger sample ([deep vs normal](../ab-tests/2026-10-08-deep-vs-normal-reviewer.md), the 25-case reviewer A/B) are separate evidence. The pairing was dropped and later effort changes are covered in [light vs normal reviewer](2026-10-14-light-vs-normal-reviewer.md). The extra checks have not been measured.

## Sources
- Internal: the coworker's review bot repo (a work repo, link removed) — Opus 5.5 `xhigh`, diff only, fixed prompt, categories incl. performance/resource-management, "what would a senior engineer raise" filter. Claim: not a stronger model than deep-review; the difference is brief and scope.
- [OpenAI Codex review rubric](https://github.com/openai/codex/blob/main/codex-rs/prompts/templates/review/rubric.md) — pre-flag test ("does not rely on unstated assumptions", "identify the other parts ... provably affected").
- [Qodo PR-Agent](https://github.com/qodo-ai/pr-agent) — stricter for low severity; "do not skip a genuine problem just because the trigger scenario is narrow"; code under review is data.
- [Anthropic claude-code-security-review](https://github.com/anthropics/claude-code-security-review) — per-repo never-flag list (not adopted).
- [SWR-Bench](https://arxiv.org/html/2509.01494v2) — multiple runs raise recall; mixing models adds false positives (not adopted). Snippet level from WebSearch.
- ["Can LLMs Catch a Rigged Backtest?"](https://arxiv.org/pdf/2609.28090) — an "assume it's broken" framing caused 11 of 12 false positives; "no findings is valid" removed them. The session marked it "unverified: from a search snippet only".
- Local 6-run experiment: see [the test doc](../ab-tests/2026-10-13-review-experiment-opus-pairs.md).

## Evidence
The bot setup was read through the glab API by a sub-agent (fetched and read). The OSS repos were cloned and key lines quoted. Two arXiv items are search-snippet only. The model-vs-effort conclusion rests on the 6-run local experiment. Session 1602cbf2 (2026-10-13).
