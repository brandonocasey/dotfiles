---
disable-model-invocation: true
name: pr-fix-merge
description: "Fix CI on PRs/MRs until green, then merge each one; pr-fix plus --merge."
---

Run the [pr-fix](../pr-fix/SKILL.md) skill with `--merge` added to the user's
arguments. Read and follow that skill once. Preserve the user's selection and
every other flag, such as `--approve`, `--author`, or `--repo`.

Invoking this skill is the user's request to merge every selected pull request
once it passes. [merge.md](../pr-fix/references/merge.md) owns the preflight,
merge method, and blockers. Approval still needs `--approve`.
