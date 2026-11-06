---
name: design
description: "Before non-trivial implementation: settle unknowns and write a short design.md the implementer follows."
---

Size the phase to the cost of being wrong:

- **None** for a clear one-file change.
- **Short plan plus checkable criteria** for medium work: a `design.md` of at most 20 lines with goal, what must not change, ordered steps, and "done means". Skip decisions, rejected options, and open questions unless a choice has no safe default.
- **Full design plus user approval** for hard-to-reverse choices: data model, public API, cross-module boundary.

## Steps

1. List the unknowns that change the design. Answer every one the code, docs, or history can. For a new flag, mode, setting, or field, also list every sibling path that reads or writes the same thing (other commands and handlers, docs, skip and dry-run flows), data already written, and what must run before the first side effect; give each a "done means" check.
2. Ask the user only design choices with no safe default, batched as numbered options with a recommended default, per the output-style rules. Take reversible defaults and list them in the design; do not ask.
3. Write `design.md` at `<scratch>/<task>/design.md` (under `agents/output/<task>/` when it needs approval), at most 60 lines (20 for the medium tier), with:
   - goal;
   - decisions, each with a one-line reason;
   - rejected options, each with a reason;
   - what must not change;
   - ordered steps, each with the file locations it touches;
   - "done means": each requirement in the user's words, then criteria that a command or observation can check;
   - open questions.
4. For a high-risk design only, get one independent critique: a fresh `consult` given `design.md` and the evidence paths, per `sub-agents`. Apply or answer each point in the file.
5. For the full-design tier, show `design.md` to the user and wait for approval before implementing.
6. The implementer follows `design.md` and returns a conflict with it as a question. It writes no second plan.

Pass `design.md` to the tester as the source for `Expected:` per `review` [testing.md](../review/references/testing.md).
