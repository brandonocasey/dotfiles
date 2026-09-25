---
disable-model-invocation: true
name: llm-setup-audit
description: >
  Audit skills, agent definitions, and rules files for bugs, duplication, wasted
  tokens, and complex language. Fix skills directly; propose rules-file edits for
  approval.
---

Goal: each target gives every agent that reads it what that agent needs, once, in plain
words and few tokens. Fix bugs, remove text with no effect, and keep every rule that changes
behavior.

## Modes

- **Skills mode** audits skill files: each `SKILL.md`, the shared files that skills read
  (such as `shared/git-flow.md`), and agent definitions. Fix directly, then report.
  Default targets: `~/.config/agents/skills/`, `~/.config/agents/agents/`, and
  `~/.codex/agents/`.
- **Rules mode** audits rules files: the always-loaded `AGENTS.md`, `CLAUDE.md`, and
  project equivalents. Propose first, and edit only what the user approves. Default
  target: `~/.config/agents/AGENTS.md`.
- The user's invocation sets the scope: a project's `.claude/skills/`, one skill, or one
  rules file. With no scope, audit both defaults.
- When the user says "talk before making changes", use the rules-mode flow for every target.
- A **veto item** is an applied change that alters behavior or picks one reading of unclear
  text. Give each one a revert instruction. **Left alone** lists each finding you did not
  fix and each target you did not change, with the reason.

## Setup

- Resolve links (`realpath`) before you compare files: a linked path is the same file, not a
  duplicate. Every file under `~/.config/agents/` reaches several harnesses through links,
  so one edit changes all of them. Say so before you propose a move.
- Read every target whole, and record its size in tokens for the before/after report.
  `claude -p /context` prints exact Claude counts for rules files, skill listings, and
  agent definitions. Run it in the project directory to include project files. Estimate
  other files as bytes (`wc -c`) ÷ 3.
- Do not back up targets or copy them anywhere before you edit; the user keeps backups.
- Before you edit a target, find its source: chezmoi, or another repository that it is
  copied from. Change the source too. Before you run a sync command, check its hooks and
  automatic Git settings. A sync MUST NOT commit, push, or overwrite other files without the
  user's approval.
- chezmoi manages `~/.config/agents/` as plain files, with `git.autoCommit` and
  `git.autoPush` on:
  - Never run a chezmoi command that writes the source (`add`, `re-add`, `edit`), because
    it commits and pushes. Never run `chezmoi apply` without a target.
  - First run `chezmoi status ~/.config/agents`. Leave each listed target that exists alone,
    and report it. For a listed source file with no target yet, audit and fix the source
    file itself.
  - After the last edit, copy each changed or new target to its source path.
    `chezmoi source-path` prints that path for the target or its directory. A new name can
    need a prefix such as `private_`. Then `chezmoi status <target>` must print nothing for
    each target that you changed.
  - When `chezmoi source-path` fails, the target is unmanaged: edit it in place and report
    that it has no source copy.
- Two kinds of targets have an owner that overwrites edits: the Claude app syncs
  `skills/synced/`, and `gh skill` installs skills whose frontmatter has `metadata.github-*`
  keys. Report their findings; do not edit them.
- A target modified in the last few minutes can belong to a concurrent agent. Leave it
  alone, and report its findings. On a "modified since read" error, read the file again and
  merge your change into the new content.
- Keep each skill's invocation settings unless the user asks. Report them for each harness,
  and tell explicit-only apart from off. Claude Code: `disable-model-invocation` in
  frontmatter, and the `skillOverrides` setting (`off` also removes the skill from the `/`
  menu). Codex: `policy.allow_implicit_invocation` in `agents/openai.yaml`, and
  `skills.config` in its config. One harness's setting does not control another.

## Checks

Both modes:

- **Dead references and false claims** — paths, files, step numbers, skill names, memory
  pointers, and statements about harness behavior. Check each on disk (`ls`, `grep -n`)
  or in current docs before you flag it. Also check that the fix target exists.
- **Contradictions and duplication** — two statements that disagree, or one rule in two
  places, in one file or across files. Keep the rule in its natural owner. Make the other
  place refer to it ("per the `commit` skill — it owns the split rules").
- **Text with no effect** — remove a sentence when no agent that reads the file would act
  differently without it. This covers general knowledge, a restated rule or heading,
  history, and an example that repeats its rule. A shorter sentence keeps every fact,
  number, condition, and scope qualifier. Keep a reason or clause that changes behavior,
  even if it looks verbose, and list it under **Left alone**. Examples: a tool ignores
  `PORT`; a note stops edits to `.gitignore`.
- **Token cost** — spend effort where text costs the most, and cut there first:
  - Rules files load in every session, and again in every sub-agent that loads them.
  - The listing of each model-invocable skill loads in every session. Propose making a
    rarely used skill explicit-only (`disable-model-invocation`, or `skillOverrides` for a
    skill you do not own).
  - A skill body loads each time the skill runs, then stays for the session. Weigh it by
    its `/<name>` or `$<name>` count in the history files (`~/.claude*/history.jsonl`,
    `~/.codex/history.jsonl`).
  - Each file that a skill tells the agent to read adds its tokens. Make each read
    conditional ("read X when Y").
  - After compaction, Claude Code keeps only the first 5,000 tokens of a skill (about
    15 KB). Flag a longer skill, and put its essential rules first.
  - Codex stops reading `AGENTS.md` files at `project_doc_max_bytes` (32 KiB by default).
  - A sub-agent role that needs none of the rules can skip them (Claude Code
    `omitClaudeMd: true`). Propose it; do not apply it.
- **Restated defaults** — keep a rule that restates one harness's or model's default when
  several harnesses read the file. Never remove a check or an authorization boundary for
  that reason alone. For a file that one harness reads, ask once for the whole category,
  unless the user already answered.
- **Stop points** — each instruction that makes the agent ask, confirm, wait, or stop. Keep
  it when it guards an irreversible, outward-facing, or unauthorized action. Narrow or
  remove the rest. Agents follow these literally.
- **Language** — every line you keep follows the Writing rules in
  `~/.config/agents/AGENTS.md`, including the sentence-length limits. Also check:
  - the same term for a concept in every target;
  - the action to take, not only a ban; keep "never" for hard boundaries;
  - no emphasis (capitals, "IMPORTANT") on a rule that agents follow without it, because
    agents over-apply emphasized rules.
- **Ambiguity that changes behavior** — pick the safer reading, and give the reason. Flag
  it as a veto item or a proposal. Never end with the ambiguity as an open question.

Skills mode:

- **Command correctness under the skill's own preconditions** — run each command mentally
  from the state that the skill creates. A detached-HEAD worktree needs
  `git push origin HEAD:<branch>`, not `git push`.
- **Environment portability** — literal `.git/` paths break in linked worktrees. Use
  `git rev-parse --git-common-dir` for shared metadata and
  `git rev-parse --git-path <name>` for metadata that can belong to one worktree. Test OS
  and shell assumptions the same way.
- **Resource leaks** — everything the skill creates (worktree, server, browser page) needs
  cleanup on every exit path.
- **Platform parity** — a skill that queries GitHub (`gh`) needs the GitLab path (`glab`)
  too, and the reverse, unless it is explicitly single-platform.
- **Frontmatter** — a short description: the use case first, then specific triggers, then
  the neighbor skill for a nearby case. Move operating detail to the body. Before you rename
  a skill, check name-collision behavior in each harness's docs. Do not assume that a
  personal skill shadows a built-in everywhere. Also compare names with the current
  repository's skills. On a clash, Claude Code runs the personal skill; Codex lists both.
- **Structure** — move long detail that only one mode or case needs into a linked file.
  Keep simple skills in one file.
- **Whole skills** — a skill that another skill, a built-in, or a rules file covers.
  Propose its merge or removal, but do not apply it. Do the same for an explicit-only skill
  that nothing uses. Such a skill has no `/<name>` or `$<name>` in the history files, and no
  target refers to it.

Rules mode:

- **General rule and its specific case** — merge them into one bullet.
- **Wrong section** — move a rule to the section that owns its topic. A section with one
  bullet does not need its own header.
- **Tool- or ecosystem-specific detail in a global file** — generalize it ("follow semver
  and use the project's release tooling"). Never add tool-specific commands.

## Skills mode flow

1. Do the setup, then apply the fixes, and record each veto item.
2. Verify: `head` the frontmatter of each edited file, and compare token counts before and
   after. Re-derive each algorithm or calculation that you changed or chose to keep.
3. Report in these categories: **Bugs fixed / Deduped / Improved / Veto items / Left
   alone**. For each finding, give what was wrong, why it matters for the user's workflow,
   and the fix.

## Rules mode flow

1. Do the setup, then present the full analysis. Group proposals under
   **Combine / Simplify / Remove / Left alone**, numbered within each group.
2. Show the exact final wording of each proposal.
3. Ask unresolved gating questions first. Use the harness's question tool for a judgment
   call with real options. If the harness has none, ask a short text question. A free-text
   answer overrides every offered option.
4. Apply only what the user approved. The user approves by number ("combine: 1, 2, 3"), by
   group ("do combine and simplify"), or with "do all". Read the file again first. The user
   edits by hand between rounds, so use targeted edits that keep their additions.
5. Report what changed, with the token delta. Then list each item not applied, with its
   before/after text. The user will ask "what was skipped", so answer it first.

## Every run

- Start the report with the tokens that load in every session, before and after.
- When you merge, move, or remove text, map each original rule to its new place or its
  removal reason. Say in the report that you checked every rule.
- When a pass finds little, say that the files are in good shape; do not invent findings.
- Cite files as bare `path:line`, never as Markdown links.
- Committing is the user's decision; offer it once at the end.

## Sources

Read a page only when a finding depends on it, and cite it. Do not read every page on each
run.

- Skills:
  - Anthropic skill best practices https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
  - Claude Code skills https://code.claude.com/docs/en/skills
  - Codex skills https://learn.chatgpt.com/docs/build-skills
- Rules files:
  - Claude Code memory https://code.claude.com/docs/en/memory
  - Codex AGENTS.md https://learn.chatgpt.com/docs/agent-configuration/agents-md
- Model behavior and tokens:
  - Claude prompting best practices https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
  - Claude token counting https://platform.claude.com/docs/en/build-with-claude/token-counting
  - GPT-6 model guidance https://developers.openai.com/api/docs/guides/latest-model
  - GPT-6 skills and prompts https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra
