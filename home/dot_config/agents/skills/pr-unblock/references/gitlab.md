## GitLab path

Run these commands in the MR's repository. Prefix `GITLAB_HOST=HOST` for a
self-hosted GitLab. Verify flags with `glab <command> --help` before use.

| Need | Command |
| --- | --- |
| User login | `glab api user \| jq -r .username` |
| Inventory | `glab mr list --author=@me -F json -P 100 -p 1`; `all` drops `--author`. GitLab caps a page at 100: fetch `-p 2`, `-p 3`, and on until a page has fewer than 100 rows |
| Filters | `--base` is `--target-branch`, `--head` is `--source-branch`, `--repo` is `-R`; `--assignee`, `--label`, `--search` pass unchanged |
| MR state | `glab mr view N -F json` |
| Unresolved threads | `glab mr view N --unresolved` |
| Failed jobs | `glab ci get --pipeline-id PIPELINE_ID --with-job-details -F json` |
| Job log | `glab ci trace JOB_ID` |
| One retry | `glab ci retry JOB_ID` |

Map the `glab mr view` JSON to the blockers above:

- Head SHA is `sha`. Auto-merge is set when `merge_when_pipeline_succeeds` is
  true. Fork state: `source_project_id` differs from `target_project_id`.
  `squash_on_merge` true means the merge method is squash.
- A branch is the user's own when `author.username` equals the login and the
  MR is not from a fork.
- `has_conflicts` is true, or `detailed_merge_status` is `need_rebase` or
  `conflict`: rebase or update the branch.
- `head_pipeline.status` is `created`, `pending`, or `running`: wait.
- `head_pipeline.status` is `failed`: read each failed job's full log. Fix or
  retry per [Fix failing checks](check-repair.md), with `glab ci trace` and
  `glab ci retry` in place of the `gh run` commands.
- `detailed_merge_status` is `not_approved` or `requested_changes`: a review
  blocker. `draft` true or `draft_status`: a draft blocker.
  `discussions_not_resolved`: an unresolved-thread blocker.
- `ci_must_pass` or `ci_still_running`: apply the pipeline rules above.
- `checking`, `unchecked`, `preparing`, or `approvals_syncing`: wait and refresh
  the MR state.
- Any other status except `mergeable`: report the exact status and its owner.

GitLab has no merge-update command for another author's branch, and
`glab mr rebase` rewrites it. Report a stale or conflicting branch to its
author.
