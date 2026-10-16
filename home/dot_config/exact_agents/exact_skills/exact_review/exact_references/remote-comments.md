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
other MRs/PRs. Never post on any other MR/PR unless the user asks; then post only
the findings the user chose with
`agent-review publish --not-own --findings --only <ids>` per [output.md](output.md). It never posts records.

### IDs and signature

- Run ID: `rv-` plus 4 random lowercase letters or digits, new per review run, from
  `agent-review run start`.
- Pass ID: `c<cycle>p<pass>`; `p0` is the full review, `p1`–`p3` the fix checks.
- Reviewer ID: `r<n>`, unique within the run, from `pass start`. A continued reviewer
  keeps its ID.
- Signature: `<model-id> <effort> <harness> <run>.<pass>.<reviewer>`, such as
  `claude-opus-5-5 xhigh claude-code rv-7k2m.c1p0.r1`. Harness is `claude-code` or
  `codex`. Write `default` for an unknown effort. Add ` post-reveal` to findings
  from the cycle 2 reveal. The fixer signs with reviewer ID `fix`.
- Harness version: run `claude --version` or `codex --version` once per run.
- Starting context, per reviewer and pass: the starting SHA plus `fresh`,
  `continued <pass> + <N> findings, fix diff`, or `blind, threads after lock`.

### Publishing

After each pass and its fix push (or after the pass, when nothing was fixed), run
`agent-review publish --target <key>` per [store.md](store.md); prefix
`GITLAB_HOST=<host>` when self-hosted. It syncs first, then posts every pending
finding, reply, and resolve, plus the final record of each ended run not yet posted.
A rerun matches posted items instead of posting again. Read only its returned links and failures; rerun a failure once
yourself. It refuses an MR/PR the user did not author. What it posts:

- Each finding body holds the step 3 comment text, the finding's signatures (one per
  reviewer that raised it), and the marker
  `<!-- review-finding v1 id=<finding id> sha=<reviewed-sha> -->`. Every posted body,
  replies and the final record included, also ends with
  `<!-- agent-review id=<local-id> -->`.
- **Findings, as one review.** GitHub: one review with `commit_id` set to the reviewed
  SHA, `event` `COMMENT`, `body` `Review findings.`, and one comment per in-diff
  finding (`side` `LEFT` for old, else `RIGHT`). GitLab: one draft note per in-diff
  finding, its lines mapped to and positioned on the latest MR head, each published
  by its own ID. Never use `bulk_publish`: it also publishes the user's own unfinished
  drafts.
- **Outside the diff.** GitLab: a resolvable thread. GitHub: a general comment; it
  cannot be resolved, so `publish` posts a reply to it as a new general comment
  ending `Re: <finding id>`.
- **Replies.** Fixed: `resolve <id>... --fixed <sha> --run <run> --pass <pass>
  --reviewer fix` adds the `Fixed in <sha>.` reply and resolves. Not fixed:
  `resolve <id> --not-fixed "<reason>"` with the fix-check reviewer's `--run`,
  `--pass`, and `--reviewer` adds the `Not fixed: <reason>.` reply and reopens.
  `publish` posts each reply with its author's signature, then resolves or reopens
  the thread.
- **Final record.** GitLab: a note with `resolvable=false`, so it never blocks
  merging. GitHub: a general comment.

````markdown
**bug (medium):** <what breaks, when, and the fix>

```suggestion
<replacement lines>
```

claude-opus-5-5 xhigh claude-code rv-7k2m.c1p0.r1
<!-- review-finding v1 id=rv-7k2m.c1p0.r1.f1 sha=<reviewed-sha> -->
<!-- agent-review id=rv-7k2m.c1p0.r1.f1 -->
````

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

### Syncing

`agent-review sync --pr <n|url>` imports every thread, comment, and review record of
the MR/PR. It trusts a `review-finding`, `agent-review`, or `review-record v2` marker
only when its author is the authenticated user, its `editor` is null or that user, and
it sits in the thread's first comment; it ignores the rest. Trusted records count in
`reviews_at_head`. A marked GitHub general comment stays open until a later comment by
that user ends with `Re: <its finding id>` after `Fixed in`. The record's `open` value
is informational only.
