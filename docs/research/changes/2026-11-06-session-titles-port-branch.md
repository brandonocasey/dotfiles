# Session titles: port, branch and part number via `sessionTitle`

- Status (2026-11-06): current. `home/dot_claude/hooks/executable_session-port.sh` and `executable_auto-title.sh` exist. The auto-title header says every name keeps the session's port in front, a session takes its branch name, and after `/clear` the next prompt names it "<old name> Part N". Latest commit `0cc5217a`.
- Topic: Hooks
- Related: [Session names from the first prompt via a Haiku hook](2026-10-13-session-names-haiku-hook.md), [Auto-title cost probe](../ab-tests/2026-10-13-auto-title-cost.md)

## Change
Hooks name each session with the session's port, then by branch and "Part N". The hook clears the old name on `/clear`, skips headless runs, and lets `/rename` win over a pending branch name. Before this, on 2026-10-14, a hook retitled sessions after `/clear` and left user-set names alone.

## History
- 2026-10-14 — session 27c2f151, user: "sessions should be renamed again after a clear". `a23c3518 dx(claude): retitle sessions after /clear`: after `/clear` the first plain prompt replaces an old auto-made title; user-set names stay. A "New session" placeholder was tried and dropped because it never showed.
- 2026-10-15 — `f97640fb dx(claude): give each session its own port block` and `555444c6 dx(claude): keep ports while the cache is valid` created `session-port.sh`, which reserves a port block per session. These are the port source, not naming.
- 2026-11-06 — session fb027f3e, user: "I want to start all claude sessions with their unique port so that the tmux and claude session is more easily navigated to". Commit times fit this session.
- 2026-11-06 — `468dd076 feat(claude): start session names with the session's port`: titles and tmux session names start with the port ("47950 Fix login"). `session-port.sh` sets the title at start; `auto-title.sh` adds the port to Haiku titles and to `/rename` names at the next prompt.
- 2026-11-06 — `d82235b3 fix(claude): drop the carried-over name on /clear`: `/clear` carries the old name and port into the new session, and Claude ignores a SessionStart title on `/clear`. The hook records the carried name and the first prompt sets the port alone; Haiku then names it.
- 2026-11-06 — `b016cc17 fix(claude): keep headless runs out of session naming`: `claude -p` and SDK runs keep Claude's own title. They show `CLAUDE_CODE_SESSION_ATTENDED=0` and no `CLAUDE_JOB_DIR`; `claude --bg` sets a job dir and keeps the port. Also fixes a headless run in an agent's pane renaming that tmux session back to "main" at SessionEnd.
- 2026-11-06 — session 4d83f96c, user: "sessions should be renamed based on the branch they are going to be working in. if I clear a session and start work on the session again we should really just append a `Part <number>` to the session so that they are grouped".
- 2026-11-06 — `e13918c7 feat(claude): name sessions by branch and part`: the session takes the branch from `agt worktree create` output, a cwd moved into a linked worktree, or the worktree it starts in. After `/clear` the next prompt names it "<old name> Part N". tmux takes the name at once; Claude takes it at the next prompt.
- 2026-11-06 — `24756ce6 fix(claude): fit branch names beside the port`: a long branch was dropped whole by the 60-character word-break cut. The branch is cut to 54 bytes, a split UTF-8 character is dropped, and a branch that cleans to nothing names nothing.
- 2026-11-06 — `05cc1ad4 fix(claude): rename only on a move to another branch`: CwdChanged fires on every `cd`, so a `cd` in the same worktree replaced names from `claude -n`, `/rename` and Part N. The hook remembers the last branch it used, per Claude process, and renames only for another branch.
- 2026-11-06 — `0cc5217a fix(claude): let /rename beat a pending branch`: a `/rename` between finding a branch and the next prompt was replaced by the branch. A different custom title at the next prompt or in tmux now wins. Worktrees made by a sub-agent (hook input has `agent_id`) no longer rename the main session.
- `a7fe4bff` is the same change as `b016cc17` (same time, same files, same subject), the id session fb027f3e reported before another session's pull and push; the id changed, probably by a rebase (not checked). Both ids resolve in the repo.

## Results
No measurement. Known instead: each follow-up commit above was a bug fix found while building the feature (same-day, 2026-11-06): the `/clear` carry-over, headless runs and a tmux rename bug, long branch names, repeated `cd` renames, and `/rename` losing to a pending branch. Session fb027f3e ended with 24 tests passing and a reviewer who found no defect but raised two points (background sessions and a `claude -p` run in a pane), both handled in `b016cc17`. No later complaint or revert found; `0cc5217a` is the latest commit touching these files.

## Sources
- [Claude Code hooks reference](https://code.claude.com/docs/en/hooks) — SessionStart `sessionTitle` "Sets the session title, with the same effect as /rename. Applies when source is startup, resume, or fork". SessionStart input carries `session_title` ("a hook that emits sessionTitle can check this field first to avoid overwriting an existing custom title"). UserPromptSubmit `sessionTitle`: "Use to name sessions automatically based on the prompt content"; it also receives `session_title`.
- Same page, CwdChanged — fires "when Claude executes a cd command", no matcher, no decision control. The doc does not say whether it fires for sub-agents.
- Same page, print mode — a fetch asked whether SessionEnd/Stop fire in `claude -p`; the summary said the excerpt did not settle it (only `terminalSequence` is ignored in `-p`). `b016cc17` (keep headless runs out of naming) is not backed by a doc quote.
- [Claude Code sessions](https://code.claude.com/docs/en/sessions) — generated titles are not custom titles.

## Evidence
Fetched and quoted by a sub-agent. "A hook cannot clear a title on /clear" was checked in the installed 2.1.299 binary, not from docs. Sessions 27c2f151 (2026-10-14), fb027f3e (2026-11-06, port prefix and /clear), 4d83f96c (2026-11-06, branch and part; fetched the CwdChanged text). Commits 468dd076, d82235b3, b016cc17 are matched to fb027f3e by commit time; 24756ce6, 05cc1ad4, 0cc5217a are matched to 4d83f96c by time and not seen in its transcript. For headless detection, fb027f3e compared the environment of `claude -p` and `claude --bg` hooks: only `--bg` sets `CLAUDE_JOB_DIR`.
