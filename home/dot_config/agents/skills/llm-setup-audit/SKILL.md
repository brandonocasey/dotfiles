---
disable-model-invocation: true
name: llm-setup-audit
description: "Audit global skills, roles, rules, and config for defects and token waste; rules/config edits require approval."
---

Scope: Audit skills, agent definitions, rules files, and harness config for bugs, duplication, drift, wasted tokens, and complex language. Fix skills directly; propose rules-file and config edits for approval.


Give each reader every needed rule once, in plain words and few tokens.
Fix bugs and remove ineffective text. Preserve every rule that changes behavior.

## Scope and authority

- **Skills:** audit whole `SKILL.md` files, linked shared instructions, and agent definitions. Fix directly, then report.
  Defaults: `~/.config/agents/skills/`, `~/.config/agents/agents/`, and `~/.codex/agents/`.
- **Rules:** audit always-loaded `AGENTS.md`, `CLAUDE.md`, and project equivalents. Propose edits; apply only approved proposals.
  Default: `~/.config/agents/AGENTS.md`.
- **Harness config:** audit `~/.claude*/settings.json` hooks and `statusLine`, `~/.claude*/hooks/`,
  `~/.codex/config.toml`, `~/.codex/hooks.json`, and the repository's `.claude/skills/` and `.agents/skills/`.
  Propose edits; apply only approved proposals.
- Use the invocation's scope; without one, audit both defaults.
  “Talk before making changes” applies the rules flow to every target.
- A **veto item** changes behavior or resolves ambiguity. Give each applied item a revert instruction.
  **Left alone** includes every unedited target and unresolved finding, with reasons.

## Setup

Resolve links with `realpath` before comparing files; aliases are not duplicates.
Files under `~/.config/agents/` reach multiple harnesses through links.
State that shared impact before proposing a move.

Read every target whole and record before/after tokens.
Run `claude -p /context` in the project directory for reported rules, skill-listing, and agent counts.
Label rounded or estimated counts accordingly. Estimate other files as bytes (`wc -c`) ÷ 3.
Do not back up or copy targets before editing; the user keeps backups.

Find each target's source before editing: chezmoi or another repository. Update that source too.
Before any sync, check hooks and automatic Git settings.
A sync must not commit, push, or overwrite other files without approval.

When the scope names several hosts, read [host-drift.md](references/host-drift.md).
Compare each shared source with its resolved installation on every named host.
Distinguish intentional host differences from stale copies. After an authorized
sync, check hashes and linked references again; report every remaining mismatch.

### Chezmoi

It manages `~/.config/agents/`, `~/.codex/`, `~/.claude/`, and `~/.claude-two/` with automatic commits and pushes enabled.
Some sources are `modify_` scripts, `.tmpl` templates, or `symlink_` entries, not plain files.

1. Run `chezmoi status ~/.config/agents ~/.codex ~/.claude ~/.claude-two` first.
   For each listed target, summarize `chezmoi diff <target>` in one line.
   Skip targets modified in the last few minutes; another agent may own them.
   Recommend one action for each: copy the target to its source (step 3), or `chezmoi apply <target>`.
   Ask once for all of them. Apply only the approved actions.
   If a listed source has no target, audit and edit the source itself.
2. Never run source-writing commands (`add`, `re-add`, `edit`); they commit and push.
   Never run `chezmoi apply` without a target.
3. Before any copy, review the changes with `diff -u "$(chezmoi source-path <target>)" <target>`.
   After the review fixes, copy each changed or new target to its source.
   Copy only plain sources. For a `modify_`, `.tmpl`, or `symlink_` source, edit that script or template instead.
   Any later source-writing command, from any session, commits and pushes pending source copies.
   Find the path with `chezmoi source-path <target-or-directory>`; new names can require prefixes such as `private_`.
   Require empty `chezmoi status <target>` output for every changed target.
4. If `source-path` fails, edit the unmanaged target in place and report that it has no source copy.

### Ownership and invocation

Report findings without editing Claude-app-owned `skills/synced/` or `gh skill` installs with `metadata.github-*` frontmatter.
Leave targets modified within the last few minutes alone; another agent may own them.
On “modified since read,” reread and merge with the new content.

Preserve invocation settings unless the user asks to change them. Report each harness separately:

- Claude Code: `disable-model-invocation` frontmatter and `skillOverrides`.
  `user-invocable-only` is explicit-only; `name-only` still lists the name; `off` also removes the `/` entry.
- Codex: `policy.allow_implicit_invocation` in `agents/openai.yaml`, and `skills.config` in its config.

One harness's setting does not control another.

## Checks for all targets

- **References and claims:** check paths, files, steps, skill names, memory pointers, and harness claims on disk or in current documentation.
  Verify the proposed fix target exists before flagging a defect.
- **Contradictions and duplicates:** check within and across files. Keep each rule in its natural owner; refer there elsewhere.
  Example: “The `commit` skill owns commit splitting.”
- **Invocation conflicts:** find each rule or skill that tells the model to run an explicit-only skill.
  Propose one fix: make the skill model-invocable, or change the rule.
- **Orphans:** list each file under `references/` or `shared/` that no skill links. Propose a link or a removal.
- **Authorization owners:** give push, merge, git-settings, and destructive-action consent one owning rule.
  Skills name that owner and keep their own stop points.
- **Ineffective text:** remove general knowledge, repeated rules/headings, history, and examples only when no reader would act differently.
  Preserve every fact, number, condition, scope qualifier, and reason that changes behavior.
  List retained clauses under **Left alone**, including tool-specific exceptions such as ignored `PORT` values or protection against `.gitignore` edits.
- **Defaults:** keep restated defaults in files shared across harnesses.
  For a single-harness file, ask once about removing this category unless already answered.
  Never remove a check or authorization boundary merely because it restates a default.
- **Stop points:** keep asks, confirmations, waits, and stops that guard irreversible, outward-facing, or unauthorized actions.
  Narrow or remove other stop points; agents follow them literally.
- **Language:** apply `~/.config/agents/AGENTS.md` Writing rules, including sentence limits.
  Use one term per concept and name the action, not only a ban. Keep “never” for hard boundaries.
  Remove unnecessary capitals and emphasis, which can cause over-application.
- **Behavioral ambiguity:** choose the safer reading and give the reason as a veto item or proposal.
  Do not leave it as an open question.

## Token priorities

Prioritize recurring cost over raw file size:

1. Rules load every session and in sub-agents that include them.
2. Model-invocable skill listings load every session.
   Propose explicit-only invocation for rarely used skills: `disable-model-invocation` for owned skills;
   `skillOverrides: user-invocable-only` for other Claude skills.
   `name-only` saves description tokens while keeping model visibility.
   Plugin skills ignore `skillOverrides`; manage them through `/plugin`.
3. Skill bodies load on invocation and remain in context.
   Weight cost by `/<name>` or `$<name>` counts in `~/.claude*/history.jsonl` and `~/.codex/history.jsonl`.
   History records typed invocations only.
   For model-invocable skills, count Claude `"name":"Skill"` calls recursively under `~/.claude*/projects/`, including sub-agent logs.
4. Linked reads add tokens. Make each conditional: “Read X when Y.”

For workflow improvements or a session-history audit, read
[session-evidence.md](references/session-evidence.md). Inspect corrections and
repeated follow-ups alongside invocation counts. Check the surrounding turns,
current implementation, and coverage before ranking avoidable user effort.

Claude Code compaction retains at most the first 5,000 tokens per invoked skill, about 15 KB by this estimate.
Flag longer skills and put essential rules first. Its shared retention budget can also drop older skills.
Codex caps `AGENTS.md` reads at `project_doc_max_bytes`, 32 KiB by default.
For a Claude sub-agent needing no rules, propose `omitClaudeMd: true`; do not apply it.

## Additional skill checks

- **Commands:** trace each command from the skill's actual preconditions.
  Detached review worktrees need `git push origin HEAD:<branch>`, not `git push`.
- **Portability:** literal `.git/` paths fail in linked worktrees.
  Use `git rev-parse --git-common-dir` for shared metadata and `git rev-parse --git-path <name>` for per-worktree metadata.
  Check OS and shell assumptions too.
- **Cleanup:** every created worktree, server, or browser page needs cleanup on every exit path.
- **Platforms:** provide GitHub (`gh`) and GitLab (`glab`) paths unless the skill is explicitly single-platform.
- **Frontmatter:** keep descriptions short: use case, specific triggers, then the neighbor skill for nearby tasks.
  Move operating detail into the body.
  Before renaming, check current harness collision behavior and repository skill names.
  Do not assume personal skills shadow built-ins everywhere: Claude Code and Codex resolve names differently.
- **Structure:** move long, case-specific detail into conditional references. Keep simple skills in one file.
- **Whole skills:** propose, but never apply, mergers or removals when another skill, built-in, or rules file covers the workflow.
  Also propose this for unused explicit-only skills: no typed invocation in either history and no target referring to them.

## Additional rules checks

Combine general rules with their specific cases.
Move misplaced rules to their owning section; remove single-bullet section headings.
Generalize ecosystem-specific details in global rules, such as “Follow semver and use the project's release tooling.”
Never add tool-specific commands there.

## Config coverage checks

- **Coverage:** each file that a hook or `statusLine` command names must appear in `chezmoi managed`.
- **Empty hooks:** report hook events with no commands, such as `"PreToolUse": []`.
- **Parity:** list each Claude hook with no Codex equivalent in `~/.codex/hooks.json`, and the reverse.
- **Secrets:** search the chezmoi source for tokens and keys. Report each match as `path:line` with the value replaced by [redacted].
  Propose a move to the secret store for each.

## Skills flow

1. Complete setup, apply fixes, and record veto items.
2. Check edited frontmatter with `head`, compare token counts, and re-derive algorithms or calculations changed or retained.
   After workflow edits, replay relevant failures with
   [workflow-replays.md](references/workflow-replays.md). Record expected and
   observed behavior without external writes. Do not infer savings from counts.
3. Report **Bugs fixed / Deduped / Improved / Session evidence / Veto items / Left alone**.
   For each finding, state the defect, its workflow effect, and the fix.

## Rules flow

1. Complete setup. Present the full analysis under **Combine / Simplify / Remove / Session evidence / Left alone**, numbered within each group.
2. Show every proposal's exact final wording.
3. Ask unresolved gating questions first. Use the harness's question tool for judgement calls with real options; otherwise ask in text.
   Free text overrides offered choices.
4. Apply only approved numbers, groups, or “do all.” Reread first; use targeted edits that preserve the user's intervening changes.
5. Report changes and token deltas. List each unapplied item with its before/after text so skipped work is explicit.

## Every report

Start with before/after tokens that load every session.
Map each original rule to its retained location or removal reason when merging, moving, or removing text.
State that every rule was checked. If little needs changing, say the files are in good shape; do not invent findings.
Cite files as bare `path:line`, never Markdown links.
Leave committing to the user; offer it once at the end.

## Sources

Read and cite a page only when a finding depends on it.

- Anthropic skill practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Claude Code skills: https://code.claude.com/docs/en/skills
- Claude Code sub-agents: https://code.claude.com/docs/en/sub-agents
- Codex skills: https://learn.chatgpt.com/docs/build-skills
- Claude Code memory: https://code.claude.com/docs/en/memory
- Codex AGENTS.md: https://learn.chatgpt.com/docs/agent-configuration/agents-md
- Claude prompting: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Claude token counting: https://platform.claude.com/docs/en/build-with-claude/token-counting
- GPT-6 guidance: https://developers.openai.com/api/docs/guides/latest-model
- GPT-6 skills and prompts: https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra
