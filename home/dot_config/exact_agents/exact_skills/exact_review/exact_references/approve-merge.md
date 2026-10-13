## 7. Optional: --approve, --auto-merge, --merge

Each flag is the user's request to approve or merge the reviewed MR/PR
([git-policy.md](../../shared/git-policy.md)), for MRs/PRs the user names or
authored only. Local targets: report `Merge: not run (local target)`.

- `--approve`: approve the MR/PR at its reviewed head.
- `--auto-merge`: enable auto-merge, read the state back, and stop.
- `--merge`: enable auto-merge, then watch until merged or blocked.

`--auto-merge` and `--merge` never imply approval. Combine them with `--approve` for that.

Run this step last: after step 4's push when `--fix` applies, otherwise after step 3.

1. **Gate**: run only when no `bug`, `requirement`, or `question` finding remains
   unfixed. Otherwise skip every flag and name the blocking findings.
2. **Head**: refresh the source SHA. If it moved since the review or fix push,
   review the changed commits through steps 0–2 and recheck affected findings.
   Run affected checks and manual cases, then repeat the gate above.
   Use only that verified SHA as `HEAD_SHA`.
3. **Approve** (`--approve`): follow the `ship` skill's
   [merge.md](../../ship/references/merge.md#approve) **Approve** section with `HEAD_SHA`.
   On GitHub, report your own PR as a blocker instead of approving it.
4. **Auto-merge** (`--auto-merge` or `--merge`): follow merge.md **Inspect** and
   **Enable auto-merge** with `HEAD_SHA`.
5. **Watch** (`--merge` only): follow merge.md **Watch**. Move the ticket only when
   it belongs to this task or the user asked.
6. **Local cleanup** (`--merge` only, after a confirmed merge): remove every local
   remnant of the MR/PR per the `worktree` skill's **Remove** and
   `host-preflight/references/task-resources.md`, from `<main-checkout>`.
   - Remove the review worktree and any other clean worktree on the source branch,
     including one that existed before this review. Keep a locked, dirty, or in-use
     worktree and report it.
   - Delete the local source branch per **Remove after push**. If the remote branch
     is gone and `branch -d` refuses the squash-merged tip, run
     `git branch -D <branch>` only when the local tip equals the merged MR/PR's
     recorded head SHA. Otherwise keep it and report both IDs.
   - Run `git -C <main-checkout> fetch --prune origin`, then `git worktree prune`.

End the report with one line:
`Merge: approved <sha>; auto-merge enabled; merged <sha>; cleaned <paths and branch>`
(only the parts that ran), or `Merge: not run (<reason>)`. Name any retained remnant
and its reason.
