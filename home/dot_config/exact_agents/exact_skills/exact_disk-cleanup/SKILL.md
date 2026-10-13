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

Authorization and execution follow **Preview, approve, remove, verify**; every removal keeps
its audit preview and pre-deletion rechecks.

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
- Scan one filesystem per root and never cross into other mounts unless the user asks.
  Cover home, platform/XDG cache and data locations, discovered project roots,
  downloads, system caches and logs, temp roots, the current user's trash, and macOS
  local snapshots. Per-OS roots, temp/trash paths, and Full Disk Access:
  [tools.md](references/tools.md) **Scan roots and coverage**.
- Resolve aliases, avoid symlink loops, and deduplicate overlapping entries and
  hard-linked files. Do not use `sudo` unless the user asks. Without it, unreadable
  directories are skipped, so say totals may be undercounted. Report every root that
  could not be read, such as other users' files.
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
- Reconcile the scan total with `df` used space. Report any large gap and its likely
  causes, never a silent guess; checklist in [tools.md](references/tools.md).
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
  records, backups, requested deliverables, unused copy files, and unknown content. Do not
  delete shared history or edit application databases/indexes by hand. Do not remove
  downloads, trash contents, temp files, or system logs merely because they are old; show
  their contents/purpose and restoration limits for specific approval. A request that names
  that set, such as "empty my trash", approves it after the preview; a broader category
  such as "clean caches" does not. Emptying trash cannot be undone.
- A temp entry qualifies only if the current user owns it, no process has it
  open, and its producer is known. Never clear a temp root wholesale. Measure swap
  and sleep images and system-volume contents, but never propose or delete them.
  Report local snapshots as needing review; details in [tools.md](references/tools.md).
- A cleanup that needs root, such as `apt clean`, `journalctl --vacuum-size`, or
  snapshot deletion, still goes in the preview with its exact `sudo` command. Unless
  the user asked you to use `sudo`, give them that command to run themselves.
- Mark VM images, databases, photo/video libraries, device (iOS) backups, other backups, and
  files under `/var/lib` or other system paths as needing user review, never as cleanup
  candidates; delete there only through the owning tool's supported cleanup (`docker`,
  `apt`, `journalctl`).

## Worktrees, build outputs, and task resources

- First run the required `worktree-cleanup` step to qualify whole merged/landed worktrees. For
  retained checkouts, independently qualify inactive build outputs and linked scratch (see
  the dependencies bullet above); classify them under `worktree` preservation/removal checks.
  Unknown files and requested deliverables still protect the checkout.
- Inventory each worktree's build targets and task scratch separately from the checkout.
  A process using any descendant protects the whole worktree from build cleanup; unfinished
  durable tasks protect outputs they still need. Rules:
  [agent-resources.md](references/agent-resources.md) **Build outputs and linked scratch**.
- Automatically clean this task's known disposable resources as authorized by
  `host-preflight/references/task-resources.md`. Other tasks' shared scratch requires its own
  ownership/disposal evidence and authorization. Keep a batch moving when individual entries
  are protected, changed, or fail.
- Do not add cron jobs or timers unless recurring cleanup is explicitly requested.

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
- Obtain approval for the exact deletion set, or for specified categories within specified
  roots when the current request or a recorded approval names them. With that authorization,
  show the read-only deletion preview, record the authorization and scope with it, and execute
  qualifying entries without re-asking. Otherwise ask once for the concrete combined batch.
  Expanded sets and other categories need new approval. A preference for automation, or tool
  flags that suppress prompts, never supply approval or broaden scope.
- Recheck identity, contents, activity and ownership before each operation. Skip changed
  entries. Never follow replacement symlinks or delete an ancestor of protected data.
  Use literal resolved paths or structured tool IDs, never broad deletion globs.
- Use verified supported session deletion and refresh derived indexes per
  `session-resume`. Isolate failures. Stop only cleanup-owned processes, and remove
  only this run's disposable scratch.
- Re-enumerate affected resources and verify protected paths remain. Re-run `df -h`
  and report removed counts/bytes by category, observed filesystem change,
  retained reasons, coverage gaps, and partial failures. Concurrent writes and hard links can make measured
  free-space recovery differ from estimates.
