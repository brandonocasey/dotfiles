---
effort: medium
disable-model-invocation: true
name: resource-cleanup
description: "Free disk space and memory in one pass: find large reclaimable files (disk-cleanup) and heavy processes that are probably unused (process-cleanup), then act on what the user approves."
---

Runs `disk-cleanup` and `process-cleanup` as one task with one combined preview. The user's
request to this skill is the explicit request for both. Neither skill can be loaded with the Skill
tool, so read `~/.config/agents/skills/disk-cleanup/SKILL.md` and
`~/.config/agents/skills/process-cleanup/SKILL.md` whole before starting. Their rules apply
unchanged: qualification, protection, preview contents, approval wording, and verification.
This skill adds only the ordering below.

A request to find or list only (no cleanup) ends after the combined report. A request for just
disk or just processes belongs to the single skill. Honor a narrower scope such as a path or a
program the user names.

## Order

1. Baseline: `df -h` and the memory state (`memory_pressure` and `sysctl vm.swapusage` on
   macOS, `free -m` on Linux).
2. Inventory processes first, then disk. Processes first because a running process protects
   worktrees, build outputs, and caches in disk-cleanup, so the disk preview should already
   reflect which ones are held. Run the two inventories in parallel when they are independent.
3. Report in two sections, never one merged ranking: disk by reclaimable bytes, processes by
   resident memory. The units differ, and a merged list would hide one side.
4. One combined preview and one approval request for the concrete batch. Keep each item's
   own evidence, loss, and command as its skill requires.
5. Execute approved process stops first. Then recheck disk entries before removal: a stopped
   process can free a worktree or cache that was protected at preview time. Show these as
   new `candidate` rows needing their own approval, and do not delete them this run unless
   the approval already covers them by name or by an approved category and root.
6. Verify both sides: `df -h` and the memory state again, with what was removed, stopped,
   retained, and why, plus coverage gaps from either skill.

Stopping a process never makes anything else a candidate on its own, and a disk candidate
never justifies stopping a process. Each action is judged by its own skill.
