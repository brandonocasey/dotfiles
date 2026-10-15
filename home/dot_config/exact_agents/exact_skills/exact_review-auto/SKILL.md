---
disable-model-invocation: true
name: review-auto
description: "Review and fix an MR/PR, then approve and merge it when no blocking finding remains; review plus --fix --approve --merge."
---

Run the [review](../review/SKILL.md) skill with `--fix --approve --merge` added to the
user's arguments. Read and follow that skill once. `--fix` runs its fix loop.
Preserve the user's target and every other flag, such as `--agents` or `--no-test`.

Invoking this skill is the user's request to fix, approve, and merge the target.
Review step 7 owns the gate, head re-check, approval rules, and merge watch.
Blocking findings or a local target stop approval and merge.
