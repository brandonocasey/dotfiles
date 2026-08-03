---
name: review
description: >
  Verified code review of any change: a GitLab MR or GitHub PR URL, a local branch, a commit
  or range, or the uncommitted working diff. Remote targets fetch via glab/gh. Every
  candidate finding is VERIFIED against the real code before it is shown. Output: findings
  with a severity label, a plain-language explanation, the exact location (clickable MR/PR
  link, or file:line locally), and a ready-to-post comment or concrete fix. Use when the
  user pastes an MR/PR URL, names a branch or commit to review, says "review this
  MR/PR/branch/commit", "review my changes", "review and ELI5", or invokes /review.
  Optional --fix applies the agreed fixes (and pushes, for an MR/PR).
---

Review a code change. The deliverable is a set of verified findings the user can act on
as-is — ready-to-post comments for an MR/PR, concrete fixes for local targets — each
explained in plain language.

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

## 1. Review

Look for, in priority order: correctness bugs (null/undefined paths, ordering, races, missed
callers of changed functions), behavior changes not covered by the description, missing or
weakened tests, and only then style/simplification. Check every caller of any changed
function — a fix applied at one call site with broken siblings is the most common real finding.

## 2. Verify — mandatory, before anything is shown

For EVERY candidate finding, confirm it against the actual code (not the diff hunk alone):
read the full function/file in the checkout, trace the failure path, and state the concrete
input/state that triggers it. Kill any finding you cannot make concrete. A plausible-sounding
comment that turns out false is worse than no comment. If tests exist for the area, run the
relevant ones when a finding claims broken behavior.

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
to post. Remove any worktree this review created — never a pre-existing one — unless
continuing to `--fix` (`git worktree remove .worktrees/review-<number>`).

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
  the repo's tests/lint, and commit per the `commit` skill. Do not push.
- **Working diff**: apply the agreed fixes in place and leave them uncommitted unless the
  user asks to commit.
