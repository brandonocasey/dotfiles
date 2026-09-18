---
disable-model-invocation: true
name: repo-audit
description: >
  Multi-agent repo audit pipeline: fan out dimension-scoped finder agents (bugs, performance,
  duplication, legacy/back-compat, consistency), verify every finding against the real code,
  present confirmed findings split into safe fixes vs decisions, then apply approved fixes with
  parallel worktree agents under strict file-ownership boundaries. Also re-verifies or works
  through an existing AUDIT.md. Use when the user says "audit this repo", "full audit", "get
  this code base in tip-top shape", "re-verify the audit findings", "work through AUDIT.md", or
  invokes /repo-audit.
---

Run a repo-wide audit as a staged multi-agent pipeline. Findings are never shown unverified,
and fixes are never applied without the user picking them.

## Modes

Pick from the invocation; default is **full**.

- **full** — find → verify → present → (on approval) fix. Steps 0–6.
- **re-verify `<path>`** — the repo changed since the findings were written: run step 3
  against the current code for every unresolved finding, then rewrite the file (step 6's
  format). Skip finding.
- **apply `<path>`** — findings already exist and are decided: run steps 4–6 for the
  entries the user selects.

`<path>` is the findings file step 6 writes; it defaults to `docs/AUDIT.md`.

Arguments the user may pass: dimensions to audit (default: bugs, performance, duplication,
legacy/back-compat, consistency), paths to include/exclude, and an agent model override (e.g.
"opus agents") — apply it to every spawned agent.

## 0. Setup

- Establish repo facts the agents will need: language/toolchain, package or crate map with
  **real repo paths** (agents waste turns resolving shorthand — give them the mapping), rough
  LOC, test and lint commands.
- In the modes that can write code (**full**, **apply**), create the fix worktree up front per
  the `worktree` skill — it owns the commands and the base-branch rule. This skill's only delta
  is the naming: path `.worktrees/repo-audit`, branch `repo-audit`. **re-verify** never
  writes code — create no worktree there. Finder and verifier agents are read-only and run
  against the main checkout; only fixers (step 5) write, and only inside this worktree.
- Before creating `.worktrees/repo-audit` or branch `repo-audit`, check whether
  either exists. Reuse it only for this invocation's continuing audit;
  otherwise choose a unique task name. Record which worktree and branch this
  invocation created.
- Findings live as JSON in the scratch directory (AGENTS.md, **Directories**):
  `~/.cache/agents/scratch/repo-audit/batches/batch_N.json`. Never the harness scratchpad.
- Orchestrate with the Workflow tool when it is available (this skill is the user's opt-in);
  otherwise fan out with the Agent tool. Keep any single workflow under ~15 agents — split the
  pipeline into one workflow per phase (find, verify, fix) and read results between phases.

## 1. Find

One read-only finder agent per dimension, in parallel. Every finder prompt must contain: the
repo path, the path map from step 0, the dimension's definition and non-goals, the exclusions
(generated/vendored/build output, e.g. `bin-*`, `dist/`, lockfiles), and the output contract —
a JSON array of findings:

```json
{ "id": "bugs-3", "dimension": "bugs", "severity": "high|medium|low",
  "confidence": "high|medium|low", "file": "path/from/repo/root.rs", "line": 123,
  "title": "one line", "detail": "what is wrong, why it matters, concrete fix direction" }
```

State in the prompt that the agent's final message IS the JSON — no prose around it.

## 2. Merge and dedupe

Plain code/inspection, not an agent: flatten all finders' output, drop exact duplicates, and
merge overlapping findings that share a root cause (keep the clearest title, union the
locations). Renumber ids. Batch the result into files of 8–12 findings for verification.

## 3. Verify (adversarial)

One verifier agent per batch, in parallel, prompted to **refute**: read the JSON batch file,
check every finding against the real code at current HEAD (read-only), and return the array
with two fields added per finding — `verdict`: `CONFIRMED` or `REFUTED`, and `evidence`:
`file:line` plus a verbatim excerpt proving the verdict. Uncertain defaults to REFUTED. Drop
refuted findings; keep their count for the report.

## 4. Present and decide

Show confirmed findings as a numbered list — `severity`, `title`, clickable `file:line`, one
plain-language sentence each — grouped as:

- **SAFE** — mechanical, behavior-preserving, low blast radius (dead code, duplication,
  missing guards, obvious perf wins).
- **DECIDE** — changes behavior, API, or design; needs the user's call.

The user picks by number ("all safe", "1, 4, 7", "everything but 3"). Apply nothing before
they answer.

## 5. Fix (parallel, bounded)

- Partition the approved findings into groups with **disjoint file sets**; groups touching the
  same file run in the same agent, sequentially.
- One fixer agent per group, in the step-0 worktree. Every fixer prompt must contain: the
  worktree path, the finding(s) verbatim (id, file:line, detail, evidence), and these rules:
  the decision is already made — implement it faithfully, do NOT re-litigate; edit ONLY inside
  the worktree; HARD BOUNDARY — touch only your assigned files, others are being edited in
  parallel; do not commit; report per finding: fixed / blocked / already-fixed, with the diff
  summary.
- After all fixers return: write or update the step-6 remainder file, loading
  `write-docs` first. Then run the project's lint and test commands in the worktree. Failures
  are yours to fix before reporting.
- Commit via the `commit` skill (one logical commit per concern, referencing finding ids in
  bodies). Include changes to the findings file in a separate documentation
  commit so no task files remain uncommitted. Hand the branch to `land` or
  `ship` only when the user asks. Load the authorized skill through the
  harness's explicit skill mechanism when available; otherwise read
  `<skills-dir>/land/SKILL.md` or `<skills-dir>/ship/SKILL.md`. Resolve
  `<skills-dir>` against this file's path, not the user's repo, and follow it.

## 6. Report and remainder

- Write every unapplied finding (DECIDE items, blocked fixes, deferred SAFE items) to
  `docs/AUDIT.md` — one checkbox line per finding: id, severity, `file:line`, title, verdict,
  and a `detail:` sub-line. Put it in the worktree when fixes were applied there; with no
  applied fixes, write it in the main checkout instead — an untracked file blocks the worktree
  removal below and would be deleted with it. This file is the input for the re-verify and
  apply modes later.
- Remove an unused task-created fix worktree and branch through the `worktree`
  skill's **Remove** rules, from a surviving checkout outside it. Never remove
  a pre-existing worktree or branch. When fixes are committed but not landed
  or pushed, retain the worktree and report its path, branch, and tip.
- Report: counts per stage (found → after dedupe → confirmed → fixed), what was refuted or
  dropped (never silently truncate coverage — say what was skipped and why), test/lint state,
  citing the worktree path, `docs/AUDIT.md`, and every applied fix inline as bare
  `file:line` paths (never markdown-formatted). Add a **Links** section only for relevant
  external links (ticket, MR/PR, CI).

## Hard rules

- Nothing unverified reaches the user; nothing unapproved gets fixed.
- Finder/verifier agents are read-only; fixers write only inside the audit worktree, only
  their assigned files.
- Full lint + test gate before any commit; failures are yours to fix, never "pre-existing".
- Never delete or rewrite an existing AUDIT.md's unresolved findings except through re-verify
  with evidence.
