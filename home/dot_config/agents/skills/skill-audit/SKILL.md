---
name: skill-audit
description: >
  Audit the user's prompt files: SKILL.md skills, agent definitions, and always-loaded
  rules files (AGENTS.md / CLAUDE.md). Finds bugs, contradictions, dead references,
  duplication, and verbosity. Skills are fixed directly and reported after, with risky
  semantic changes flagged as veto items; rules files are never edited before the user
  approves numbered proposals showing the exact final wording. Use when the user says
  "go over my skill files", "audit my skills", "simplify/dedupe my skills", "clean up
  AGENTS.md / CLAUDE.md", "audit my rules", or invokes /skill-audit.
---

Audit prompt files the way code gets audited: verify every claim on disk, fix with a
paper trail, and never silently drop a rule.

## Targets and modes

- **Skills mode** — SKILL.md files and agent definition `.md` files. Fix directly, report
  after. Default target: `~/.config/agents/skills/`.
- **Rules mode** — always-loaded instruction files: AGENTS.md, CLAUDE.md, and project
  equivalents. Talk first; zero edits before explicit approval. Default target:
  `~/.config/agents/AGENTS.md`.
- The user's invocation picks the scope (a project's `.claude/skills/`, one skill, one
  rules file). No scope given: audit both defaults.
- "Talk before making changes" from the user forces rules-mode flow for every target.

## 0. Setup (both modes)

- Resolve symlinks first (`readlink`, inode compare) to find the single real file or dir.
  Known chains: `~/.claude/skills` and `~/.claude-two/skills` → `~/.config/agents/skills`;
  `~/.claude*/CLAUDE.md` → `~/.config/agents/AGENTS.md`. Symlinked copies are not
  duplicates, and one edit propagates everywhere — say so before proposing moves.
- Read every target file whole. Record `wc -l` per file for the before/after report.
- No backup step: the user keeps these files backed up. Edit in place; do not copy
  targets to the scratchpad or anywhere else first.
- Check mtimes. A file modified in the last few minutes may belong to a concurrent agent:
  leave it untouched and report its issues instead. On a "modified since read" error,
  re-read and merge around the new content — never clobber it.

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
- **Environment portability** — literal `.git/` paths break in linked worktrees; use
  `git rev-parse --git-common-dir`. Same test for OS- and shell-specific assumptions.
- **Resource leaks** — everything the skill creates (worktree, server, browser page) needs
  cleanup on every exit path, not just the happy one.
- **Platform parity** — a skill that queries GitHub (`gh`) needs the GitLab path (`glab`)
  too, and vice versa, unless it is explicitly single-platform.
- **Frontmatter quality** — description triggers neither overbroad (fires on any stale
  file) nor missing the phrases the user actually says. Before renaming a skill, confirm
  shadowing rules against the official docs (personal skills shadow built-ins).

Rules mode additions:

- **General rule + its specific case** — merge into one bullet.
- **Wrong section** — move rules to the section that owns the topic; a one-bullet section
  does not earn a header.
- **Restates tool defaults** — removal is gated on one question: "do other tools read this
  file?" If yes, keep every such rule. Ask once for the whole category, not per rule.
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
3. Ask the gating questions up front (other-tools gate for Remove; AskUserQuestion for
   judgment calls with real options). A free-text answer overrides every offered option.
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
- End the report with a **Links** section: every file touched or cited, as bare
  `path:line` — never markdown links.
