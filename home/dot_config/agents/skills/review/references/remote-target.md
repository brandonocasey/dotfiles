# Remote review setup

Remote fetch — GitLab:

```sh
glab mr view <iid> --repo <project-path>    # title, description, state, branches
glab mr diff <iid> --repo <project-path>
glab api --paginate "projects/<url-encoded-project-path>/merge_requests/<iid>/notes?per_page=100"  # existing discussion — skip already-raised points
```

Remote fetch — GitHub:

```sh
gh pr view <n> --repo <owner>/<repo>              # title, description, state, branches
gh pr diff <n> --repo <owner>/<repo>
gh pr view <n> --repo <owner>/<repo> --comments   # existing discussion — skip already-raised points
```

## Source checkout

- **Remote target**: check out the source branch in a worktree per the `worktree` skill —
  never the main checkout. The repo may not be the current working directory: locate the
  project's main checkout (the `worktree` skill's `<main-checkout>`) and run both commands
  against it, because `FETCH_HEAD` belongs to the checkout that fetched. A review worktree is
  detached on purpose, so it takes a commit-ish rather than `-b <branch>`.

  ```sh
  git -C <main-checkout> fetch origin <source-branch>          # GitLab, or same-repo GitHub PR
  git -C <main-checkout> worktree add --detach .worktrees/review-<number> FETCH_HEAD
  # GitHub fork: fetch origin pull/<n>/head, then add --detach from FETCH_HEAD
  # GitLab fork: fetch origin refs/merge-requests/<iid>/head, then add --detach from FETCH_HEAD
  ```
