# MR/PR threads

Use this reference for `review --threads`. GitLab and GitHub only. For another
platform, report that `--threads` is unsupported and stop before any reply or resolve.

## Procedure

1. List unresolved discussions with the commands below.
2. Classify each one: `fixed` (cite the commit sha), `stale`, `valid`, or `question`.
3. If the user only asked about status, stop here and report the table from step 7.
4. Fix the `valid` threads that the request covers through review step 4. Then classify them as `fixed`.
5. Reply in one plain sentence and resolve the `fixed` and `stale` threads.
   The user's request authorizes this for the named MR/PR only.
   Never reply or resolve on a repository outside the user's organization unless the user names that action.
6. Write draft replies for `question` threads to the review's comment file. Do not post them.
7. Report a table: thread link, class, and action taken.

## GitLab

```sh
glab api --paginate "projects/<enc-path>/merge_requests/<iid>/discussions?per_page=100"
glab api -X POST "projects/<enc-path>/merge_requests/<iid>/discussions/<id>/notes" -f body='<reply>'
glab api -X PUT "projects/<enc-path>/merge_requests/<iid>/discussions/<id>" -f resolved=true
```

Use only discussions whose first note has `resolvable: true` and `resolved: false` (`notes[0]`).
Prefix each command with `GITLAB_HOST=<host>` when self-hosted.

## GitHub

List threads with `isResolved: false`:

```sh
gh api graphql -f o=<owner> -f r=<repo> -F n=<n> -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{id isResolved isOutdated path line comments(first:20){nodes{author{login} body url}}}}}}}'
```

Reply to and resolve one thread:

```sh
gh api graphql -f id=<thread-id> -f b='<reply>' -f query='mutation($id:ID!,$b:String!){addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id,body:$b}){comment{url}}}'
gh api graphql -f id=<thread-id> -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}'
```
