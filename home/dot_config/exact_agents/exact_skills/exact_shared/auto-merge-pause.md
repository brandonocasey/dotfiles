# Pause auto-merge while working on an MR/PR

Applies when a task will push to the branch of an MR/PR that has auto-merge on,
in any workflow: `ship`, `pr-fix`, review `--fix`, or CI repairs. Otherwise CI can
merge a head that is still being changed, reviewed, or repaired.

## Pause

Pause when work on the MR/PR starts, before editing. Read its state again right
before each push, and pause again if auto-merge was turned back on.
Cover every MR/PR the push updates, including submodule MRs/PRs.

## Queued MR/PR

First, check whether the MR/PR is in a merge queue or merge train:

- GitHub: `gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){pullRequest(number:<n>){mergeQueueEntry{state}}}}'`;
  a non-null `mergeQueueEntry` means queued.
- GitLab: `glab api "projects/:id/merge_trains/merge_requests/<iid>"`; a 404
  means it is not on a train.

If it is queued, skip the steps below and leave it untouched; never push to its
branch. Fetch its source branch and start a new branch from that commit with the
`worktree` skill, per [dependent-branches.md](dependent-branches.md). Keep the
ticket key in the branch name. Cherry-pick any task commits already made on the
queued branch; leave the originals and report them. Ship the new branch as a new
MR/PR. This covers `ship`, review `--fix`, and CI repairs; `pr-fix` keeps its own
rule to wait on a queued PR.

## Pause steps

1. Record the merge method. GitHub: `gh pr view <number> --json autoMergeRequest`;
   map `mergeMethod` `MERGE`, `SQUASH`, `REBASE` to `--merge`, `--squash`, `--rebase`.
   GitLab: `glab mr view <iid> -F json`; restore with `--squash` only when
   `squash_on_merge` is true. The project's merge method needs no flag.
2. Disable it:
   - GitHub: `gh pr merge <number> --disable-auto`.
   - GitLab: `glab api -X POST "projects/:id/merge_requests/<iid>/cancel_merge_when_pipeline_succeeds"`.
     Run it in the MR's repository checkout, prefixed with `GITLAB_HOST=<host>` for
     a self-hosted GitLab; `:id` comes from that checkout.
3. Read the state back and confirm auto-merge is off.

If it cannot be disabled for another reason, report why. Then review before the
push; that review is the hand-off review, and `ship` skips its after-push review.

## Restore

Re-enable it once the work's pushes are complete: in `ship`, after the review, any
follow-up review, and their fix pushes end; otherwise right after the push. Use the
recorded method and the last `HEAD_SHA`, with the commands in ship's
[merge.md](../ship/references/merge.md) **Enable auto-merge**. Read the state back
and report it. Restoring needs no new merge consent; it returns the user's setting.

Leave it off while a blocking finding or failed repair remains. Then report that
auto-merge is paused, with its method and the restore command. In a
`session-resume` record, put the pause and method in `nextStep` as plain text.
