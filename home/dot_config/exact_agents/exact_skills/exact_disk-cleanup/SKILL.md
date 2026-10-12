---
model: claude-sonnet-5-5
effort: medium
disable-model-invocation: true
name: disk-cleanup
description: "Find what uses disk space and large files in a directory or the whole disk, then reclaim space from regenerable caches, builds, containers, trash, merged worktrees, and old sessions."
---

Measure the host, preview exact candidates ranked by reclaimable bytes, then remove
approved items. Work locally unless the user explicitly requests a remote host.
A dry run ends at the preview. A request only to find what uses space or to list
large files ends at the report. It writes only scan files to the task scratch
directory. It skips agent-resource and worktree inventory unless the user asks.
Scan the full disk when the user says "my disk" or "the whole drive", or gives no
path. Announce the full-disk scan before starting it. Honor narrower scope, such as a
path the user names. Ask when the path is ambiguous in any other way.

**Preview, approve, remove, verify** owns authorization and
automatic execution; every removal keeps its audit preview and pre-deletion rechecks.

Read `host-preflight` and its `references/task-resources.md`, then run
`agent-preflight`. Do not install tools merely to expand cleanup coverage. For agent
resources, also read `worktree`, `session-resume`, and
[agent-resources.md](references/agent-resources.md) before inventory or removal.
For merged-worktree cleanup, follow **Merged or landed worktrees** in
agent-resources.md; it owns the `worktree-cleanup` component and its limits. Read
[tools.md](references/tools.md) when selecting inventory or cleanup commands.

## Measure and discover

- Run `df -h` first. It is the ground truth for used and free space per filesystem.
  Report each APFS container once, because its volumes share free space. Report macOS
  auxiliary volumes (VM, Preboot, Update) for capacity only.
- Full-disk scan roots. Never cross into other mounts unless the user asks to include them:
  - Linux: scan `/` on one filesystem, which skips `/proc`, `/sys`, `/dev`, and `/run`.
    Scan separately mounted `/home`, `/var`, or `/data` as their own roots.
  - macOS: scan `/System/Volumes/Data`, not the sealed read-only system volume at `/`,
    which firmlinks to it.
  - WSL: scan the Linux filesystem. Windows drives under `/mnt/<letter>` are a separate
    scan; mention them and scan them only on request.
- Cover home, platform/XDG cache and data locations, discovered project roots,
  downloads, system caches and logs, and these:
  - Temp: `/tmp`, `/var/tmp`, `$TMPDIR` when set, and on macOS `/private/var/folders`.
    On macOS these overlap: `/tmp` and `/var/tmp` link into `/private`, and
    `$TMPDIR` sits inside `/private/var/folders`. Count each once.
  - Current user's trash only: `~/.Trash` and `/Volumes/<name>/.Trashes/<uid>` on
    macOS; `${XDG_DATA_HOME:-~/.local/share}/Trash`, `<mount>/.Trash/<uid>`, and
    `<mount>/.Trash-<uid>` on Linux.
  - macOS local snapshots: `tmutil listlocalsnapshots <mount>` for each APFS volume.
- Resolve aliases, avoid symlink loops, and deduplicate overlapping entries and
  hard-linked files. Do not use `sudo` unless the user asks. Without it, unreadable
  directories are skipped, so say totals may be undercounted. Report every root that
  could not be read, such as other users' files.
- Many permission errors under `~/Library`, `~/.Trash`, or other protected macOS folders
  mean the terminal app lacks Full Disk Access. Tell the user to grant it in System
  Settings > Privacy & Security > Full Disk Access. Do not work around it.
- Scan once. A full-disk scan can take minutes, so run it in the background or with a
  generous timeout. Save its output, as a JSON export when the tool supports one, and
  query that file with `jq` instead of rescanning.
- Cap every scan's depth and result count. For a full disk, pass 1 is depth 1 from
  each root; pass 2 rescans each of the top 3–5 entries one level deeper. For a single
  directory, start at depth 2 with about 30 results. Repeat one level deeper only
  until the largest items are identifiable.
- Redirect scan errors to a file in the task scratch directory, not the terminal.
  Never discard them, because an unreadable root otherwise looks like a complete
  scan. Count them for the coverage report.
- Reconcile the scan total with `df` used space. When the scan accounts for much
  less, report the gap and its likely causes; never guess silently. Check:
  - unreadable directories;
  - deleted files still held open (Linux: `lsof +L1`);
  - macOS local snapshots, and APFS purgeable space, which scanners cannot see;
  - other mounts skipped by the one-filesystem limit;
  - ext4 root-reserved blocks;
  - Linux journals (`journalctl --disk-usage`).
- Drill into large entries before prioritizing small logs. Common candidates include
  compiler caches (sccache, ccache, Go), package download caches (npm, yarn, pip, uv,
  pnpm, Cargo, Homebrew; Gradle's `caches/` and downloaded Maven artifacts only, never
  their settings, credentials, or locally installed artifacts), project build/test outputs and dependencies,
  browser automation downloads/profiles, container images/build caches, Xcode
  DerivedData and unavailable simulators, package manager leftovers (`apt clean`,
  `brew cleanup`), Linux journals (`journalctl --vacuum-size=<size>`), and trash. Discover their actual
  paths from installed tools and safe configuration path fields, not names alone.
- Use installed tools' read-only usage/status/dry-run operations where available.
  Inspect cleanup command semantics before proposing them; an “unused” resource may
  still support stopped containers, an offline workflow, or an unfinished task.
- Inventory agent resources using the linked reference, including external and legacy
  worktrees. Session retention defaults to 30 elapsed days and applies only to sessions.

## Qualify and preserve

- Classify each entry by producer, purpose, regeneration source, and active consumers.
  Cache locations, ignore rules, age, and large size alone do not prove disposability.
  Check process working directories, open files, tool locks, and unfinished task records.
  Keep uncertain entries; never kill another task to make cleanup possible.
- Dependencies and generated project outputs can qualify independently of their
  checkout, including an unmerged worktree, when sources/lockfiles remain and no active
  process or task needs them. Inspect contents for manual additions, credentials,
  requested artifacts, and unknown files. Retain those entries. Explain the rebuild or
  download cost and any offline availability lost.
- Prefer supported cache cleanup operations. Verify their complete scope: a command
  covering more than the approved entries needs a new preview and approval. A shared
  cache requires a verified producer and supported concurrency guarantees, or proven
  absence of active consumers. Never delete lockfiles to bypass ownership checks.
- Browser profiles may contain login state; installed browsers, runtimes, skills, and
  plugins are not ordinary caches. Keep these unless the user approves their specific
  removal and their consumers are known. Container volumes and writable layers can
  contain durable data; do not include them in generic prune operations. Inspect exact
  image/build-cache identities and references before proposing removal.
- Preserve source, Git refs, settings, authentication, databases, memory, task/recovery
  records, backups, requested deliverables, unused copy files, and unknown content.
  Do not remove downloads, trash contents, temp files, or system logs merely because
  they are old; show their contents/purpose and restoration limits for specific approval.
  A request that names that set, such as "empty my trash", approves it after the
  preview. A broader category authorization, such as "clean caches", does not.
  Emptying trash cannot be undone. Do not delete shared history or edit application
  databases/indexes by hand.
- Temp directories hold live sockets, locks, and running apps' and agents' working
  files. A temp entry qualifies only if the current user owns it, no process has it
  open, and its producer is known. Never clear a temp root wholesale. Measure swap
  and sleep images (`/private/var/vm` on macOS) and system-volume contents, but never
  propose or delete them.
- Report local snapshots as needing review, with size unknown; `tmutil` lists no sizes.
  Deleting one removes that restore point. Its command is `tmutil deletelocalsnapshots`.
- A cleanup that needs root, such as `apt clean`, `journalctl --vacuum-size`, or
  snapshot deletion, still goes in the preview with its exact `sudo` command. Unless
  the user asked you to use `sudo`, give them that command to run themselves.
- Mark VM images, databases, photo/video libraries, device (iOS) backups, other
  backups, and files under `/var/lib` or other system paths as needing user review,
  never as cleanup candidates. Never delete files there directly or propose deleting
  system directories. The owning tool's supported cleanup, such as `docker`, `apt`, or
  `journalctl`, is the only exception.

## Worktree priority and task resources

- First run the required `worktree-cleanup` step to qualify whole merged/landed worktrees. For retained
  checkouts, independently qualify inactive build outputs and linked scratch. Do not
  keep a merged worktree solely because it contains proven regenerable files; classify
  those files under `worktree` preservation/removal checks. Unknown files and requested
  deliverables still protect the checkout.
- Automatically clean this task’s known disposable resources as authorized by
  `host-preflight/references/task-resources.md`. Other tasks’ shared scratch requires
  its own ownership/disposal evidence and authorization. Keep a batch moving when
  individual entries are protected, changed, or fail.
- Do not add cron jobs or timers unless recurring cleanup is explicitly requested.

## Pair worktrees with their build outputs and shared scratch

- For every discovered worktree, inventory build targets and task scratch separately
  from the checkout. An unmerged or dirty checkout need not be deleted to reclaim its
  regenerable build outputs. A process using any descendant protects the whole
  worktree from build cleanup; recheck immediately before removal. Unfinished durable
  tasks protect outputs they still need, even when no process is running.
- Establish build-output provenance from the project's build configuration and actual
  contents (for example Cargo target fingerprints), and verify no tracked files or
  manual artifacts would be removed. Do not apply a recursive directory-name match to
  arbitrary projects. Keep installed tools and requested executables/artifacts.
- Link external scratch to a worktree/task using durable records, session metadata,
  inspected producer scripts/logs, or an explicit resource manifest. A similar directory
  name is only a discovery hint, never ownership proof. For future task resources,
  record canonical worktree, task/session ID, producer, purpose, and resource paths in
  the existing durable task record or a private resource manifest. Do not move older
  scratch directories or introduce a new registry when existing records suffice.
- Preview linked scratch entries alongside each worktree/build candidate. Classify
  each entry independently: regenerable test data, compiler caches, logs and helpers
  may qualify; screenshots/reports, databases, source, credentials, recovery data and
  unknown files remain protected unless their disposal is separately established.
  A mixed scratch directory can have eligible children without deleting the parent.
- Include eligible external scratch in the same approval batch, even if the checkout
  remains. Removing a worktree does not authorize deleting external scratch. Never
  remove shared entries until every consumer is accounted for. After approved worktree
  removal, recheck and clean its approved scratch paths; on failure or new activity,
  retain dependent scratch and report why. Verify both paths and retained artifacts.

## Report

Every run reports:

- used and total space from `df`, and how much of it the scan accounted for;
- the top 5–10 consumers by path and size, each with a one-line note on what it is;
- anything the scan could not see, such as unreadable folders, snapshots, and other mounts.

An analysis-only request stops here.

## Preview, approve, remove, verify

- Show category, canonical path or tool resource ID, allocated size, activity where
  relevant, disposal/merge evidence, remove/keep reason, and the exact cleanup command
  for each removal. Rank by reclaimable bytes,
  count overlaps once, and distinguish apparent size from estimated disk recovery.
  State what cannot be restored and what must be downloaded or rebuilt. Retained Git refs
  allow worktree recreation; deleted transcripts and unbacked cache contents are not restorable.
- Obtain approval for the exact deletion set unless the current request or recorded
  approval explicitly authorizes removal of specified categories within specified
  roots. With that authorization, show the read-only deletion preview, record the
  authorization and its scope with it, and execute qualifying entries without another
  confirmation; do not repeat unchanged authorization requests. If authorization is
  missing, ask once for the concrete combined batch, not once per worktree or cache.
  Expanded sets need new approval. Approval for one category does not authorize the
  rest. A preference for automation alone is not permission to delete unknown content
  or broaden scope. Tool flags that suppress prompts implement existing approval; they
  never supply it.
- Recheck identity, contents, activity and ownership before each operation. Skip changed
  entries. Never follow replacement symlinks or delete an ancestor of protected data.
  Use literal resolved paths or structured tool IDs, never broad deletion globs.
- Remove worktrees sequentially with Git from a surviving checkout; use `worktree` for
  blockers and submodules. Preserve branch refs. Prune administrative records only
  after a dry run proves they are stale, not inaccessible or unmounted.
- Use verified supported session deletion and refresh derived indexes per
  `session-resume`. Isolate failures. Stop only cleanup-owned processes, and remove
  only this run's disposable scratch.
- Re-enumerate affected resources and verify protected paths remain. Re-run `df -h`
  and report removed counts/bytes by category, observed filesystem change,
  retained reasons, coverage gaps, and partial failures. Concurrent writes and hard links can make measured
  free-space recovery differ from estimates.
