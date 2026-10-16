# MR/PR threads

GitLab and GitHub only. On any other platform, including Forgejo, report that
`--threads` is unsupported and stop before any reply or resolve.

## Procedure

Use the `agent-review` commands in [store.md](store.md), each with the
`--target <key>` that `sync` prints. Set `GITLAB_HOST=<host>` for a self-hosted GitLab.

1. List unresolved discussions: `agent-review sync --pr <n|url>`, then
   `agent-review list --open`.
2. Classify each one: `fixed` (cite the commit sha), `stale`, `valid`, or `question`.
   Record `valid` and `question` with `agent-review resolve <id> --triage <class>`.
3. If the user only asked about status, stop here and report the table from step 7.
4. Fix the `valid` threads that the request covers through review step 4. Then classify them as `fixed`.
5. Reply in one plain sentence and resolve the `fixed` and `stale` threads:
   one `agent-review resolve <id>... --fixed <sha> --reply '<reply>'` for the fixed
   threads and one `agent-review resolve <id>... --triage stale --reply '<reply>'` for
   the stale ones (each thread its own call when the replies differ), then
   `agent-review publish`. Add `--not-own` when the user did
   not author the MR/PR; it then posts only replies and resolves. Show the user
   `publish --dry-run` output first.
   The user's request authorizes this for the named MR/PR only.
   Never reply or resolve on a repository outside the user's organization unless the user names that action.
6. Print draft replies for `question` threads for the user to post, as in [output.md](output.md). Do not post them.
7. Report a table: thread link, class, and action taken.
