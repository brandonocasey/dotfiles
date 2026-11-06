# Review comments on own MRs: auto-mode rule and review skill

- Status (2026-11-06): current. The auto-mode allow text is in `home/.chezmoitemplates/claude-settings-modify.sh` line 135 and has not changed since `1cc6cc7d`: "Review comments on MRs/PRs the user authored, during a review the user asked for in this session: post, reply, resolve, and reopen. Never on MRs/PRs others authored." The review skill (`exact_review/SKILL.md`, `exact_references/remote-comments.md`) still posts findings on own MRs/PRs, but the mechanics were rewritten several times after 2026-10-15.
- Topic: Review
- Related: [review loop](2026-10-13-review-loop.md), [light vs normal reviewer](2026-10-14-light-vs-normal-reviewer.md), [review misses](2026-10-13-review-misses-deep-review.md)

## Change
An auto-mode allow rule lets Claude post, reply to, resolve and reopen review comments on MRs/PRs the user authored, during a review the user asked for. The review skill posts signed review comments on own MRs/PRs and gates a second review on the first (skip when the same commit already has reviews). The simplification pass cut the auto-mode allow list to 8 entries; a follow-up restored the exceptions that the simplification had dropped.

Current skill wording (`remote-comments.md`, "Own MR/PR comments"): "Every review of an MR/PR authored by the authenticated user ... posts its findings, resolves fixed ones, and keeps the review summary current." Other MRs/PRs get comments only when the user asks, through `agt review publish --not-own --only <ids>`.

## History
- 2026-10-15 — Session 34dbf6d2. The user first asked for a rule that comments on an MR when it was review-fixed, with the model used, and that is considered before another review ("comment should be very simple"). Then: "we should actually always do this for all reviews. all self reviews should get merge request comments on the correct line. fixes should resolve them. we need to record model/harness/harness version and model version and effort in the review comment." Further turns covered token cost, avoiding context bleed to the second review, batching, and whether a cheap model should post the comments.
- 2026-10-15 — `23c9c88c dx(review): post signed review comments on own MRs` (22:43 local). Rewrote the review skill, added `remote-comments.md` rules for own MRs (an earlier `remote-comments.md` existed from 2026-09-12), and touched fix.md, loop.md, output.md, remote-target.md, reviewer-steps.md and setup.md.
- 2026-10-15 — Follow-ups the same evening: `8467b67e dx(review): fix comment anchors, publish, and replies` (22:56); `36ad23ba dx(review): name repo and gate skips on open items` (23:00); `84d805cd dx(review): reopen only review-marked threads` (23:02); `bcc05cf3 dx(review): keep own open findings and skip early` (23:13); `8601b7ef dx(review): let review-again bypass skip, count open threads` (23:16); `fd0ca2cc dx(review): fix skip override and open count` (23:16); `06823c91 dx(review): count open GitHub general findings` (23:18).
- 2026-10-15 — The user asked "can we simplify auto mode rules". The live settings were changed with a scratch script (`apply-automode.sh`) that the user ran three times, once per approved draft. Commit `1cc6cc7d dx(claude): simplify auto-mode rules` (23:26) merged the MR/PR and issue-tracker rules into one line and added the review-comments rule in its current wording; it also shortened the environment text to one line.
- 2026-10-15 — `2f1ff037 dx(claude): restore dropped auto-mode exceptions` (23:50). Put back the Trusted source control and internal domains labels in the environment line, the auto-merge re-enable exception, the `/llm-setup-audit` clause and the LAN-test wording. It did not touch the review-comments line.
- 2026-10-16 — `3b5c701a dx(agents): keep review state in agent-review store` (15:06) moved review state to the `agent-review` store; `6b54d1bf dx(agents): batch review store calls` (18:13); `cb54590b feat(review): agent-review 0.3.0 approvals, usage, rejected findings, fix commits only` (21:03).
- 2026-10-17 to 2026-10-29 — Tooling moves: `02bbe63d docs(skills): use agt subcommands in skills, rules and the allowlist`; `8369aed9 build(deps): pin agt 0.18.0 and update callers` (10-20); `3a77d9ec docs(review): describe the agt 0.22.0 post format` (10-23, finding title and footer, one summary per MR/PR); `afda8d1f build(deps): pin agt 0.26.0 for comment reviews` (10-26); `73bd7e57 build(deps): pin agt 0.27.0 for gitlab comments` (10-26); `34591586 dx(skills): update review and ticket rules` (10-29).
- 2026-11-01 to 2026-11-05 — `a88c1733 dx(agents): cut the review reveal step` and `7f72a632 dx(skills): fix audit findings in skills and roles` edited the same file.
- 2026-11-06 — Status checked in the repo: auto-mode rule unchanged; skill wording rewritten.

## Results
No measurement. What is known: the session said "Nothing has run on a real MR/PR yet; the posting commands come from the CLI help and API docs" and "I can't test [classifier recognition] without a live MR/PR". The many same-evening follow-up commits (anchors, publish, replies, skip override, open counts) fixed defects found right after the first version, which implies (inference) the first version had them. The review skill has since moved the posting to `agt review publish`, so the original `glab`/`gh` posting commands are no longer the path. No transcript of a complaint about the auto-mode rule was found (not searched exhaustively).

## Sources
- [Claude Code, configure auto mode](https://code.claude.com/docs/en/auto-mode-config) — `autoMode` environment/allow/deny; the classifier documents labels `Organization:`, `Trusted source control:`, `Trusted internal domains:`; deny and explicit ask rules run before the classifier.
- [Claude Code permission modes](https://code.claude.com/docs/en/permission-modes) — auto mode behavior.
- [GitLab draft notes API](https://docs.gitlab.com/api/draft_notes/) and [discussions API](https://docs.gitlab.com/api/discussions/) — posting and resolving threads.
- [GitHub REST, create a review for a pull request](https://docs.github.com/en/rest/pulls/reviews?apiVersion=2022-11-28#create-a-review-for-a-pull-request) — creating a review.

## Evidence
Docs fetched. Session 34dbf6d2 (2026-10-15/16). The reply said "Nothing has run on a real MR/PR yet; the posting commands come from the CLI help and API docs" and "I can't test [classifier recognition] without a live MR/PR".
