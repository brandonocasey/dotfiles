---
name: review-mr
description: >
  GitLab-native merge request review using glab. Fetch the MR, review the diff, VERIFY every
  claim against the actual code before presenting, and output ready-to-post MR comments with
  clickable file/line links and GitLab suggestion blocks. Use when the user pastes a
  gitlab.com merge_requests URL, says "review this MR", "give me MR comments", or invokes
  /review-mr. Optional --fix mode applies agreed fixes and pushes to the MR branch. (GitHub
  PRs go to /review instead.)
---

Review a GitLab MR. The deliverable is a set of comments the user can post as-is — every one
verified, every one linked.

## 0. Fetch

Parse `<project-path>` and `<mr-iid>` from the URL. Then:

```sh
glab mr view <iid> --repo <project-path>                # title, description, state, branches
glab mr diff <iid> --repo <project-path>                # the diff
glab api "projects/<url-encoded-project-path>/merge_requests/<iid>/notes?per_page=50" # existing discussion (skip already-raised points)
```

If the diff alone isn't enough context (it rarely is), check out the MR branch in a worktree —
never in the main checkout:

```sh
git fetch origin <source-branch>
git worktree add .worktrees/review-<iid> origin/<source-branch>
```

Read the surrounding code of every changed hunk you intend to comment on.

## 1. Review

Look for, in priority order: correctness bugs (null/undefined paths, ordering, races, missed
callers of changed functions), behavior changes not covered by the description, missing/weakened
tests, and only then style/simplification. Check every caller of any changed function —
a fix applied at one call site with broken siblings is the most common real finding.

## 2. Verify — mandatory, before anything is shown

For EVERY candidate finding, confirm it against the actual code (not the diff hunk alone):
read the full function/file in the worktree, trace the failure path, and state the concrete
input/state that triggers it. Kill any finding you cannot make concrete. A plausible-sounding
comment that turns out false is worse than no comment. If tests exist for the area, run the
relevant ones when a finding claims broken behavior.

## 3. Output

For each surviving finding:

- **Clickable link** — prefer the MR-diff line anchor so the comment can be left in place:
  `https://gitlab.com/<project-path>/-/merge_requests/<iid>/diffs#<sha1>_<old>_<new>`
  where `<sha1>` = `printf '<repo-relative-file-path>' | shasum -a 1` and `<old>`/`<new>`
  are the diff positions of the line (walk the hunk from `@@ -o,c +n,c @@`: context lines
  increment both counters, `-` only the old, `+` only the new; an added line's `<old>` is
  the current unincremented old counter). File-wide notes use `.../diffs#<sha1>`. Fall back
  to `https://gitlab.com/<project-path>/-/blob/<source-branch>/<file>#L<line>` only for
  lines outside the MR diff.
- One or two sentences, factual, no hedging, no AI-flavored preamble. State the failure
  scenario concretely.
- Where a small code change fixes it, include a GitLab suggestion block ready to paste:

  ````markdown
  ```suggestion:-0+0
  <replacement lines>
  ```
  ````

Order most-severe first. If nothing survives verification, say so plainly — do not pad.
Do NOT post comments to the MR unless the user asks; print them for the user to post.

## 4. Optional: --fix

Only when the user asks (`--fix`, "fix them and push"): in the review worktree, apply the
agreed fixes, run the repo's tests/lint, commit in the MR's existing style (include the
PUBS/QAPUBS ref if the MR title has one), and push to the source branch. Print branch,
HEAD sha, and the MR link afterwards. Clean up the worktree
(`git worktree remove .worktrees/review-<iid>`) when done either way.
