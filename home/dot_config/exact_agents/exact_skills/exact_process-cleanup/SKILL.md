---
effort: medium
disable-model-invocation: true
name: process-cleanup
description: "Find processes using lots of memory or CPU that are probably no longer in use (old agent sessions, orphaned dev servers, simulators, headless browsers) and stop the ones the user approves."
---

Find user-owned processes that hold memory or CPU, judge from evidence whether anything
still uses them, preview the likely-stale ones, and stop the approved ones. Work locally.
A request only to find or list heavy processes ends at the report. Stopping a process loses
its unsaved state and cannot be undone, so every stop needs approval that names the PID.

Run `sh ~/.config/agents/skills/process-cleanup/scripts/proc-audit` (add `--min-mb N` or
`--top N`). It is read-only, lists only the current user's processes, and takes about 5 s,
including a 2 s CPU sample. Never use `sudo`, and never touch other users' or system processes.

## Leave out anything used in the last 24 hours

`proc-audit` omits every process that was used in the last 24 hours and prints how many it left
out. An agent session counts by its last update; anything else with a terminal counts by when the
terminal last changed. Do not list, propose, or rank those processes, even as `needs review`.
Do not rerun with `--all` to add them back. The user asked for them to be excluded, and a busy
session that is quiet for under a day is exactly what a cleanup must not interrupt. Say only the
count, and that they were left out.

## Judge use

Columns are evidence, not a verdict. Rank by how many signals agree, then by `rss_mb`:

- `age` is old, `cpu_pct_2s` is about 0, and `net` and `listening` are `no`: nothing is
  talking to it.
- `orphan` is `yes` for a `dev` or `sim-browser` process: its parent is gone, so no terminal or
  session owns it. Orphan `app` rows are normal (launchd starts apps), so ignore that signal there.
- `where` and `attached` show whether anyone can see it. `tmux:<name>` with `attached` `no` is a
  detached tmux session: running, but no client is showing it. `tmux:<name>` with `yes` has a
  client attached, so the user may be looking at it. `tty` is a plain terminal window that still
  exists (`attached` `yes`). `none` has no terminal at all. An attached session is likelier in use.
- `session` (agent rows only) is the session's name, `busy` or `idle`, minutes since its last
  update, and a short session ID. `busy` means it is working or waiting on a prompt, so it is
  never a candidate. An `idle` session that is detached and has not updated for hours is the
  strongest stale signal. The name is what the user recognises, so lead each agent line with it.
  Codex CLI sessions have no such file: `session` is `-`, so identify them by `where` and `cwd`
  and say the name is unknown. `tty_idle_h` is weak for agents (a redrawing UI keeps it at 0).
- `cwd` names the project. A process whose directory is in an active worktree or open PR is
  likelier to be wanted. Check `git -C <cwd> status` and recent commits when unsure.
- `children` shows what dies with it, such as MCP servers under an agent session, and `tree_mb`
  is the memory of it plus all of them. Shared pages count in every process, so trees overstate.

A listening port or network connection means something may be using it. Name the port, and
keep it `needs review` unless the user says it is theirs and unused.

## Find what an agent left behind

Also run `proc-audit made`. Agents start browsers, MCP servers, emulators, simulators, `adb`, and dev
servers that are often small, so the memory cutoff of the main table hides them. This table does not
use that cutoff. It lists trees nothing owns now, by `tree_mb` (the process and everything under it):

- `orphan` rows are automation browsers (headless, remote-debugging, Chrome for Testing,
  Playwright, Puppeteer), MCP servers, emulators, `adb` servers, and dev servers whose agent session
  is gone, so nothing will ever stop them. Read `command` for the origin (a `--user-data-dir` in
  a temp or `.cache` path, the owning project). When the origin is unclear, say it is unknown.
- `ios-sim` rows are booted simulators. `agent-script` means the device name starts with `wt-`, the
  name `ios-sim` gives each worktree's device; `unknown` may be one the user booted by hand.
  A simulator whose worktree is gone (`git worktree list` in each project) is the stale one.
- Trees under a live agent session are not listed: they stop with that session, and the session
  row's `tree_mb` already counts them. The summary line says how many there are.

The same 24-hour rule applies: the table leaves out trees and simulators younger than 24 hours.

## Classify

- `candidate`: an agent-made `orphan` row from `proc-audit made`, or a `dev` or `sim-browser` row, orphaned or idle with no port or connection, and not
  inside an active worktree.
- `needs review`: `agent` sessions (they may hold an unfinished conversation; list each by session
  name with `where`/`attached`, idle time and `cwd`, and say it can be resumed per
  `session-resume`; an `idle`, detached, hours-stale one is the best proposal; a `busy` or
  attached one is protected unless the user names it), `app` rows such as browsers
  and media players (leave them out of the proposal unless the user names them), and anything with a port or connection.
- `protected`: `self` is `yes`, which includes this session and its parents. Never stop it. Also
  protect processes that belong to another task per `host-preflight/references/task-resources.md`,
  and system components.

Never make a protected process a candidate to free memory. Name the one question that would
unblock it, such as "is the web-player session in a terminal you still use?"

## Preview and approve

Show a numbered list ranked by `rss_mb`. One line per process: PID, program (agent: session name), `cwd`, age,
memory, attachment, and the evidence that it is idle. Add what stopping it loses and what stops with it
(`children`). Give the exact command, for example
`sh ~/.config/agents/skills/process-cleanup/scripts/proc-audit stop 4242@TueOct2710:57:312026`.

Ask once for the exact set. The user's approval must name the PIDs, or name a category
and root you listed, such as "the orphaned node servers". Do not widen the set later.

## Stop and verify

- Run `proc-audit stop PID@START ...` with `PID@START` copied from the preview. It rechecks
  owner and start time, so a reused PID is never stopped, and it sends SIGTERM and waits 10 s.
- Stop a simulator or emulator through its owner, never by killing its helper processes, which
  respawn. iOS: find the device with `xcrun simctl list devices booted`, then
  `xcrun simctl shutdown <udid>`. Android: `adb -s <serial> emu kill`. An `adb-server` row:
  `adb kill-server` (it restarts on demand). A device whose worktree
  no longer exists (`git worktree list` in each project) is the stale one.
- Use `--force` (SIGKILL) only for a process that survived SIGTERM, and only after the user
  approves that PID again. SIGKILL skips cleanup and can leave lock files or sockets.
- Rerun `proc-audit` after the stop. Report each process as stopped, still running, or
  skipped with the reason, any orphans the stop left behind, and the change in memory
  (`memory_pressure` and `sysctl vm.swapusage` on macOS, `free -m` on Linux).
- Do not install tools, add cron jobs or timers, or change app settings to prevent
  recurrence unless the user asks.
