# Skill descriptions and bodies tuned with Anthropic's skill-creator guide

- Status (2026-11-06): description work reverted; body trims current. `5ac0362f` restored the original descriptions, so listed descriptions match their pre-2026-11-04 text (checked for `commit`, which differs from `6240b6a6~1` only in its body). Body trims remain: `code-standards` (a mention of `code-quality.md` became a markdown link to `references/code-quality.md`, in `fa0991a5`), the CI-server skill, `ticket`, `ux-verify`, `device-test`, `open-ended`, `frontend-design`.
- Topic: Skills
- Related: [Path-loaded code-quality rules](2026-11-06-path-loaded-quality-rules.md), [Review-driven code and comment rules](2026-11-05-review-driven-code-rules.md)

## Change
20 skill descriptions got trigger contexts and several bodies were trimmed. The user then asked "is this worth doing? wont it be more tokens?", so descriptions were shortened and then restored. Net effect is 4 skills changed in a way the earlier note listed (its "code-quality.md is now a link" meant that one in-text mention became a link; the reference file itself is unchanged in place): `code-standards`, the CI-server skill, `ticket` (stale "as step 4 does" reworded), `ux-verify`. Descriptions are unchanged from before.

## History
- 2026-11-04 — session d6a0632d, user: "run anthropic skill-creator over my skills to improve". The assistant checked 31 skills against skill-creator's validator: 24 pass; 7 fail only on `effort` and `disable-model-invocation`, which are false alarms because the checker targets claude.ai uploads. It listed 5 options and the user chose "5" (fix missing descriptions plus review against the writing guide). It then found the 12 skills with no description in the session list are `name-only` on purpose (`skillOverrides` in `settings.json`), dropped option 1, and ran only option 2 in a background worker, e1a8a39d.
- 2026-11-04 — `6240b6a6 docs(skills): add trigger contexts to skill descriptions`: 20 descriptions changed by the worker.
- 2026-11-04 — `fa0991a5 dx(skills): trim redundant body text and link code-quality reference`: body trims in `code-standards`, `device-test`, `frontend-design`, the CI-server skill, `open-ended`, `ticket`, `ux-verify`.
- 2026-11-04 — `e34b4b20 docs(skills): drop misleading triggers from commit and explicit-only skills`: removes "Use when..." text from `commit`, `frontend-design`, `worktree-cleanup` descriptions.
- 2026-11-05 — user: "is this worth doing? wont it be more tokens?". The worker had reported that description text across the 20 changed skills grew from 2,191 to 3,217 characters, and that skills the model can invoke are listed every session.
- 2026-11-05 — `bdd83330 dx(skills): keep listed descriptions short`: shortened `commit`, `dotfiles-sync`, `sub-agents`, `ticket`, `worktree` descriptions.
- 2026-11-05 — user: "undo". `5ac0362f dx(skills): restore original skill descriptions`: 13 files restored.
- 2026-11-05 — user asked "what other changes happened?" and "is it better to have desicptions?"; the body trims were kept.
- Later, not part of this change: `90a5ffab dx(frontend-design): restore scope line the readme documents` (2026-11-05) and `2e854a41 dx(frontend-design): let agents invoke the skill themselves` (2026-11-06) edited the `frontend-design` header again.

## Results
No measurement of skill behavior; no test loop was run. The full loop was priced and not run: about 6 test runs per skill, about 300 `claude -p` runs for description tuning, about 9,000 runs for all 31 skills. Measured instead: description text grew about 1,000 characters (2,191 to 3,217) across the 20 changed skills, which led to the revert. The worker also left a list of questions: `commit` type map sends `refactor` to `chore` while its body says avoid `chore`; a possibly stale `device-test` step 5 line; vague "per the main rules" in `open-ended`; `pr-fix` refusing a described selection such as "approve my auto-merge PRs"; an about 200-word bullet in `code-standards`; overlap between `sub-agents` wake-time rules and `monitoring.md`. The assistant stated "unverified: this is probably Claude Code's size limit on the skill list" for the 12 hidden descriptions, and that later turned out to be the user's `name-only` override.

## Sources
- Anthropic skill-creator SKILL.md (local plugin file): `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/skill-creator/skills/skill-creator/SKILL.md`, sections "Write the SKILL.md", "Skill Writing Guide", "Writing Style", "How to think about improvements" — descriptions state what and when with trigger contexts; all "when to use" text belongs in the description, not the body; imperative body; progressive disclosure with read-when pointers.

## Evidence
A local file named in the task prompt, read by the worker. No web fetch. The guide's "pushy descriptions" advice was explicitly not followed, and the token-cost objection led to the revert. Session d6a0632d (2026-11-05 by the S note; commit times show 2026-11-04 23:11 to 2026-11-05 00:40 local, user asked "run anthropic skill-creator over my skills to improve"); work done by worker session e1a8a39d from a task prompt written by d6a0632d. 31 skills reviewed.
