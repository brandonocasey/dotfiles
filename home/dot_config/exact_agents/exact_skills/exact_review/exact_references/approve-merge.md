## 7. Optional: --approve, --auto-merge, --merge

Each flag is the user's request to approve or merge the reviewed MR/PR
([git-policy.md](../../shared/git-policy.md)). Local targets: report `Merge: not run (local target)`.

- `--approve`: approve the MR/PR at its reviewed head.
- `--auto-merge`: enable auto-merge, read the state back, and stop.
- `--merge`: enable auto-merge, then watch until merged or blocked.

`--auto-merge` and `--merge` never imply approval. Combine them with `--approve` for that.

A fix pushed to the MR/PR, `--approve`, `--auto-merge`, or `--merge` is also the
user's request to mark a draft MR/PR ready. This overrides the `ship` rule that
leaves drafts alone. A fix run with no flag runs only steps 1–3 here.

Run this step last: after step 5's fix loop when `--fix` applies, otherwise after step 3.

1. **Gate**: run only when no `bug`, `requirement`, or `question` finding remains
   unfixed. Otherwise skip every flag, leave draft state alone, and name the
   blocking findings.
2. **Head**: refresh the source SHA. If it moved since the review or fix push,
   review the changed commits through steps 0–2 and recheck affected findings.
   Run affected checks and manual cases, then repeat the gate above.
   Use only that verified SHA as `HEAD_SHA`.
3. **Ready**: if the MR/PR is a draft, mark it ready and read the state back.
   - GitHub: `gh pr ready <number>`; check `gh pr view <number> --json isDraft`.
   - GitLab: `glab mr update <iid> --ready`; check `draft` in `glab mr view <iid> -F json`.
   - Outside the checkout, add `-R` as in merge.md. If it stays a draft, skip
     steps 5–6 and report it as a blocker.
4. **Approve** (`--approve`): follow the `ship` skill's
   [merge.md](../../ship/references/merge.md#approve) **Approve** section with `HEAD_SHA`.
5. **Auto-merge** (`--auto-merge` or `--merge`): follow merge.md **Inspect** and
   **Enable auto-merge** with `HEAD_SHA`.
6. **Watch** (`--merge` only): follow merge.md **Watch**. Move the ticket only when
   it belongs to this task or the user asked.
7. **Local cleanup** (`--merge` only, after a confirmed merge): remove every local
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
`Merge: marked ready; approved <sha>; auto-merge enabled; merged <sha>; cleaned <paths and branch>`
(only the parts that ran), or `Merge: not run (<reason>)`. Name any retained remnant
and its reason.
