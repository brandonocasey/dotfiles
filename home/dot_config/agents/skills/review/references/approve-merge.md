## 7. Optional: --approve, --auto-merge, --merge

Each flag is the user's request to approve or merge the reviewed MR/PR (Git policy).
Apply them only to MRs/PRs the user names or authored. Local targets have nothing to
approve or merge: report `Merge: not run (local target)`.

- `--approve`: approve the MR/PR at its reviewed head.
- `--auto-merge`: enable auto-merge, read the state back, and stop.
- `--merge`: enable auto-merge, then watch until merged or blocked.

`--auto-merge` and `--merge` never imply approval. Combine them with `--approve` for that.

Run this step last: after step 4's push when `--fix` applies, otherwise after step 3.

1. **Gate**: run only when no `bug`, `requirement`, or `question` finding remains
   unfixed. Otherwise skip every flag and name the blocking findings.
2. **Head**: refresh the source SHA. If it moved since the review or the fix push,
   check each finding again before continuing. Use the fresh SHA as `HEAD_SHA`.
3. **Approve** (`--approve`): follow the `ship` skill's
   [merge.md](../../ship/references/merge.md#approve) **Approve** section with `HEAD_SHA`.
   On GitHub, report your own PR as a blocker instead of approving it.
4. **Auto-merge** (`--auto-merge` or `--merge`): follow merge.md **Inspect** and
   **Enable auto-merge** with `HEAD_SHA`.
5. **Watch** (`--merge` only): follow merge.md **Watch**. Move the ticket only when
   it belongs to this task or the user asked.

End the report with one line:
`Merge: approved <sha>; auto-merge enabled; merged <sha>` (only the parts that ran),
or `Merge: not run (<reason>)`.
