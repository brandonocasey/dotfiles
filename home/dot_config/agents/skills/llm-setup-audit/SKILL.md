---
disable-model-invocation: true
name: llm-setup-audit
description: >
  Audit skills, agent definitions, and shared prompt rules for bugs,
  duplication, and excess context. Fix skills directly; propose rules-file
  edits for approval.
---

Audit prompt files the way code gets audited: verify every claim on disk, fix with a
paper trail, and never silently drop a rule.

## Targets and modes

- **Skills mode** — every file in the skills tree: `SKILL.md` files, agent definitions, and
  the shared helper files that skills read (e.g. `shared/git-flow.md`). Fix directly, report
  after. Default targets: `~/.config/agents/skills/`, the Claude/Gemini/pi agent definitions
  in `~/.config/agents/agents/`, and the Codex ones in `~/.codex/agents/`.
- **Rules mode** — always-loaded instruction files: AGENTS.md, CLAUDE.md, and project
  equivalents. Talk first; zero edits before explicit approval. Default target:
  `~/.config/agents/AGENTS.md`.
- The user's invocation picks the scope (a project's `.claude/skills/`, one skill, one
  rules file). No scope given: audit both defaults.
- "Talk before making changes" from the user forces rules-mode flow for every target.

## 0. Setup (both modes)

- Resolve symlinks first (`readlink`, inode compare) to find the single real file or dir.
  Known chains: `~/.claude*/skills`, `~/.agents/skills` (Codex), and `~/.gemini/config/skills`
  → `~/.config/agents/skills`; `~/.claude*/CLAUDE.md`, `~/.codex/AGENTS.md`,
  `~/.gemini/GEMINI.md`, and `~/.pi/agent/AGENTS.md` → `~/.config/agents/AGENTS.md`.
  Symlinked copies are not duplicates, and one edit propagates everywhere — say so before
  proposing moves. These chains also answer rules mode's "do other tools read this file?":
  yes, so keep tool-default restatements.
- Read every target file whole. Record `wc -l` per file for the before/after report.
- No backup step: the user keeps these files backed up. Edit in place; do not copy
  targets to the scratchpad or anywhere else first.
- Find the manager's source files before editing, including source files not yet
  deployed to the target. Check synchronization hooks and automatic Git settings
  before any manager command. Synchronization MUST NOT commit, push, or apply
  unrelated files without the user's authorization. For plain source files, a
  targeted file edit can sync them without invoking manager hooks; otherwise use
  a documented per-command setting that disables unauthorized side effects.
  Known manager: chezmoi, source `~/.local/share/chezmoi/home/`, plain files (no
  templates), with `git.autoCommit` and `git.autoPush` on. Sync by copying the edited
  target over its source file; never run `chezmoi add`, `re-add`, or `edit`, which commit
  and push. `chezmoi status` must print nothing for the target afterwards.
- Check mtimes. A file modified in the last few minutes may belong to a concurrent agent:
  leave it untouched and report its issues instead. On a "modified since read" error,
  re-read and merge around the new content — never clobber it.
- Check invocation controls for each harness that reads these files: settings overrides,
  skill frontmatter, and any invocation policy in agent metadata. Distinguish disabled
  from explicit-only: Claude Code's `disable-model-invocation` blocks automatic loading;
  Codex documents `policy.allow_implicit_invocation` in `agents/openai.yaml` and
  `skills.config` in its config. Report the observed settings; do not assume one
  harness's flag controls another. Preserve settings unless the user asks to change
  them. Check current harness docs if a setting is unclear.

## Checks

Both modes:

- **Dead references** — paths, files, step numbers, skill names, memory pointers. Verify
  each on disk (`ls`, `grep -n`) before flagging; verify the fix target exists too.
- **Contradictions** — between files and within one file (e.g. step order that disagrees
  with an earlier bullet). Resolve by making one place the authority and having the other
  defer to it, so they cannot drift again.
- **Duplication** — the same rule or algorithm in two places. Move it to its natural owner;
  replace the copy with a reference ("per the `commit` skill — it owns the split rules").
- **Restated rules within one file** — make one section the single authority; steps
  reference it.
- **Ambiguity that changes behavior** — pick the safer reading, state the rationale, and
  flag it (veto item in skills mode, proposal in rules mode). Never end with the
  ambiguity as an open question.
- **Keepers** — verbose-looking rules whose clauses are load-bearing (a clause exists
  because some tool ignores `PORT`, a note stops agents from editing `.gitignore`).
  Defend these in a "Left alone" / "Keep as-is" list instead of trimming them.

Skills mode additions:

- **Command correctness under the skill's own preconditions** — run each command mentally
  from the state the skill creates (detached-HEAD worktree needs
  `git push origin HEAD:<branch>`, not `git push`).
- **Environment portability** — literal `.git/` paths break in linked worktrees. Use
  `git rev-parse --git-common-dir` for shared metadata and `git rev-parse --git-path
  <name>` for metadata that may belong to one worktree. Same test for OS- and
  shell-specific assumptions.
- **Resource leaks** — everything the skill creates (worktree, server, browser page) needs
  cleanup on every exit path, not just the happy one.
- **Platform parity** — a skill that queries GitHub (`gh`) needs the GitLab path (`glab`)
  too, and vice versa, unless it is explicitly single-platform.
- **Frontmatter quality** — keep triggers concise and specific to the user's requests;
  put operating detail in the body. Before renaming a skill, check name-collision
  behavior in each harness's official docs; do not assume personal skills shadow
  built-ins everywhere.
- **Shared-model compatibility** — keep requirements needed by other models or tools.
  Do not remove checks or authorization boundaries merely because one model supplies
  them by default. Link substantial mode-specific detail when that saves irrelevant
  reading; keep simple skills self-contained.

Rules mode additions:

- **General rule + its specific case** — merge into one bullet.
- **Wrong section** — move rules to the section that owns the topic; a one-bullet section
  does not earn a header.
- **Restates tool defaults** — removal is gated on one question: "do other tools read this
  file?" If yes, keep every such rule. Use an answer already given in the conversation;
  otherwise ask once for the whole category, not per rule.
- **Tool- or ecosystem-specific detail in a global file** — generalize ("follow semver and
  use the project's release tooling"), never add tool-specific commands.

## Skills mode flow

1. Setup, then apply fixes directly with Edit — no permission round.
2. Apply semantic changes (where the user's intent could differ) using the safer reading;
   collect them as veto items.
3. Verify: `head` each edited file's frontmatter, `wc -l` before/after. Re-derive any
   algorithm or math you touched or chose to keep.
4. Report in categories: **Bugs fixed / Deduped / Improved / Veto items / Left alone**.
   Each finding: what was wrong, why it matters for the user's workflow, the fix. Veto
   items include the revert instruction.

## Rules mode flow

1. Setup, then present the full analysis — no edits yet. Group proposals under
   **Combine / Simplify / Remove / Keep as-is**, numbered within each group.
2. Every proposal shows the exact final wording that will land on disk. Prose
   descriptions of intended edits are not approvable.
3. Ask unresolved gating questions up front. Use the harness's available question tool
   for judgment calls with real options, or a concise text question if none exists.
   A free-text answer overrides every offered option.
4. Apply only what the user approved — they answer by number ("combine: 1, 2, 3"), by
   group ("do combine and simplify"), or "do all". Re-read the file first; the user
   hand-edits between rounds, so use targeted Edits that preserve their additions.
5. Report: what changed with line-count delta, then full disclosure of every skipped or
   unapplied item with its before/after text. The user will ask "what was skipped" —
   answer it before they do.

## Hard rules

- Never edit a rules file before explicit approval; never edit anything when the user
  said "talk before making changes".
- Never silently drop a rule in a merge or dedup — check every original rule off against
  the result and say you did.
- Accuracy beats brevity: a shortening that loses a fact, condition, number, or scope
  qualifier is a bug, not an improvement.
- Report every file left untouched and every finding left unfixed, with reasons.
- After edits are final, sync every changed or new file back into whatever manages the
  targets so source matches target — never leave drift you created. Committing is the
  user's call; offer it once at the end.
- The audit is re-runnable; when a pass finds little, say the files are in good shape —
  do not invent findings.
- Cite files inline as bare `path:line`, never markdown links. End the report with a
  **Links** section only when there are relevant external links (tickets, MRs/PRs, CI
  jobs) — never a list of the files touched.
