---
name: llm-setup-audit
description: "Audit global skills, roles, rules, config, and session spend for defects and token waste."
---

Give each reader every needed rule once, in plain words and few tokens.
Fix bugs and remove ineffective text. Preserve every rule that changes behavior.

## Scope and authority

- **Skills:** audit whole `SKILL.md` files, linked shared instructions, and agent definitions. Fix directly, then report; on talk-first or a run you started without the user asking, propose instead.
  Defaults: `~/.config/agents/skills/`, `~/.config/agents/agents/`, and `~/.codex/agents/`.
  Both harnesses' role bodies render from chezmoi's `.chezmoitemplates/agents/`; edit those templates.
  Role frontmatter lives in `dot_config/exact_agents/exact_agents/*.md.tmpl` and `dot_codex/exact_agents/*.toml.tmpl`.
- **Rules:** audit always-loaded `AGENTS.md`, `CLAUDE.md`, and project equivalents. Tag each proposal (see **Safe and gating**); ask only about gating ones.
  Defaults: `~/.config/agents/AGENTS.md` and the main-session rules in chezmoi's `.chezmoitemplates/main-rules.md`.
  Both render into the Gemini, opencode, and pi rules files; the main rules also render into `~/.claude/output-styles/main.md` and Codex `developer_instructions`.
- **Harness config:** audit `~/.claude*/settings.json` hooks and `statusLine`, `~/.claude*/hooks/`,
  `~/.codex/config.toml`, `~/.codex/hooks.json`, and the repository's `.claude/skills/` and `.agents/skills/`.
  MCP servers: `mcpServers` and `disabledMcpServers` (top level and per project) in `~/.claude.json` and `~/.claude*/.claude.json`; project and plugin `.mcp.json`; and Codex `[mcp_servers.*]`.
  Read only names, `enabled`, and `enabled_tools`, never values.
  Tag each proposal (see **Safe and gating**); ask only about gating ones.
- **Sessions:** audit the last 30 days of transcripts per [runtime.md](references/runtime.md).
- Use the invocation's scope; without one, audit every target above.
  “Talk before making changes” applies the rules flow to every target.
- A **veto item** changes behavior or resolves ambiguity. Give each applied item a revert instruction.
  **Left alone** includes every unedited target and unresolved finding, with reasons.

## Setup

Resolve links with `realpath` before comparing files; aliases are not duplicates.
Files under `~/.config/agents/` reach multiple harnesses through links.
State that shared impact before proposing a move.

Read every target whole and record before/after tokens.
Measure global rules, skills, and agents with `agent-probe --prompt 'Reply with OK only.'`, before and after.
Invoking this skill authorizes these probes.
It runs in an empty directory, so it never loads project files.
For the MCP share, run it with `--variant base= --variant nomcp='--strict-mcp-config'` and compare.
For project files or a per-file breakdown, ask the user to run `/context` in the project, before and after.
Label rounded or estimated counts accordingly. Estimate other files as bytes (`wc -c`) ÷ 3.
Before applying a safe rules or config item, copy the target to the AGENTS.md backup path.
Skill edits need no backup.

Find each target's source before editing: chezmoi or another repository. Update that source too.
Before any sync, check hooks and automatic Git settings.
A sync must not commit, push, or overwrite other files without approval.

When the scope names several hosts, follow [host-drift.md](references/host-drift.md) on every named host.

### Chezmoi

It manages `~/.config/agents/`, `~/.codex/`, `~/.claude/`, `~/.claude-two/`, and the Gemini, opencode, and pi rules files with `autoCommit` and `autoPush` off.
Some sources are `modify_` scripts, `.tmpl` templates, or `symlink_` entries, not plain files.

1. Run `chezmoi status ~/.config/agents ~/.codex ~/.claude ~/.claude-two ~/.gemini/GEMINI.md ~/.config/opencode/AGENTS.md ~/.pi/agent/AGENTS.md` first.
   For each listed target, summarize `chezmoi diff <target>` in one line.
   Skip targets under the ownership rule below.
   Recommend one action for each: copy the target to its source (step 3), or `chezmoi apply <target>`.
   Ask once for all of them. Apply only the approved actions.
   If a listed source has no target, audit and edit the source itself.
2. Never run source-writing commands (`add`, `re-add`, `edit`); they can write source files outside the audit.
   Never run `chezmoi apply` without a target.
3. Before any copy, review the changes with `diff -u "$(chezmoi source-path <target>)" <target>`.
   After the review fixes, copy each changed or new target to its source.
   Copy only plain sources. For a `modify_`, `.tmpl`, or `symlink_` source, edit that script or template instead.
   Find the path with `chezmoi source-path <target-or-directory>`; new names can require prefixes such as `private_`.
   Require empty `chezmoi status <target>` output for every changed target.
4. If `source-path` fails, edit the unmanaged target in place and report that it has no source copy.

### Safe and gating

Tag each rules or config proposal **safe** or **gating**.
Safe: a wording, dedupe, path, or typo fix that keeps every rule's behavior and touches no veto item, stop point, or authorization boundary.
Gating: everything else.
- Talk-first, or a run you started without the user asking: apply nothing; list every item with its tag and exact wording.
- Otherwise, including a bare invocation by the user: apply safe items after the backup and report each with a revert instruction; ask only about gating items.

When a settings or rule file is harness-blocked, do not retry the edit.
Write one apply script (`sh`, with the backup step) to the scratch directory, print its path and what it changes, and hand it over once.

### Ownership and invocation

Report findings without editing Claude-app-owned `skills/synced/` or `gh skill` installs with `metadata.github-*` frontmatter, or skills listed in `~/.agents/.skill-lock.json`.
Leave targets modified within the last few minutes alone; another agent may own them.
On “modified since read,” reread and merge with the new content.

Preserve invocation settings unless the user asks to change them. Report each harness separately:

- Claude Code: `disable-model-invocation` frontmatter and `skillOverrides`.
  `user-invocable-only` is explicit-only; `name-only` lists only the name, saving description tokens while keeping model visibility; `off` also removes the `/` entry.
- Codex: `policy.allow_implicit_invocation` in `agents/openai.yaml`, and `skills.config` in its config.

One harness's setting does not control another.

## Checks for all targets

- **Sweeps:** run the existence, orphan, parity, and byte-count checks via `cheap`.
- **References and claims:** check paths, files, steps, skill names, memory pointers, and harness claims on disk or in current documentation.
  Verify the proposed fix target exists before flagging a defect.
- **Contradictions and duplicates:** check within and across files. Keep each rule in its natural owner; refer there elsewhere.
- **Reader context:** for the main thread and each role, per harness, list what loads together: rules (Codex roles load `AGENTS.md`; Claude roles with `omitClaudeMd: true` do not), the main rules or role body with its partials, skills each names, MCP tools, and session-start hook output.
  Check each set for duplicates, gaps, and contradictions.
  Flag text a reader loads but never acts on, such as main-session reply rules in a role.
- **Spawn guidance:** compare the spawn-prompt content that skills require with each role's load.
  Flag text the role already loads and context it lacks.
- **Invocation conflicts:** find each rule or skill that tells the model to run an explicit-only skill.
  Propose one fix: make the skill model-invocable, or change the rule.
- **Orphans:** list each file under `references/` or `shared/` that no skill links. Propose a link or a removal.
- **Authorization owners:** give push, merge, git-settings, and destructive-action consent one owning rule.
  Skills name that owner and keep their own stop points.
- **Ineffective text:** remove general knowledge, repeated rules/headings, history, and examples only when no reader would act differently.
  Preserve every fact, number, condition, scope qualifier, and reason that changes behavior.
  List retained clauses under **Left alone**.
  Keep restated defaults in files shared across harnesses. For a single-harness file, ask once about removing them unless already answered.
  Never remove a check or authorization boundary merely because it restates a default.
- **Stop points:** keep asks, confirmations, waits, and stops that guard irreversible, outward-facing, or unauthorized actions.
  Narrow or remove other stop points; agents follow them literally.
- **Language:** apply the writing rules. Main sessions already load them; read [writing.md](../shared/writing.md) only when they are absent.
  Use one term per concept and name the action, not only a ban. Keep “never” for hard boundaries.
  Remove unnecessary capitals and emphasis, which can cause over-application.
- **Behavioral ambiguity:** choose the safer reading and give the reason as a veto item or proposal.
  Do not leave it as an open question.

## Token priorities

Prioritize recurring cost over raw file size:

1. Rules, MCP tool listings, and session-start hook output load every session. Rules also load in sub-agents that include them.
2. Per-prompt and per-tool hook output recurs on each call that adds it.
3. Model-invocable skill listings load every session.
   Propose explicit-only invocation for rarely used skills: `disable-model-invocation` for owned skills;
   `skillOverrides: user-invocable-only` for other Claude skills.
   To keep model visibility, propose `name-only` instead.
   Plugin skills ignore `skillOverrides`; manage them through `/plugin`.
4. Skill bodies load on invocation and remain in context.
   Weight cost by `/<name>` or `$<name>` counts in `~/.claude*/history.jsonl` and `~/.codex/history.jsonl`.
   History records typed invocations only. History files can hold NUL bytes: search them with `rg -a` or `grep -a`.
   For model-invocable skills, count Claude `"name":"Skill"` calls recursively under `~/.claude*/projects/`, including sub-agent logs.
5. Linked reads add tokens. Make each conditional: “Read X when Y.”

For workflow improvements or a session-history audit, read
[session-evidence.md](references/session-evidence.md).

Claude Code compaction retains at most the first 5,000 tokens per invoked skill, about 15 KB by this estimate.
Flag longer skills and put essential rules first. Its shared retention budget can also drop older skills.
Codex caps `AGENTS.md` reads at `project_doc_max_bytes`, 32 KiB by default.
For a Claude sub-agent needing no rules, propose `omitClaudeMd: true`; do not apply it.

## Additional skill checks

- **Commands:** trace each command from the skill's actual preconditions.
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

Combine general rules with their specific cases. Remove single-bullet section headings.
Generalize ecosystem-specific details in global rules, such as “Follow semver and use the project's release tooling.”
Never add tool-specific commands there.

## Config coverage checks

- **Coverage:** each file that a hook or `statusLine` command names must appear in `chezmoi managed`.
- **Empty hooks:** report hook events with no commands, such as `"PreToolUse": []`.
- **Parity:** list each Claude hook with no Codex equivalent in `~/.codex/hooks.json`, and the reverse.
- **Secrets:** run the `dotfiles-sync` secret scan on the chezmoi source; report per AGENTS.md. Propose a move to the secret store for each.
- **Tool search:** flag `ENABLE_TOOL_SEARCH=false` in a Claude profile's settings `env`, a custom `ANTHROPIC_BASE_URL`, or a `ToolSearch` deny rule.
  Each turns tool search off, so every MCP tool schema loads in full on each call.
- **MCP servers:** check use per [runtime.md](references/runtime.md).

## Skills flow

1. Complete setup, apply fixes (or propose them, per **Skills** above), and record veto items.
2. Check edited frontmatter with `head`, compare token counts, and re-derive algorithms or calculations changed or retained.
   After workflow edits, replay relevant failures per
   [workflow-replays.md](references/workflow-replays.md).
3. Report under **Bugs fixed / Deduped / Improved / Session evidence / Veto items / Left alone**.
   For each finding, state the defect, its workflow effect, and the fix.

## Rules flow

1. Complete setup. Present the full analysis under **Combine / Simplify / Remove / Session evidence / Left alone**, numbered within each group.
2. Show every proposal's exact final wording.
3. Apply safe proposals per **Safe and gating**. Ask unresolved gating questions next. Use the harness's question tool for judgement calls with real options; otherwise ask in text.
   Free text overrides offered choices.
4. Apply approved items (gating, or safe ones held back by talk-first): numbers, groups, or “do all.” Reread first; use targeted edits that preserve the user's intervening changes.
5. Report changes. List each unapplied item with its before/after text so skipped work is explicit.

## Every report

Start with before/after tokens that load every session.
Put runtime findings under **Session evidence**, with their numbers and date range.
Map each original rule to its retained location or removal reason when merging, moving, or removing text.
State that every rule was checked. If little needs changing, say the files are in good shape; do not invent findings.
Cite files as bare `path:line`, never Markdown links.
Leave committing to the user; offer it once at the end.

## Sources

Read [sources.md](references/sources.md) only when a finding depends on documentation.
