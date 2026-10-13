---
name: review-fix
description: "Review a change, fix verified findings, and re-check fixes of major bugs; review plus --fix. The default review after agent work."
---

Run the [review](../review/SKILL.md) skill with `--fix` added to the user's
arguments. Read and follow that skill once. `--fix` runs its fix loop.
Preserve the user's target and every other flag, such as `--agents` or `--no-test`.

Invoking this skill is the user's request to fix the target. Approval and merge
still need `--approve` or `--merge`, or `review-auto`.
