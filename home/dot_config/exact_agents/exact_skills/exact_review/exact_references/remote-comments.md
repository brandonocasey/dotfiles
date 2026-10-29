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
keeps the review summary current. GitLab and GitHub only, and only in a repository inside
the user's organization; for an upstream or other outside repository, print as for
other MRs/PRs. Never post on any other MR/PR unless the user asks; then post only
the findings the user chose with
`agt review publish --not-own --only <ids>` per [output.md](output.md). It never posts the summary.

### IDs and signature

- Run ID: `rv-` plus 4 random lowercase letters or digits, new per review run, from
  `agt review pass start --kind full`.
- Pass ID: `c<cycle>p<pass>`; `p0` is the full review, `p1`–`p3` the fix checks.
- Reviewer ID: `r<n>`, unique within the run, from `pass start`. A continued reviewer
  keeps its ID.
- Signature: the reviewer's `model`, `effort` and `harness` (`claude-code` or
  `codex`), recorded by `pass start`. Write `default` for an unknown effort. Mark
  findings from the cycle 2 reveal `post_reveal`. The fixer is reviewer ID `fix`.
  Posted comments carry only the footer `> <sub>🔍 agt review · <model></sub>`;
  the summary footer names every reviewer and model.
- Harness version: run `claude --version` or `codex --version` once per run.
- Starting context, per reviewer and pass: the starting SHA plus `fresh`,
  `continued <pass> + <N> findings, fix diff`, or `blind, threads after lock`.

### Publishing

After each pass and its fix push (or after the pass, when nothing was fixed), run
`agt review publish --target <key>` per [store.md](store.md); prefix
`GITLAB_HOST=<host>` when self-hosted. It syncs first, then posts every pending
finding, reply, and resolve, and updates the summary when a run ended or its text changed.
A rerun matches posted items instead of posting again. Read only its returned links and failures; rerun a failure once
yourself. It refuses an MR/PR the user did not author. When its output has `kept_local`,
posting is off (`[forge] post`): it posted nothing and exits 0. Report `kept local (posting off)`
once; do not rerun it or post with `gh` or `glab`. What it posts:

- **Finding body.** The kind on its own line (`**🐛 bug (high)**`, `**❓ question**`,
  `**🎯 requirement**`, `**✏️ nit**`), the step 3 comment text, and the footer
  `> <sub>🔍 agt review · <model></sub>`. Finding threads carry the marker
  `<!-- review-finding v1 id=<finding id> sha=<reviewed-sha> -->`. Every posted body,
  replies and the summary included, also ends with
  `<!-- agent-review id=<local-id> attempt=<attempt> -->`.
- **Findings, as one review.** GitHub: one `COMMENT` review per reviewed commit, one
  comment per in-diff finding (`side` `LEFT` for old, else `RIGHT`). GitLab: one draft
  note per in-diff finding, its lines mapped to and positioned on the latest MR head,
  each published by its own ID. Never use `bulk_publish`: it also publishes the user's
  own unfinished drafts.
- **Outside the diff.** Lines of a changed file that the diff does not show post as a
  resolvable thread on the whole file whose first line names the lines: GitHub a
  file-level review comment, GitLab a file discussion (or a diff discussion on the
  unchanged line). A GitLab position the host refuses falls back to a general thread.
  A file the MR/PR does not change posts as a general comment naming the location.
  On GitHub an agent never posts a general comment: on your own PR such a finding is
  listed in the summary with its whole text; on someone else's PR it goes in the
  review body.
- **Replies.** `resolve` posts the outcome as a reply, then resolves or reopens:
  `✅ Fixed in <sha> <subject>.`, `❌ Not fixed: <reason>.`, `🚫 Won't fix: <reason>.`,
  `➖ No longer applies: the code changed.`, `💬 Answered above.`, `📋 Moved to <issue>.`,
  or `✅ Resolved.` for a bare resolve. Agent replies end with the same footer. The
  user's reply to a GitHub general comment quotes it and links it.
- **Approval.** No comment. `--formal` is the host's approval only: a GitHub `APPROVE`
  review whose body is the marker, or GitLab's approve call. On your own GitHub PR, which
  GitHub will not let you approve, it is a `COMMENT` review with the approval text. When
  GitLab will not let you approve (HTTP 401 or 403), a comment carries the approval text
  instead.

````markdown
**🐛 bug (medium)**
<what breaks, when, and the fix>

```suggestion
<replacement lines>
```

> <sub>🔍 agt review · claude-opus-5-5</sub>
<!-- review-finding v1 id=rv-7k2m.c1p0.r1.f1 sha=<reviewed-sha> -->
<!-- agent-review id=rv-7k2m.c1p0.r1.f1 attempt=<attempt> -->
````

### Summary

One general comment per MR/PR, posted with the first ended run and edited in place
after that. GitLab: a plain note, so it never blocks merging. Past 65,000 characters
it continues in linked part comments. Its headline is the only status:

- `**⚠️ <N> to fix** at <head>`: open findings and failed or blocked QA checks
  that no open thread explains;
- `**⏳ <n> new commits not reviewed** at <head>`: nothing open, but no run read
  some commits;
- `**✅ Nothing to fix** at <head>`;
- then ` · <n> commits not reviewed`, ` · 🔍 approved` and ` · 🧪 QA approved` as
  they apply.

Each open item takes two lines: the emoji and first sentence in bold, then severity,
place, and its thread link. A collapsed Details section holds the QA checks table and
the closed findings; after approval only the QA table stays. The summary ends with
one `<!-- review-record v2 id=<run> head=<head> reviews-at-head=<N> open=<O> -->`
per run it covers. `reviews-at-head` counts the passes whose reviewed SHA is the
final head: full reviews, plus a fix check that found no major finding.

### Syncing

`agt review sync --pr <n|url>` imports every thread, comment, and review record of
the MR/PR. It trusts a `review-finding`, `agent-review`, or `review-record v2` marker
only when its author is the authenticated user, its `editor` is null or that user, and
it sits in the thread's first comment; it ignores the rest. Trusted records count in
`reviews_at_head`. A user's reply to a GitHub general comment reads back as `Fixed in`
or `Won't fix:` and resolves the comment. The record's `open` value is informational only.
