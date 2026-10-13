---
disable-model-invocation: true
name: open-ended
description: "User-invoked only: run an open-ended task in rounds of fresh sub-agents until rounds stop finding anything new."
---

Use this for tasks with no fixed end, such as audits, gap hunts, "find all X",
or "improve X". One session anchors on its first ideas. Fresh agents miss
different things, so repeat rounds until they run dry.

Arguments: the task, `--rounds N` (most rounds, default 6), and `--angles N`
(agents per round, default 3).

## 0. Set up

1. Read [sub-agents/SKILL.md](../sub-agents/SKILL.md) and
   [roles.md](../sub-agents/references/roles.md).
2. Define done. Write the scope (paths, features, configs, sources) and one end
   check that says what "covered" means. If the task is too vague to scope, ask
   one question.
3. Pick angles: distinct lenses that fit the task, one line each. For a code
   audit: correctness, error and edge paths, callers and sibling sites, tests.
4. If a ledger for this task exists, resume from it. Otherwise create
   `<scratch>/open-ended/<task-slug>/ledger.md` with the task, scope, end check,
   angles, and empty **Found**, **Rejected**, and **Checked** sections.

## 1. Run a round

1. Write the shared prompt once to `<ledger-dir>/brief.md`: task, scope, end
   check, ledger path, repository constraints, and the instructions below.
   Spawn one agent per angle, in one message, with "read brief.md; your angle:
   X". Use `explorer` for read-only search and `worker` when items need
   judgement or research. Tell each agent to:
   - read the ledger first;
   - write its result to `round-<k>/<angle>.md` and return the path and item
     count;
   - return only items absent from **Found** and **Rejected**, each with source
     (`file:line` or URL), evidence, and the reason it is new;
   - re-raise a rejected item only with new evidence;
   - list the areas it checked;
   - not edit, commit, or spawn agents.
2. From round 2, replace each angle that returned nothing with a new angle aimed
   at scope not yet in **Checked**.
3. Spot-check high-risk items yourself against the cited code or data. Give the
   rest to a fresh verifier agent that writes a verdict file. Move duplicates and
   unproven items to **Rejected** with a one-line reason.
4. Append verified items to **Found** with the round number. Append the areas to
   **Checked**.
5. When the task includes changes and they are authorized, apply the verified
   items now, so the next round sees the current state.
6. Tell the user one line: `round k: X new, Y rejected`.

## 2. Stop

Stop when any of these is true:

- Two rounds in a row add nothing to **Found**.
- The end check passes and the next round adds nothing.
- The round count reaches `--rounds`.

## 3. Report

Lead with the result: **ran dry** or **stopped at the cap**. At the cap, say
whether the last round still found items. Then give every **Found** item in a
compact table, the **Rejected** count, scope not yet checked, and the ledger
path.
