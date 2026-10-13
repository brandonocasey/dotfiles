# CLI tools for cleanup

Prefer installed tools. Verify local help and cleanup semantics before use; tools do
not replace ownership, active-process, content, merge, or approval checks.

- **Disk inventory:** use the first installed tool in this order: `dust`, `gdu`,
  `ncdu`, then the fallback. Stay on one filesystem, never dereference symlinks, and
  cap output. Send scan errors to `"$err"`, a file in the task scratch directory, and
  report its line count. Use depth 1 for a full-disk first pass.
  - `dust` (quick summary): `dust -x -d 2 -n 30 -b -P <path> 2>>"$err"`. Its JSON
    (`-j`) is a capped snapshot with human-readable size strings, so do not treat it as a full scan.
  - `gdu` (saved full scan): `gdu -x -n <path>`; ncdu-compatible JSON: `gdu -x -o <file>.json <path>`.
    Homebrew coreutils installs GNU `du` as `gdu`, and Homebrew's real tool is then
    `gdu-go`. Use `gdu-go` when present. Otherwise use `gdu` only if
    `gdu --version` names gdu, not GNU coreutils.
  - `ncdu`: export without the UI: `ncdu -1xo- <path> > <file>.json`.
  - Fallback: `du -xh -d 2 <path> 2>>"$err" | sort -rh | head -30` for directories;
    `find <path> -xdev -type f -size +500M -exec ls -lh {} + 2>>"$err" | sort -k5 -rh | head -30`
    for large files. `df` reports capacity and free space.
  - Save JSON scans in the task scratch directory. Never run interactive TUIs (`ncdu`
    browser, interactive `gdu`, `dua`, `diskonaut`); they need a human at the keyboard.
- **Docker:** use `docker system df` to read usage. Before proposing a prune, explain
  exactly what it removes. Never include volumes; the main skill's container rules apply.
- **Worktrees:** use `git worktree list --porcelain -z` for discovery and follow
  [agent-resources.md](agent-resources.md) for qualification and removal. `git worktree
  prune` removes stale administrative records, not checkout contents; dry-run and verify
  missing mounts first.
- **Rust build outputs:** installed `cargo clean` supports `--dry-run` and explicit
  `--manifest-path`/`--target-dir`. Resolve the effective target directory (configuration,
  environment, hook overrides) and preview each inactive target independently. The default
  clean deletes the whole target directory, including executables and reports placed there;
  use it only when that entire scope qualifies, and never substitute it for a
  partial-intermediates approval. Check the whole owning worktree for active consumers before
  preview and removal.
- **Caches and sessions:** prefer each producer’s supported operations, such as
  `ccache --clear` and `codex delete --force <UUID>`, only within verified approved scope.
  Inspect installed help rather than assuming every compiler cache supports clearing.

## Scan roots and coverage

Read when choosing full-disk scan roots, listing temp/trash/snapshot locations, or
explaining a gap between the scan total and `df`.

- Full-disk scan roots:
  - Linux: scan `/` on one filesystem, which skips `/proc`, `/sys`, `/dev`, and `/run`.
    Scan separately mounted `/home`, `/var`, or `/data` as their own roots.
  - macOS: scan `/System/Volumes/Data`, not the sealed read-only system volume at `/`,
    which firmlinks to it.
  - WSL: scan the Linux filesystem. Windows drives under `/mnt/<letter>` are a separate
    scan; mention them and scan them only on request.
- Temp: `/tmp`, `/var/tmp`, `$TMPDIR` when set, and on macOS `/private/var/folders`.
  On macOS these overlap: `/tmp` and `/var/tmp` link into `/private`, and
  `$TMPDIR` sits inside `/private/var/folders`. Count each once. Temp roots hold live
  sockets, locks, and running apps' and agents' working files. Swap and sleep images
  are `/private/var/vm` on macOS.
- Current user's trash only: `~/.Trash` and `/Volumes/<name>/.Trashes/<uid>` on
  macOS; `${XDG_DATA_HOME:-~/.local/share}/Trash`, `<mount>/.Trash/<uid>`, and
  `<mount>/.Trash-<uid>` on Linux.
- macOS local snapshots: `tmutil listlocalsnapshots <mount>` for each APFS volume.
  `tmutil` lists no sizes, so report size unknown. Deleting one removes that restore
  point; the command is `tmutil deletelocalsnapshots`.
- Many permission errors under `~/Library`, `~/.Trash`, or other protected macOS folders
  mean the terminal app lacks Full Disk Access. Tell the user to grant it in System
  Settings > Privacy & Security > Full Disk Access. Do not work around it.
- Gaps between the scan total and `df` used space:
  - unreadable directories;
  - deleted files still held open (Linux: `lsof +L1`);
  - macOS local snapshots, and APFS purgeable space, which scanners cannot see;
  - other mounts skipped by the one-filesystem limit;
  - ext4 root-reserved blocks;
  - Linux journals (`journalctl --disk-usage`).
