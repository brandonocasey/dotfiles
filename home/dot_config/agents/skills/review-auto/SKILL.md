---
name: review-auto
description: "Review and fix an MR/PR, then approve and merge it when no blocking finding remains; review plus --fix --approve --merge."
---

Scope: Review an MR/PR, fix its findings, and, when no blocking finding remains, approve it and merge it. Use for review-auto requests.


Run the [review](../review/SKILL.md) skill with `--fix --approve --merge` added to the
user's arguments. Read and follow that skill once. Preserve the user's target and
every other flag, such as `--loop`, `--deep`, or `--no-test`.

Invoking this skill is the user's request to fix, approve, and merge the target.
Review step 7 still owns the gate, the approval rules, and the merge watch:
blocking findings, a moved head, or a local target stop the approval and merge.
