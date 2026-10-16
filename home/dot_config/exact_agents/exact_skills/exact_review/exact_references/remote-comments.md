# Remote review comments

## Link formats (MR/PR only)

GitLab — diff-line anchor in the Changes tab:
`https://<host>/<project-path>/-/merge_requests/<iid>/diffs#<sha1>_<old>_<new>`
where `<sha1>` = `printf '%s' '<repo-relative-file-path>' | shasum -a 1 | cut -d' ' -f1`
(`shasum` appends two spaces and `-`; the anchor breaks if you paste that) and `<old>`/`<new>` are
the diff positions of the line (walk the hunk from `@@ -o,c +n,c @@`: context lines increment
both counters, `-` only the old, `+` only the new; an added line's `<old>` is the current
unincremented old counter). File-wide notes use `.../diffs#<sha1>`. Fall back to
`https://<host>/<project-path>/-/blob/<source-branch>/<file>#L<line>` only for lines outside
the diff.

GitHub — diff-line anchor in the Files tab:
`https://github.com/<owner>/<repo>/pull/<n>/files#diff-<sha256>R<new-line>`
where `<sha256>` = `printf '%s' '<repo-relative-file-path>' | shasum -a 256 | cut -d' ' -f1`;
use `L<old-line>`
for a deleted line. File-wide notes use `...#diff-<sha256>`. Fall back to
`https://github.com/<owner>/<repo>/blob/<source-branch>/<file>#L<line>` for lines outside
the diff.

## Suggestion blocks (MR/PR only)

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

## Own MR/PR comments

Every review of an MR/PR authored by the authenticated user ([fix.md](fix.md) **Fix
authorization** names the lookup) posts its findings, resolves fixed ones, and
posts a final review record. GitLab and GitHub only, and only in a repository inside
the user's organization; for an upstream or other outside repository, print as for
other MRs/PRs. Never post on any other MR/PR unless the user asks.

### IDs and signature

- Run ID: `rv-` plus 4 random lowercase letters or digits, new per review run.
- Pass ID: `c<cycle>p<pass>`; `p0` is the full review, `p1`–`p3` the fix checks.
- Reviewer ID: `r<n>`, unique within the run. A continued reviewer keeps its ID.
- Signature: `<model-id> <effort> <harness> <run>.<pass>.<reviewer>`, such as
  `claude-opus-5-5 xhigh claude-code rv-7k2m.c1p0.r1`. Harness is `claude-code` or
  `codex`. Write `default` for an unknown effort. Add ` post-reveal` to findings
  from the cycle 2 reveal. The fixer signs with reviewer ID `fix`.
- Harness version: run `claude --version` or `codex --version` once per run.
- Starting context, per reviewer and pass: the starting SHA plus `fresh`,
  `continued <pass> + <N> findings, fix diff`, or `blind, threads after lock`.

### Main session's part

After each pass and its fix push (or after the pass, when nothing was fixed), write
`post-<run>-<pass>.json` in the task scratch directory, then start one `cheap`
sub-agent with exactly this prompt:

```text
Post review comments per **Posting agent** in <absolute path of remote-comments.md>.
Input: <absolute path of the JSON file>.
```

```json
{
  "platform": "gitlab | github", "host": "<host>", "repo": "<project-path or owner/repo>",
  "number": 123, "reviewed_sha": "<sha>",
  "diff_refs": {"base_sha": "", "start_sha": "", "head_sha": ""},
  "findings": [{"id": "rv-7k2m.c1p0.r1.f1", "path": "src/a.ts", "line": 42,
    "old_line": 40, "side": "new | old | context", "in_diff": true, "body_file": "<path>"}],
  "fixed": [{"id": "rv-7k2m.c1p0.r1.f1", "sha": "<short-sha>", "signature": "<fixer signature>"}],
  "not_fixed": [{"id": "<finding id>", "signature": "<fix-check reviewer signature>", "reason": "<one line>"}],
  "final_record_file": "<path, or null>"
}
```

Each body file holds the step 3 comment text, the finding's signatures (one per
reviewer that raised it), and the marker
`<!-- review-finding v1 id=<finding id> sha=<reviewed-sha> -->`. `diff_refs` is
GitLab only: the MR diff version of `reviewed_sha`. `line` is the new line for `new`
and `context`, the old line for `old`; `old_line` is set only for `context` (an
unchanged line inside a hunk). List only findings that
[output.md](output.md) says to post. Pass `final_record_file` with the last pass only. Read only the
agent's returned links and failures; retry a failure once yourself.

````markdown
**bug (medium):** <what breaks, when, and the fix>

```suggestion
<replacement lines>
```

claude-opus-5-5 xhigh claude-code rv-7k2m.c1p0.r1
<!-- review-finding v1 id=rv-7k2m.c1p0.r1.f1 sha=<reviewed-sha> -->
````

### Posting agent

Post exactly the given bodies; edit no other file. Put every command in one scratch
script beside the input, appending each response to `<input>.log`, and run it once.
Prefix `glab` with `GITLAB_HOST=<host>` when self-hosted.

1. **Findings, as one review.** Skip this step when no finding is in the diff.
   GitHub: write one review JSON with `commit_id` set to `reviewed_sha`, `event`
   `COMMENT`, `body` `Review findings.`, and one `comments` entry per in-diff finding
   (`path`, `line`, `side` `LEFT` for old, else `RIGHT`, `body`), then
   `gh api repos/<repo>/pulls/<n>/reviews --input <review.json>`. GitLab: per in-diff
   finding, `glab api -X POST "projects/<enc-repo>/merge_requests/<n>/draft_notes" -H 'Content-Type: application/json' --input <note.json>`
   with `{"note": <body>, "position": {"position_type": "text", "base_sha", "start_sha", "head_sha", "old_path", "new_path", ...}}`:
   `new_line` for `new`, `old_line` for `old`, both for `context`. Record each
   returned draft `id`, then publish only those, each with
   `glab api -X PUT "projects/<enc-repo>/merge_requests/<n>/draft_notes/<id>/publish"`.
   Never use `bulk_publish`: it also publishes the user's own unfinished drafts.
2. **Outside the diff.** GitLab: `glab mr note create <n> --repo <repo> -m "$(cat <body-file>)"`
   (a resolvable thread). GitHub: `gh pr comment <n> --repo <repo> --body-file <body-file>`; it
   cannot be resolved, so step 4 answers it with a new comment.
3. **Threads.** List all threads once, resolved ones included, with the
   [threads.md](threads.md) list command minus its unresolved filter. On GitHub, also
   list general comments per **Reading records**. Match each `fixed` and `not_fixed`
   id by the marker.
4. **Replies.** For `fixed`: reply `Fixed in <sha>.` plus the signature, then resolve.
   For `not_fixed`: reply `Not fixed: <reason>` plus the signature, then reopen
   (GitLab `-f resolved=false`; GitHub `unresolveReviewThread`). Use the
   [threads.md](threads.md) commands. For a GitHub general comment, post a new
   general comment instead: the reply text, then `Re: <finding id>`.
5. **Final record.** GitLab: `glab mr note create <n> --repo <repo> --resolvable=false -m "$(cat <file>)"`,
   so it never blocks merging. GitHub: `gh pr comment <n> --repo <repo> --body-file <file>`. Then
   read it back.

Return at most 15 lines: each finding id with its comment link, each thread action,
the final record link, and each failure with its exact error message.

### Final record

Post one general comment after the review ends, even with open items. One row per
reviewer per pass; a fix check row may list several continued reviewers.
`reviews-at-head` counts the passes whose reviewed SHA is the final head: full
reviews, plus a fix check that found no major finding.

```markdown
**Review rv-7k2m:** review-fixed at <short-head>. <C> cycles, <F> found, <X> fixed, <O> open.

| Pass | Reviewed | Starting context | Reviewer |
|---|---|---|---|
| c1p0 full | 1a2b3c4 | fresh | r1 claude-opus-5-5 xhigh · Claude Code 2.1.296 |
| c1p1 fix check | 1a2b3c4..5d6e7f8 | continued c1p0 + 2 findings, fix diff | r1 |
| c2p0 full | 5d6e7f8 | blind, threads after lock | r2 gpt-6-astra xhigh · codex-cli 0.162.1 |
| c2p1 fix check | 5d6e7f8..9e8d7c6 | continued c2p0 + 1 finding, fix diff | r2 |

Reveal: 2 agree, 0 disagree.
Fixed by: claude-opus-5-5 high · Claude Code 2.1.296
<!-- review-record v2 id=rv-7k2m head=<full-head-sha> reviews-at-head=<N> open=<O> -->
```

### Reading records

Read all general comments and keep those containing `<!-- review-record v2`. Trust
only records by the authenticated user; ignore the rest. The prior reviews of the
pinned head are the sum of `reviews-at-head` over trusted records whose `head`
equals it. The open items are the open threads that carry a `review-finding` marker
posted by the authenticated user, from the [threads.md](threads.md) list command.
On GitHub, a marked general comment by that user also counts as open until a later
comment by that user ends with `Re: <its finding id>` after `Fixed in`. The record's
`open` value is informational only.

```sh
glab api --paginate "projects/<url-encoded-project-path>/merge_requests/<iid>/notes?per_page=100"   # GitLab: author.username, body
gh api --paginate repos/<owner>/<repo>/issues/<n>/comments --jq '.[] | {user: .user.login, created_at, url: .html_url, body}'   # GitHub
```
