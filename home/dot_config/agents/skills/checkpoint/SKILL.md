---
name: checkpoint
description: >
  Dump the current session's working state into a checkpoint file in the repo so a fresh
  session or a second agent can resume cold: goal, decisions made, work done, remaining
  steps, key file paths, and gotchas. Use when the user says "checkpoint", "save a
  checkpoint", "write a handoff", "make a plan file for another agent", "save state so we
  can continue later", or invokes /checkpoint. Also resumes from an existing checkpoint
  when invoked with a path or asked to continue from one.
---

Write (or resume from) a checkpoint file that lets a context-free agent continue this work.

## Writing a checkpoint

1. **Location**: `.checkpoints/<slug>.md` at the repo root (create the dir; add
   `.checkpoints/` to `$(git rev-parse --git-common-dir)/info/exclude` if not already
   ignored — not a literal `.git/` path, which breaks in linked worktrees where `.git` is a
   file. Checkpoints are scratch, never committed unless the user asks). `<slug>` = short kebab-case name for the task,
   e.g. `playlist-loader-refactor`. If a checkpoint for this task already exists, update it
   in place — don't create a second file for the same task.
2. **Content** — write for someone with ZERO context from this conversation. No shorthand,
   no codenames invented mid-session, no "as discussed". Sections:

   ```markdown
   # <Task title>
   Updated: <ISO date> | Repo: <path> | Branch: <branch> @ <short sha> | Worktree: <path or "main checkout">

   ## Goal
   One or two sentences: what done looks like, and why (link the JIRA/MR/issue if there is one).

   ## Done
   - What has been completed, each with the file(s) touched and commit sha if committed.
   - Note anything verified (tests run, MCP repro, etc.) vs merely written.

   ## Remaining
   - Ordered, smallest-step-first list. Each step names the file(s)/function(s) it touches.
   - Mark blockers explicitly (waiting on X, unknown Y).

   ## Key files
   - path — one line on why it matters to this task.

   ## Gotchas / decisions
   - Non-obvious constraints, dead ends already tried, decisions the user made and why.
   - Anything the user corrected during the session (these WILL be repeated by a fresh agent otherwise).

   ## How to verify
   - Exact commands (test/lint/build) and any manual/MCP verification steps used so far.
   ```

3. **Uncommitted work**: if the tree is dirty, say so in the checkpoint with a
   `git status --short` snapshot. Do NOT commit or stash — just record the state.
4. After writing, print the file path and a one-line summary of Remaining.

## Resuming from a checkpoint

When invoked with a path (`/checkpoint <file>`) or asked to "continue from the checkpoint":
read it, verify the recorded branch/sha/worktree still match reality (`git status`,
`git log --oneline -3`), flag any drift, then start on the first Remaining item. Keep the
checkpoint updated as items complete: move them to Done, and refresh the header sha.
