# Remote review setup

Remote fetch — GitLab:

```sh
glab mr view <iid> --repo <project-path>    # title, description, state, branches
glab mr diff <iid> --repo <project-path>
glab api --paginate "projects/<url-encoded-project-path>/merge_requests/<iid>/notes?per_page=100"  # discussion: main session only, never reviewers
```

Remote fetch — GitHub:

```sh
gh pr view <n> --repo <owner>/<repo>              # title, description, state, branches
gh pr diff <n> --repo <owner>/<repo>
gh pr view <n> --repo <owner>/<repo> --comments   # discussion: main session only, never reviewers
gh api --paginate repos/<owner>/<repo>/pulls/<n>/comments
```

The API command includes inline review comments. Reviewers never run the discussion
commands, so earlier reviews cannot steer them. The main session matches findings
to threads per [output.md](output.md).

Remote fetch — Forgejo:

```sh
fj -H <host> pr view <id>
fj -H <host> pr view <id> diff
fj -H <host> pr view <id> comments
```

This supports a read-only review. For `--fix`, `--threads`, or merge, report
that the platform is unsupported and stop before any mutation.

## Source checkout

- **Remote target**: check out the source branch in a worktree per the `worktree` skill —
  never the main checkout. The repo may not be the current working directory: locate the
  project's main checkout (the `worktree` skill's `<main-checkout>`) and fetch there,
  because `FETCH_HEAD` belongs to the checkout that fetched.

  ```sh
  git -C <main-checkout> fetch origin <source-branch>          # GitLab, or same-repo GitHub PR
  # GitHub fork: fetch origin pull/<n>/head
  # GitLab fork: fetch origin refs/merge-requests/<iid>/head
  ```

  Pin the fetched commit and verify it matches the review's head SHA.
  Inspect `git -C <main-checkout> worktree list --porcelain` and the intended
  `<main-checkout>/.worktrees/review-<number>` path before adding anything.
  Reuse a compatible earlier-pass checkout, existing source-branch worktree, or
  matching named review worktree, including one retained by another session.
  Reused checkouts must be outside the main checkout and match the pinned head.

  A stale detached review worktree may move with
  `git -C <wt> switch --detach <head-sha>` only when clean and not in use.
  Never reset local changes or move an existing source branch to match the pin.
  If a matching checkout or path is dirty, locked, occupied, or incompatible,
  report the blocker; never bypass it with a timestamped or suffixed duplicate.
  Only when no reusable checkout or matching path exists, create the stable name:

  ```sh
  git -C <main-checkout> worktree add --detach .worktrees/review-<number> <head-sha>
  ```

  Report whether the checkout was created or reused. At review cleanup, follow
  `output.md`: remove only a worktree this review created, unless its retention
  rules apply. Never remove a pre-existing checkout during ordinary review cleanup.

## Linked MRs/PRs

When the request or the MR/PR description names a companion or linked MR/PR, review it in
the same run. Do not ask first. Report each one separately. Apply `--fix`, `--threads`,
and merge only to MRs/PRs that the user names or authored; review the others read-only.
