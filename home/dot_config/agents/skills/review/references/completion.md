## Automatic completion review

AGENTS.md routes automatic reviews to [when-to-run.md](when-to-run.md),
which owns triggers, skip exceptions, follow-ups, and reviewer count. For triggered
reviews of this session's work:

- Review the combined task diff after implementation and relevant checks. Include
  committed and uncommitted task changes; a clean working tree does not mean the
  task has nothing to review. Use the task's recorded starting revision and scope.
- Wait for the independent result, verify findings, apply confirmed in-scope fixes,
  and rerun affected checks before reporting completion. Preserve the existing
  authorization rules for pushes and changes outside the intended behavior.
- Do not repeat a full review merely to obtain a clean result after fixing findings.
  Apply the follow-up rules in [when-to-run.md](when-to-run.md) to the
  unreviewed delta with surrounding context. Explicit `--loop` requests retain their workflow.
- Report the verified outcome, including defects fixed, rather than relabeling a
  review as clean after repairs. Disclose any inline fallback in [delegation.md](delegation.md).
