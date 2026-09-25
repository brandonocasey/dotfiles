---
name: review
description: >
  Review a PR/MR, branch, commit range, or working diff for verified defects.
  Use for review requests; --fix applies agreed fixes and pushes remote
  reviews.
---

Review a code change adversarially: assume it is broken and try to prove it. The
deliverable is a set of verified findings the user can act on
as-is — ready-to-post comments for an MR/PR, concrete fixes for local targets — each
explained in plain language.

## Delegation

Delegate the review to a sub-agent only when this session or its sub-agents wrote the
change, so that the reviewer is independent. Review anyone else's change inline (an
MR/PR from a colleague, an arbitrary commit).

When delegating: spawn one sub-agent per the `sub-agents` skill. Pass it the review
target verbatim plus the text of steps 0–2 only — never the implementation rationale
or the conversation, or the reviewer is not independent. Resolve reference paths in
the excerpt against this skill's directory. The sub-agent runs steps 0–2
and returns candidate findings as raw data (file, line, severity, failure scenario,
evidence, and which tests it ran). It keeps any review worktree it created and returns
its path with the findings. An external tool's findings still go through the
re-verification below.

When the sub-agent returns, the main session re-verifies each finding in that
worktree before showing or fixing anything: read the cited code, confirm the failure
scenario is reachable, and kill anything that isn't concrete. Do not re-run tests the
sub-agent already reported running — re-run only when a finding hinges on a test
result the sub-agent did not show. The main session then runs steps 3–4 itself
(including worktree removal). If the sub-agent could not access the target (missing
auth, no checkout), fall back to running the review inline and note that the reviewer
is not independent.

Reviews of this session's own work skip the `--fix` gate, whether auto-triggered or
user-requested: apply verified fixes immediately, re-run tests/lint after applying them,
and do not review again. Reviews of someone else's change print the comments and wait
for `--fix`.

Before the final review of this session's own work, on a model other than Fable or Astra:
when the Git rules authorize pushing the task branch, push it first. Then inspect CI
failures that already finished, once, and fix them; do not wait for a running CI.
Without push authorization, review the local branch.

## 0. Identify the target and get the diff

Classify the argument:

- **GitLab or GitHub URL** → remote review. Parse host, project path, and MR/PR number.
  GitLab (any host) → `glab`, prefixed with `GITLAB_HOST=<host>` when self-hosted;
  GitHub → `gh`.
- **Branch name** → local branch review against **Newest default base** in
  [default-branch.md](../shared/default-branch.md), unless the user supplied a base.
  Use `git log <base-commit>..<branch>` for commits and
  `git diff <base-commit>...<branch>` for changes since their merge-base.
- **Commit sha or range** (`<sha>`, `<a>..<b>`) → `git show <sha>` / `git diff <a>..<b>`.
- **No argument** → the working diff (`git diff`, `git diff --staged`, plus untracked
  files) if the tree is dirty; otherwise the current branch against the default branch as
  above. If that is empty too, say there is nothing to review and stop.

Get the full code, not just the diff — the diff alone is rarely enough context:

- **Remote target**: read [remote-target.md](references/remote-target.md) for
  metadata, discussion, diffs, and the source checkout before review.
- **Local branch**: use its existing worktree if it has one (`git worktree list`);
  otherwise `git -C <main-checkout> worktree add .worktrees/review-<branch> <branch>`.
- When `.gitmodules` exists and the review runs tests, initialize submodules per the
  `worktree` skill's **Create**. An initialized submodule later blocks plain removal; the
  same skill's **Submodules** section owns the `--force` decision.
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

Now switch sides: for every candidate finding, try to refute it. Read the full
function/file in the checkout (not the diff hunk alone), trace the failure path, and hunt
for the guard, caller contract, or earlier check that makes the scenario unreachable. A
finding survives only if refutation fails and you can state the concrete input/state that
triggers it. Kill everything else. A plausible-sounding comment that turns out false is
worse than no comment. If tests exist for the area, run the relevant ones when a finding
claims broken behavior — a passing test that covers the exact scenario refutes the finding.

For a finding about rendered UI, use the `ui-verify` skill when browser evidence is
needed. For a ROM Weaver performance claim, use `benchmark-change` when measurements
are needed. Reuse results for the same revision and inputs; these checks return
evidence to this review, not another review cycle.

## 3. Output

Brief beats complete-sounding: no padding, no restating the diff.

1. **TLDR line** — one sentence: how many findings survived, and whether any are real bugs
   vs. minor notes.
2. **What the change does** — 1–2 plain-language sentences a non-expert could follow. No
   project codenames without a gloss.
3. **One block per surviving finding**, most-severe first, each led by a severity label:
   `bug` (wrong behavior reachable in production), `question` (design choice worth confirming
   with the author), `nit` (cosmetic/noise). Per block:
   - **Where**: file + line. For an MR/PR, add a clickable link (formats in `remote-comments.md`, linked at the end of this step) so the
     comment can be left right there; for local targets, use `path:line` (clickable in the
     terminal).
   - **Why it matters**: 1–3 plain-language sentences — what goes wrong, when, and why it
     matters. Jargon spelled out.
   - **Comment to post** (MR/PR) — ready-to-paste text (this one can be technical): factual,
     no hedging, no AI-flavored preamble; state the failure scenario concretely. Where a
     small code change fixes it, include a suggestion block (syntax in the same file).
     **Fix** (local targets) — the concrete change as a small code snippet or exact edit.
4. **What was checked and cleared** — up to 4 one-line bullets naming candidate issues that
   did NOT survive verification and why each was killed. This is the proof the review was real.

If nothing survives verification, say so plainly — the cleared list plus "nothing real found"
is a valid result. Do not post anything to the MR/PR unless the user asks; print for the user
to post. Remove any worktree this review created — never a pre-existing one — with
`git -C <main-checkout> worktree remove <the .worktrees/review-… path from step 0>`, per the `worktree` skill's
**Remove** section (clean tree, shell moved out first). When continuing to `--fix`, keep it
until the end of step 4 and remove it there. A review that leaves `.worktrees/review-…`
behind is incomplete: the report's last line names the removed path or the blocker.

For MR/PR comment links and suggestion syntax, read
[remote-comments.md](references/remote-comments.md). Local reviews do not need it.

## 4. Optional: --fix

Only when the user asks (`--fix`, "fix them"):

- **MR/PR**: in the review worktree, apply the agreed fixes, run the repo's tests/lint,
  commit through the `commit` skill in the branch's existing style (carry any issue-tracker reference from the MR/PR
  title), and push to the source branch — the review worktree is detached, so use
  `git push origin HEAD:<source-branch>`. For a fork MR/PR, `origin` is the base repo: push
  to the fork's URL instead (`git push <fork-url> HEAD:<source-branch>`). That needs push
  access to the fork and leaves `.git/config` unchanged. Print branch, HEAD sha, and the
  MR/PR link afterwards. Clean up the worktree when done either way.
- **Local branch or commit**: apply the agreed fixes in the target's checkout/worktree, run
  the repo's tests/lint, and commit per the `commit` skill. Do not push. Then remove the
  worktree if step 0 created it — the commits stay on the branch.
- **Working diff**: apply the agreed fixes in place and leave them uncommitted unless the
  user asks to commit.
