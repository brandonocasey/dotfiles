---
name: review-auto
description: "Review and fix an MR/PR, then approve and merge it when no blocking finding remains; review plus --fix --approve --merge. Invoke only when the user explicitly asks for review-auto."
---

Run the [review](../review/SKILL.md) skill with `--fix --approve --merge` added to the
user's arguments (with `--land`, only `--fix`). Read and follow that skill once. `--fix` runs its fix loop.
Preserve the user's target and every other flag, such as `--agents` or `--no-test`.

Invoking this skill is the user's request to fix, approve, and merge the target.
It also requests a formal host approval, on any MR/PR, including ones the user
authored or worked on. It confirms approval and merge at every risk tier, so skip
step 7's high-risk question. It authorizes rebasing the source branch and
force-pushing it, per **Rebase under review-auto** in
[ci-and-conflicts.md](../review/references/ci-and-conflicts.md).
Review step 7 owns the gate, head re-check, approval rules, and merge watch.
Blocking findings or a local target stop approval and merge.

Optional flags, not passed to review:

- `--ship`: before the review, run the [ship](../ship/SKILL.md) skill on the target,
  so the review targets the MR/PR it opens. The flag is the push authorization ship
  needs.
- `--land`: after the review and its fix loop, run the [land](../land/SKILL.md) skill
  on the target. The flag is the request to land. Do not pass `--approve` or `--merge`
  to review: they need an MR/PR.

Use at most one of them. With both, ask which one and stop.
