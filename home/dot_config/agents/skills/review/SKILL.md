---
name: review
description: >
  Adversarial, verified code review of any change: an MR/PR URL, a local branch, a
  commit or range, or the uncommitted working diff. Every candidate finding is
  verified against the real code before it is shown; output is findings with
  severity, a plain-language explanation, the exact location, and a ready-to-post
  comment or concrete fix. Use for any review request or /review. Optional --fix
  applies the agreed fixes (and pushes, for an MR/PR).
---

Review a code change adversarially: assume it is broken and try to prove it. The
deliverable is a set of verified findings the user can act on
as-is — ready-to-post comments for an MR/PR, concrete fixes for local targets — each
explained in plain language.

## Delegation

Delegate the review to a sub-agent ONLY when the reviewer would otherwise be the same
agent that implemented the change — i.e. this session (or its sub-agents) wrote the
code. That is what buys an independent reviewer. When the change was written by someone
else (an MR/PR from a colleague, an arbitrary commit), run the review inline — no
sub-agent needed.

When delegating: spawn one sub-agent per the `sub-agents` skill. Pass it the review
target verbatim plus the text of steps 0–2 only — never the implementation rationale
or the conversation, or the reviewer is not independent. The sub-agent runs steps 0–2
and returns candidate findings as raw data (file, line, severity, failure scenario,
evidence, and which tests it ran). It must NOT remove the review worktree; it returns
the worktree path with its findings. An external tool's findings still go through the
re-verification below.

When the sub-agent returns, the main session re-verifies each finding in that
worktree before showing or fixing anything: read the cited code, confirm the failure
scenario is reachable, and kill anything that isn't concrete. Do not re-run tests the
sub-agent already reported running — re-run only when a finding hinges on a test
result the sub-agent did not show. The main session then runs steps 3–4 itself
(including worktree removal). If the sub-agent could not access the target (missing
auth, no checkout), fall back to running the review inline and note that the reviewer
is not independent.

Auto-triggered reviews of this session's own work skip the `--fix` gate: apply
verified fixes immediately, once per task — after applying them, re-run tests/lint
but do not review again.

## 0. Identify the target and get the diff

Classify the argument:

- **GitLab or GitHub URL** → remote review. Parse host, project path, and MR/PR number.
  GitLab (any host) → `glab`, prefixed with `GITLAB_HOST=<host>` when self-hosted;
  GitHub → `gh`.
- **Branch name** → local branch review against the default branch (`main` if it exists,
  else `master`): `git log <default>..<branch>` for the commits,
  `git diff <default>...<branch>` (three-dot: changes since the merge-base) for the diff.
- **Commit sha or range** (`<sha>`, `<a>..<b>`) → `git show <sha>` / `git diff <a>..<b>`.
- **No argument** → the working diff (`git diff`, `git diff --staged`, plus untracked
  files) if the tree is dirty; otherwise the current branch against the default branch as
  above. If that is empty too, say there is nothing to review and stop.

Remote fetch — GitLab:

```sh
glab mr view <iid> --repo <project-path>    # title, description, state, branches
glab mr diff <iid> --repo <project-path>
glab api "projects/<url-encoded-project-path>/merge_requests/<iid>/notes?per_page=100"  # existing discussion — skip already-raised points
```

Remote fetch — GitHub:

```sh
gh pr view <n> --repo <owner>/<repo>              # title, description, state, branches
gh pr diff <n> --repo <owner>/<repo>
gh pr view <n> --repo <owner>/<repo> --comments   # existing discussion — skip already-raised points
```

Get the full code, not just the diff — the diff alone is rarely enough context:

- **Remote target**: check out the source branch in a worktree — never the main checkout.
  The repo may not be the current working directory: locate the local checkout for the
  project first and create the worktree there.

  ```sh
  git fetch origin <source-branch>                             # GitLab, or same-repo GitHub PR
  git worktree add .worktrees/review-<number> origin/<source-branch>
  # GitHub PR from a fork: git fetch origin pull/<n>/head, then worktree add from FETCH_HEAD
  # GitLab MR from a fork: git fetch origin refs/merge-requests/<iid>/head, then worktree add from FETCH_HEAD
  ```

- **Local branch**: use its existing worktree if it has one (`git worktree list`);
  otherwise `git worktree add .worktrees/review-<branch> <branch>`.
- **Commit or working diff**: read directly in the current checkout; no worktree needed.

Read the surrounding code of every changed hunk you intend to comment on.

## 1. Review — adversarial

Start from the assumption that the change is broken and your job is to prove it. Do not
read the diff looking for things that seem off — attack it:

- **Construct breaking inputs.** For each changed function, actively hunt for a concrete
  input or state that makes it misbehave: null/undefined, empty, zero, negative, huge,
  unicode, concurrent calls, re-entrancy, out-of-order events, first/last iteration.
- **Attack the boundaries.** Check every caller of any changed function — a fix applied at
  one call site with broken siblings is the most common real finding. Then flip it: what
  does the changed code assume about its inputs, and which caller can violate that?
- **Distrust the description.** List what the author claims the change does, then look for
  behavior the diff actually changes that the claims don't cover — that gap is where bugs
  hide. Treat "refactor, no behavior change" as a claim to falsify.
- **Attack the tests.** New/changed tests: would they still pass if the fix were reverted
  or subtly wrong? A test that can't fail is a finding. Missing or weakened tests for the
  changed behavior are findings too.
- **Exploit it.** Where the change touches a trust boundary (user input, URLs, HTML, file
  paths, permissions), spend a pass thinking like an attacker, not a reviewer.
- **Check the title and description are current** (MR/PR only). Compare them against the
  full diff: if they omit or misstate what the change now does, or the title does not use
  the conventional commit type of the most user-facing change in the diff (`feat` over
  `refactor` over `chore`), report it as a finding with the corrected title/description text.

Only after the attack passes are exhausted, note style/simplification issues.

## 2. Verify — mandatory, before anything is shown

Now switch sides: for EVERY candidate finding, try to REFUTE it. Read the full
function/file in the checkout (not the diff hunk alone), trace the failure path, and hunt
for the guard, caller contract, or earlier check that makes the scenario unreachable. A
finding survives only if refutation fails AND you can state the concrete input/state that
triggers it. Kill everything else. A plausible-sounding comment that turns out false is
worse than no comment. If tests exist for the area, run the relevant ones when a finding
claims broken behavior — a passing test that covers the exact scenario refutes the finding.

## 3. Output

Brief beats complete-sounding: no padding, no restating the diff.

1. **TLDR line** — one sentence: how many findings survived, and whether any are real bugs
   vs. minor notes.
2. **What the change does** — 1–2 plain-language sentences a non-expert could follow. No
   project codenames without a gloss.
3. **One block per surviving finding**, most-severe first, each led by a severity label:
   `bug` (wrong behavior reachable in production), `question` (design choice worth confirming
   with the author), `nit` (cosmetic/noise). Per block:
   - **Where**: file + line. For an MR/PR, add a clickable link (formats below) so the
     comment can be left right there; for local targets, use `path:line` (clickable in the
     terminal).
   - **Why it matters**: 1–3 plain-language sentences — what goes wrong, when, and why it
     matters. Jargon spelled out.
   - **Comment to post** (MR/PR) — ready-to-paste text (this one can be technical): factual,
     no hedging, no AI-flavored preamble; state the failure scenario concretely. Where a
     small code change fixes it, include a suggestion block (syntax below).
     **Fix** (local targets) — the concrete change as a small code snippet or exact edit.
4. **What was checked and cleared** — up to 4 one-line bullets naming candidate issues that
   did NOT survive verification and why each was killed. This is the proof the review was real.

If nothing survives verification, say so plainly — the cleared list plus "nothing real found"
is a valid result. Do NOT post anything to the MR/PR unless the user asks; print for the user
to post. Remove any worktree this review created — never a pre-existing one — with
`git worktree remove <the .worktrees/review-… path from step 0>`. When continuing to
`--fix`, keep it until the end of step 4 and remove it there.

### Link formats (MR/PR only)

GitLab — diff-line anchor in the Changes tab:
`https://<host>/<project-path>/-/merge_requests/<iid>/diffs#<sha1>_<old>_<new>`
where `<sha1>` = `printf '<repo-relative-file-path>' | shasum -a 1` and `<old>`/`<new>` are
the diff positions of the line (walk the hunk from `@@ -o,c +n,c @@`: context lines increment
both counters, `-` only the old, `+` only the new; an added line's `<old>` is the current
unincremented old counter). File-wide notes use `.../diffs#<sha1>`. Fall back to
`https://<host>/<project-path>/-/blob/<source-branch>/<file>#L<line>` only for lines outside
the diff.

GitHub — diff-line anchor in the Files tab:
`https://github.com/<owner>/<repo>/pull/<n>/files#diff-<sha256>R<new-line>`
where `<sha256>` = `printf '<repo-relative-file-path>' | shasum -a 256`; use `L<old-line>`
for a deleted line. File-wide notes use `...#diff-<sha256>`. Fall back to
`https://github.com/<owner>/<repo>/blob/<source-branch>/<file>#L<line>` for lines outside
the diff.

### Suggestion blocks (MR/PR only)

GitLab (`-0+0` widens the replaced line range when needed):

````markdown
```suggestion:-0+0
<replacement lines>
```
````

GitHub (replaces the line(s) the comment anchors to):

````markdown
```suggestion
<replacement lines>
```
````

## 4. Optional: --fix

Only when the user asks (`--fix`, "fix them"):

- **MR/PR**: in the review worktree, apply the agreed fixes, run the repo's tests/lint,
  commit in the branch's existing style (carry any issue-tracker reference from the MR/PR
  title), and push to the source branch — the review worktree is detached, so use
  `git push origin HEAD:<source-branch>`. For a fork MR/PR, `origin` is the base repo — you
  need push access to the fork and must add it as a remote and push there instead. Print
  branch, HEAD sha, and the MR/PR link afterwards. Clean up the worktree when done either way.
- **Local branch or commit**: apply the agreed fixes in the target's checkout/worktree, run
  the repo's tests/lint, and commit per the `commit` skill. Do not push. Then remove the
  worktree if step 0 created it — the commits stay on the branch. Never remove a pre-existing
  worktree.
- **Working diff**: apply the agreed fixes in place and leave them uncommitted unless the
  user asks to commit.
