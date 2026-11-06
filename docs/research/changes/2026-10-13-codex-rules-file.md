# Codex rules file to prompt for merges, approvals and force pushes

- Status (2026-11-06): current. `home/dot_codex/rules/private_guard.rules` holds `prefix_rule(... decision = "prompt")` entries for `gh pr merge`, `glab mr approve|merge`, `git push` with a force or mirror flag, `rm -rf`, `jira-api POST|PUT|DELETE` and `agt issue push` (also `agt issue --tracker`). `approval_policy = "on-request"` in `home/dot_codex/modify_private_config.toml.tmpl`. The Python force-push hook added to back it up was removed on 2026-10-19.
- Topic: Settings, permissions and security
- Related: [Setup audit: sandbox and auto mode](2026-10-13-setup-audit-sandbox-auto-mode.md), [Codex tester sandbox](2026-10-21-codex-tester-sandbox.md)

## Change
A Codex `.rules` file prompts before merges, approvals, force pushes, `rm -rf` and Jira writes. To make prompts possible, the Codex approval policy changed from `"never"` ("never ask") to `"on-request"` ("ask when needed"). The file header records the limits: rules match command prefixes only, with no globs and no "outside scratch" test for `rm`; `"never"` turns `prompt` into forbidden; flags after the remote, `+branch` and `--force-with-lease=<ref>` are not matched.

## History
- 2026-10-13 — session 16e40ee2: `/open-ended` "Alright i've worked on improving automatic reviews, orchestration, etc. are there other things I should work on improving look at previous sessions". The report listed "Codex runs with no approvals and full access" and offered a rules file. The assistant skipped the huge-context item and applied the rest. In review it found the first version of the Codex rules matched no commands at all and fixed that; a later "rules stopped matching" alarm was its own test's zsh quoting error, not a rule bug.
- 2026-10-13 — commit `1bedc409 security(codex): prompt for merges and force pushes`: adds `private_guard.rules`, changes `approval_policy` from `never` to `on-request`, bumps `@mozilla/firefox-devtools-mcp` to 0.10.1 and sets `JIRA_EMAIL` for Codex (same commit).
- 2026-10-13 — commit `ac18047a security(codex): deny force pushes the rules cannot prompt`: Python hook for the forms a prefix rule cannot match (part of the setup audit, see [setup audit](2026-10-13-setup-audit-sandbox-auto-mode.md)).
- 2026-10-16 — commit `d40c5370 fix(codex): omit prompt rules on yolo host`: made the rules a template that renders empty on host `bcasey-dev`, where `approval_policy` was set to `never` by `9e23b165 dx(agents): enable yolo only on bcasey-dev`.
- 2026-10-16 — commit `b8a43b67 revert(agents): restore local approval settings`: reverted both host-specific changes. The rules file went back to a plain file and `approval_policy` back to `on-request` for all hosts. The revert commit has no body; reason not found in the commit message (searched `git show`; session not identified).
- 2026-10-17 — commits `636bdd04 feat(skills): use agt issue in mr-ticket and review setup` and `758d414e fix(skills): harden agt issue wiring in mr-ticket and review setup`: add prompt rules for `agt issue push` and `agt issue --tracker ...`.
- 2026-10-17 — commit `9b89877b fix(codex): require approval for mirror pushes`: adds `--mirror` to the force-push rule.
- 2026-10-19 — commit `cf5cb999 dx(codex): drop force-push guard needing python`: the hook is gone; "Codex rules still prompt for git push with a force flag right after push; chained or late-flag force pushes now run unprompted." The rules file is now the only force-push control.

## Results
No measurement. What was checked: every `prefix_rule` carries `match` and `not_match` example commands; the assistant checked that the rules fire on test commands ("The rules work. My earlier check was wrong: zsh passes an unquoted variable as one word"). No test of a real Codex prompt in a live session was found. The docs do not cover `approval_policy = "never"` with `prompt`, so `exec_policy.rs` was read: a rule `prompt` becomes an approval request, which needs a policy that can ask.

Known gaps recorded in the file and in later commits: flags after the remote, `+branch`, `--force-with-lease=<ref>`, chained commands and late flags are not matched; `bash -lc` is split only for plain `&&`, `||`, `;` and `|` chains, otherwise evaluated as one string. Hosts that need `approval_policy = "never"` cannot use the prompt rules (the 10-16 attempt to special-case a yolo host was reverted).

## Sources
- [Codex rules docs](https://developers.openai.com/codex/rules) (redirects to https://learn.chatgpt.com/docs/agent-configuration/rules) — `.rules` under `rules/` next to an active config layer; `prefix_rule(pattern, decision allow|prompt|forbidden)`; most restrictive wins; `bash -lc` is split only for plain `&&`/`||`/`;`/`|` chains, otherwise evaluated as one string.
- [Codex source exec_policy.rs](https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/src/exec_policy.rs) — maps a rule `prompt` to an approval request.

## Evidence
Docs fetched and quoted. The doc does not cover `approval_policy = "never"` with `prompt`, so exec_policy.rs was read to fill the gap. The assistant noted the rules matched on test commands. Session 16e40ee2 (2026-10-13; `/open-ended` "other things I should work on improving").
