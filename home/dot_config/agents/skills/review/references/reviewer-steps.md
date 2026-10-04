# Reviewer steps 0–2

Inline reviews and delegated reviewers run these steps. A delegated reviewer
returns candidate findings as raw data and does not run review steps 3–4.
When the prompt gives a review worktree, use it and do not create another.

## 0. Identify the target and get the diff

Classify the argument:

- **GitLab, GitHub, or Forgejo URL** → remote review. Parse host, project path, and MR/PR number.
  GitLab (any host) → `glab`, prefixed with `GITLAB_HOST=<host>` when self-hosted;
  GitHub → `gh`; Forgejo → `fj -H <host>` (read-only review only; check
  `fj pr view --help` for the ID format).
- **Branch name** → local branch review against **Newest default base** in
  [default-branch.md](../../shared/default-branch.md), unless the user supplied a base.
  Use `git log <base-commit>..<branch>` for commits and
  `git diff <base-commit>...<branch>` for changes since their merge-base.
- **Commit sha or range** (`<sha>`, `<a>..<b>`) → `git show <sha>` / `git diff <a>..<b>`.
- **No argument** → the working diff (`git diff`, `git diff --staged`, plus untracked
  files) if the tree is dirty; otherwise the current branch against the default branch as
  above. If that is empty too, say there is nothing to review and stop.

Get the full code, not just the diff — the diff alone is rarely enough context:

- **Remote target**: read [remote-target.md](remote-target.md) for
  metadata, discussion, diffs, and the source checkout before review.
  Read [ci-and-conflicts.md](ci-and-conflicts.md) for CI status,
  mergeability, repair authorization, retries, and conflict handling.
- **Local branch**: use its existing worktree if it has one (`git worktree list`);
  otherwise `git -C <main-checkout> worktree add .worktrees/review-<branch> <branch>`.
- After you create a review worktree, run the `worktree` skill's **Prepare** section
  before tests or a `--fix` commit.
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
  or subtly wrong? Report missing or ineffective coverage only when you can name
  the important uncovered behavior. Preserve the ban on weakening existing tests.
- **Exploit it.** Where the change touches a trust boundary (user input, URLs, HTML, file
  paths, permissions), spend a pass thinking like an attacker, not a reviewer.
- **Check the title and description are accurate** (MR/PR only). Report claims
  contradicted by the diff or violations of explicit repository requirements.
  A useful description may exceed two sentences; do not shorten it just for length.
- Report verified defects and violations of explicit repository requirements.
  Include optional style suggestions only when requested. A comment is a defect
  when it misstates a contract or behavior, not merely because it could be shorter.

## 2. Verify — mandatory, before anything is shown

Now switch sides: for every candidate finding, try to refute it. Read the full
function/file in the checkout (not the diff hunk alone), trace the failure path, and hunt
for the guard, caller contract, or earlier check that makes the scenario unreachable. A
finding survives only if refutation fails and you can state the concrete input/state that
triggers it. Kill everything else. A plausible-sounding comment that turns out false is
worse than no comment. If tests exist for the area, run the relevant ones when a finding
claims broken behavior — a passing test that covers the exact scenario refutes the finding.

For a finding about rendered UI, use the `ui-verify` skill when browser evidence is
needed. For a performance claim, use the repository's benchmark skill or command when
measurements are needed. Reuse results for the same revision and inputs; these checks return
evidence to this review, not another review cycle.
