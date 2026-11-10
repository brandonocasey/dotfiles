# Task resources

Read before starting an application/preview server, creating temporary task
resources, or cleaning them up.

## Locations

Put new disposable resources in the Scratch path from AGENTS.md
**Directories**, where `<task>` is a unique task name. Keep logs, temporary
helpers, generated preview assets, and intermediate results there. When a task
works on a worktree, use that worktree's scratch, not the main checkout's or
`~/.cache/agents/scratch/`: `agt worktree remove` then deletes it with the worktree.

Before using `.cache/agents/scratch/`, verify that the candidate path is ignored
(`git check-ignore -v <candidate-path>`) and that no files under it are tracked. The
managed global ignore file supplies `/.cache/agents/`; repository rules can override
it. If it is not effective, or the root conflicts with existing project files, use the XDG
cache scratch directory and report why; do not change repository Git settings. Never reuse
or overwrite an existing task directory or follow a symlink at the scratch root or task path.

Keep credentials, preview access tokens, and private gallery state outside the repository
in private external storage. Backups, cross-session recovery records, copy files awaiting
use, and requested deliverables keep their established locations; never place them in
disposable scratch. A temporary preview may use scratch assets, but retain them for the
entire preview lifetime. Promote a file to the requested destination if the user asks to
keep it. Tools with explicit output paths keep them.

## Servers and artifacts

On koof, read `~/.config/agents/environments/koof.md` before server work.

Bind application and preview HTTP servers to `0.0.0.0`; tool-control endpoints
keep their required binding. Report `http://<lan-ip>:<port>`, never `localhost`.
Get the LAN IP with `ipconfig getifaddr en0` on macOS, `hostname -I` on Linux,
or `ipconfig` on Windows. Claude Code sessions reserve a block of ports:
`$PORT`, `$PORT_1` … `$PORT_9`. The block is for servers the user opens.
Give each such server the first block port that nothing listens on.
Without `$PORT`, give each such server and worktree its own port: `agt worktree port --env`
for a worktree (stable per worktree; needs `agt` 0.10.0), otherwise a random free port.
Automated tests and test runners never use the block. They pick their own
random free port, such as port 0. Never rely on a tool's default port:
parallel sessions and worktrees share it. Pass the same port to every start
command for the task.

## iOS Simulator

Each worktree owns one simulator; a shared one lets another worktree's install replace the app
under test (same bundle ID). Before any simulator work, get its UDID:
`sh ~/.config/agents/skills/host-preflight/scripts/ios-sim [worktree]`. It clones the shut-down
base device `ios-base` on first use, boots the clone, and prints the UDID. Each call also sends the
simulator's sound to the silent BlackHole 2ch output, so playback needs no mute; if it warns that
the simulator still plays aloud, tell the user. To hear it, see **Device sound**. Pass the UDID as
`-destination "id=<udid>"` to `xcodebuild`, never `name=`, with
`-derivedDataPath <worktree>/.cache/agents/DerivedData` so the build output goes with the
worktree instead of the shared `~/Library/Developer/Xcode/DerivedData`. Drive it from the shell, which needs no
Claude Desktop consent: `xcrun simctl` (`install`, `launch`, `io <udid> screenshot`, `openurl`,
`ui <udid> appearance`, `privacy`) and `idb` for input (`idb ui tap X Y`, `swipe X1 Y1 X2 Y2`,
`text "..."`, `describe-all`, each with `--udid <udid>`; points, origin top-left). Use the
simulator tool only when the user wants the live panel; its first use of each device asks the
user, so pass the same UDID as `device` and attach only on request. Never install onto, boot, or shut down a simulator
another worktree owns, and leave the user's own devices alone. If the script reports the base
missing or booted, ask before shutting anything down. `agt worktree remove` and `agt cleanup`
run `ios-sim rm` through the global remove hook in `~/.config/agt/config.toml`; run it yourself
only to drop a simulator while keeping its worktree.

## Android Emulator

Same rule: each worktree owns one emulator, because a shared one lets another worktree's install
replace the app under test (same application ID). Before any emulator work, get its serial:
`sh ~/.config/agents/skills/host-preflight/scripts/android-emu [worktree]`. It starts the base AVD
`android-base` read-only on a port reserved for the worktree, waits for boot, and prints the serial
(`emulator-5554`). A cold boot takes minutes, so run it with `run_in_background`. Installs vanish
when the emulator stops. It starts with no sound; to hear it, see **Device sound**. Pass the serial to every command:
`adb -s <serial>` (`install -r`, `shell am start -n`, `exec-out screencap -p > file.png`,
`shell input tap X Y`, `swipe X1 Y1 X2 Y2`, `text "..."`, `shell uiautomator dump`, `shell pm clear`),
`ANDROID_SERIAL=<serial>` for Gradle `installDebug` and `connectedAndroidTest`. Never rely on "the
only device"; pixels, origin top-left. It runs headless; set `ANDROID_EMU_WINDOW=1` only when the
user wants the live window. Linux needs the user in the `kvm` group, else the emulator fails to
start; report that, do not change groups. Never install onto, restart, or kill an emulator another
worktree owns, and leave the user's own devices alone. If the script reports the SDK or base AVD
missing, run `chezmoi apply` (it installs both), not a manual install. It reuses or kills only an
emulator it started itself, so a user emulator on a nearby port is safe. The same remove hook
runs `android-emu rm`, which stops the emulator and frees the port; run it yourself only to stop
an emulator while keeping its worktree.

## Device sound

`sh ~/.config/agents/skills/host-preflight/scripts/device-audio` lists each process sending sound
to a Mac output: owner (`ios <simulator name>`, `android emulator-<port>`, or the program), PID,
and output device. Only when the user asks to hear a worktree's devices, run `device-audio on
[worktree]`; they stay audible until `device-audio off [worktree]` or `rm`, also across restarts.
A running Android emulator restarts to switch (installs vanish), so run it with `run_in_background`.

## Cleanup

Close task-owned MCP resources, stop servers and background processes, and free
their ports before deleting their resources. Leave task dirs in place: `agt cleanup` removes `.cache/agents/scratch/<task>/`, in the
cache root and in checkouts, after 30 days untouched, and `agents/output/<task>/` after 7.
Outside them, remove only known task-owned helpers, test data, debug output, and logs, even
when an open-PR worktree stays. Inspect contents first: a Git ignore match alone is not
evidence that a file is disposable. Preserve unknown files and other tasks' directories.
Delete with literal resolved task paths, never `rm -rf "$VAR"`.

At task end, when the worktree stays, shut down its simulator
(`xcrun simctl shutdown <udid>`) and stop its emulator (`android-emu rm [worktree]`).
The next `ios-sim` or `android-emu` call starts it again. Leave one running only
while the user is using it.

When removing a worktree, its remaining disposable `.cache/agents/scratch/` contents go with
it, but directory removal does not stop processes. Remove it with
`agt worktree remove`, which backs up the worktree's commits and tracked changes, refuses while
untracked files exist (drop them with `--force` only when the user agrees they are disposable; the
plan with `--force` lists them as `untracked_lost`), and deletes its ignored files, listing the ones no build
recreates (`.env*`, credentials, notes) as `ignored_lost`.
Keep requested files and copy files awaiting use. If a helper could serve a
teammate or later task, propose a project path and let the user decide; never
leave it in the repository without consent.

Keep a server running, and retain the worktree it needs, while a requested deliverable or
live preview depends on its URL. Report its address and purpose; stop it after the user
finishes using it or requests shutdown. Never stop servers owned by other tasks. Follow
`worktree` for branch/worktree retention and removal checks; open-PR worktrees remain
available for follow-up work.
