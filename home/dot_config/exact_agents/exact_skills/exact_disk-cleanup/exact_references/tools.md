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
- **Worktrees:** use `git worktree list --porcelain -z` for discovery, the existing
  `worktree-cleanup` skill for live merge qualification, and `worktree` for
  preservation/removal. Use a documented repository removal helper only after
  inspecting it and completing those checks. `git worktree prune` removes stale
  administrative records, not existing checkout contents; dry-run and verify missing
  mounts first. Third-party worktree managers are optional, not a substitute for
  forge evidence, process ownership, retained branches and ignored-file classification.
- **Rust build outputs:** installed `cargo clean` supports `--dry-run` and explicit
  `--manifest-path`/`--target-dir`. Resolve the effective target directory, including
  configuration/environment overrides and custom hook targets. Preview each exact
  inactive target independently. The default clean deletes the whole target directory,
  including executable and report files placed there; use it only when that entire
  scope qualifies. For a partial-intermediates approval, retain that scope instead of
  substituting a full clean. Use offline/locked operation where supported, and check
  the whole owning worktree for active consumers before both preview and removal.
- **Optional Rust batch tool:** [cargo-clean-all](https://github.com/dnlmlr/cargo-clean-all)
  supports dry-run, size/age filters and executable preservation. If installed, it can
  assist discovery over bounded roots. Its filters do not establish idleness or
  ownership, and it deletes target directories directly; inspect the exact output and
  apply only independently qualified targets. Do not run a blanket recursive `--yes`.
  [cargo-sweep](https://github.com/holmgr/cargo-sweep) supports selective artifact cleanup
  but currently declares itself unmaintained; verify current status before adopting it.
- **Caches and sessions:** prefer each producer’s supported operations, such as
  `ccache --clear` and `codex delete --force <UUID>`, only within verified approved scope.
  Inspect installed help rather than assuming every compiler cache supports clearing.
  Session deletion still follows retention, pinning, sidecar and task checks.

No third-party CLI accounts for this host’s durable task records and external shared
scratch automatically. Pair those resources through the ownership evidence in the
main skill, then include them in the same audited cleanup batch.
