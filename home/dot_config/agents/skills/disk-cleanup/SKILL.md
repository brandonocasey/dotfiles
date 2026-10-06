---
model: claude-sonnet-5-5
effort: medium
name: disk-cleanup
description: >
  Find and reclaim local disk space from regenerable caches, build outputs,
  unused container resources, trash, and merged agent worktrees or old sessions.
  Use for disk space, disk cleanup, or agent housekeeping requests.
---

# Reclaim local disk space

Measure the host, preview exact candidates ranked by reclaimable bytes, then remove
approved items. Work locally unless the user explicitly requests a remote host.
Creating or editing this skill does not invoke cleanup. A dry run ends at the preview.
Honor narrower scope and existing approval; expanded deletion sets need approval.
Prefer automatic execution within authorized scope, with an audit preview and
pre-deletion rechecks; do not repeatedly request unchanged authorization.

Read `host-preflight` and its `references/task-resources.md`, then run
`agent-preflight`. Do not install tools merely to expand cleanup coverage. For agent
resources, also read `worktree`, `session-resume`, and
[agent-resources.md](references/agent-resources.md) before inventory or removal.
For merged-worktree cleanup, explicitly run the `clean-merged-worktrees` workflow
as the repository component; use its merge checks and `worktree` preservation
rules. This invocation authorizes that component, not its optional branch/review
deletion paths. Keep local branch refs. Read
[tools.md](references/tools.md) when selecting inventory or cleanup commands.

## Measure and discover

- Start with filesystem capacity and free space, then allocated sizes of the largest
  directories. Inspect home, platform/XDG cache and data locations, discovered project
  roots, downloads, trash, and accessible system cache/log locations. Stay within each
  filesystem, resolve aliases, avoid symlink loops, and deduplicate overlapping entries
  and hard-linked files. Report inaccessible roots and incomplete scans.
- Drill into large entries before prioritizing small logs. Common candidates include
  compiler caches (sccache, ccache, Go), package download caches (npm, pip, uv, pnpm,
  Cargo, Homebrew), project build/test outputs and dependencies, browser automation
  downloads/profiles, container images/build caches, and trash. Discover their actual
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
  Do not remove downloads, trash contents, or system logs merely because they are old;
  show their contents/purpose and restoration limits for specific approval. Do not
  delete shared history or edit application databases/indexes by hand.

## Automatic execution and worktree priority

- First qualify whole merged/landed worktrees with `clean-merged-worktrees`. For retained
  checkouts, independently qualify inactive build outputs and linked scratch. Do not
  keep a merged worktree solely because it contains proven regenerable files; classify
  those files under `worktree` preservation/removal checks. Unknown files and requested
  deliverables still protect the checkout.
- When the current request or recorded approval explicitly authorizes removal of
  specified categories within specified roots, write/show the read-only deletion
  preview and execute qualifying entries without another confirmation. Record that
  authorization and its scope with the preview. Tool flags that suppress prompts
  implement existing approval; they never supply it.
- Automatically clean this task’s known disposable resources as authorized by
  `host-preflight/references/task-resources.md`. Other tasks’ shared scratch requires
  its own ownership/disposal evidence and authorization. Keep a batch moving when
  individual entries are protected, changed, or fail.
- If authorization is missing, ask once for the concrete combined batch rather than
  once per worktree/cache. A preference for automation alone is not permission to
  delete unknown content or broaden scope. Do not add cron jobs or timers unless
  recurring cleanup is explicitly requested.

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

## Preview, approve, remove, verify

- Show category, canonical path or tool resource ID, allocated size, activity where
  relevant, disposal/merge evidence, and remove/keep reason. Rank by reclaimable bytes,
  count overlaps once, and distinguish apparent size from estimated disk recovery.
  State what cannot be restored and what must be downloaded or rebuilt.
- Obtain approval for the exact deletion set unless that action and scope are already
  explicitly approved. Approval for one category does not authorize the rest.
- Recheck identity, contents, activity and ownership before each operation. Skip changed
  entries. Never follow replacement symlinks or delete an ancestor of protected data.
  Use literal resolved paths or structured tool IDs, never broad deletion globs.
- Remove worktrees sequentially with Git from a surviving checkout; use `worktree` for
  blockers and submodules. Preserve branch refs. Prune administrative records only
  after a dry run proves they are stale, not inaccessible or unmounted.
- Use verified supported session deletion and refresh derived indexes per
  `session-resume`. Isolate failures. Stop only cleanup-owned processes, and remove
  only this run's disposable scratch.
- Re-enumerate affected resources and verify protected paths remain. Measure free space
  again and report removed counts/bytes by category, observed filesystem change,
  retained reasons and coverage gaps. Concurrent writes and hard links can make measured
  free-space recovery differ from estimates. Do not schedule recurring cleanup unless asked.
