# Review store

Review runs, passes, findings, threads, and MR/PR comments live in the
`agt review` CLI, one store per repository. `agt review --help` and the README
of https://github.com/brandonocasey/agt document every command, flag,
and output field. This file names what the review skill uses.

## Availability

These rules need `agt` 0.26.0 or newer. Follow [agt.md](../../shared/agt.md).

## Commands

Setup runs `sync` and `status`; later steps run the rest. Reviewers never run
`agt review`. Run every store command from the review worktree, `sync` included.
Run it bare: never pipe its output through `head`, `tail`, `rg`, or `jq`; the output
is one short JSON line, and a filter hides IDs and errors. Errors start with
`agt: error:` and name the valid run, pass, or reviewer IDs. Chain store
commands whose output you do not need with `&&` in one call. Pass IDs are
`c<cycle>p<n>`: `c1p0` is the first full review, `c1p1` its first fix check, `c2p0`
the second cycle's full review.

Pick the store target once per review:

- GitHub or GitLab MR/PR: after checkout, setup runs `agt review sync --pr <n|url>`,
  which imports the MR/PR's threads and records and prints the target key (`gh-<n>` or
  `gl-<iid>`). Setup reports the key. For a self-hosted GitLab, prefix every
  `agt review` command with `GITLAB_HOST=<host>`. Runs that ended before the target
  got its MR/PR do not count for it.
- MR/PR on any other forge (Forgejo, unknown hosts): `--range <pinned range>`, read-only:
  no `sync`, no `publish`, no skip check.
- Commit or range the user named, or work on the default branch itself (its fixes go
  on a fix branch, [fix.md](fix.md)): `--range <from>..<to>` (or `--range <sha>`). It
  pins those commits: never amend, squash, or rebase them; add fix commits on top.
- Local branch reviewed from a detached checkout: `--range <pinned range>` throughout
  the run. Keep this target if repairs later attach the checkout to a fix branch.
- A branch, also with a user-given base ("branch X against Y"), and anything else,
  including an end-point review of the session's own work (`<review_from>..HEAD` plus
  uncommitted work, [when-to-run.md](when-to-run.md)): no target flag, so the branch
  target records it, uncommitted work included. When the base branch Y is not the
  default branch, add `--default-branch Y` to every store command of the review.

Pass the target flag (`--target <key>` or `--range <range>`) to `pass start`, `status`,
`list --open`, `sync`, and `publish`. A command that names a run (`--run`, or a
finding ID of a local run) finds a range or MR/PR target itself; a branch target is
always the checked-out branch's. Threads imported from an MR/PR (IDs whose run is not
in this store) still need `--target <key>`.

| When | Command |
|---|---|
| Before the run's first reviewers start | `pass start --kind full --base <base> --reviewers -` (no `--run`: it starts the run); prints the run ID and pass `c1p0` |
| Before later reviewers start | `pass start --run <run> --kind full\|fix-check\|reveal --base <base> --reviewers -` |
| After re-verifying the pass's findings | `pass end --run <run> --pass <pass> --findings - --reviewer <id>`: every finding of the pass, surviving and killed, in one array; a finding of another reviewer adds `"reviewer": "<id>"`; `[]` for none; `--lock` for the blind review; with reviewer usage, send `{"findings": [...], "usage": [...]}` instead (**Usage input**) |
| Kill a blind finding after the reveal | `finding kill <id> --reason <text>`; works on a locked pass |
| Fixes applied | `resolve <id>... --fixed <sha> --reviewer <run>.<pass>.fix`: replies `✅ Fixed in <sha> <subject>.` and resolves each |
| The user declines a finding, or it proves wrong after it was posted | `resolve <id> --rejected "<reason>"` with the main session's `--model`, `--effort`, `--harness` and `--harness-version`: replies `Won't fix: <reason>.` and resolves; the record counts it as rejected, not fixed; a finding not yet posted stays unposted |
| Fix check says not fixed | `resolve <id> --not-fixed "<reason>" --reviewer <run>.<pass>.<id>`: replies and reopens |
| Held question | `resolve <id> --triage question`; record the user's answer with `reply <id> --local --body <answer>` (never posted) |
| Fix-check inputs | `list --run <run> --cycle <n> --format prompt` (`--head HEAD` for a commit or range target) |
| Reveal inputs | `list --run <run> --cycle 1 --format prompt` (`--head HEAD` for a commit or range target) |
| Prior reviews, open items, review range | `status [--head <sha>]` (`--full` adds commits and runs), `list --open` |
| Post to an MR/PR | `publish`, also the review summary (one per MR/PR, updated for each ended run); `publish --dry-run` prints every payload; on another person's MR/PR when the user asks, `publish --not-own --only <ids>` after a `--dry-run` with the same flags (findings and user-written threads, never records) |
| Approve (`--approve`, [approve-merge.md](approve-merge.md)) | `publish --approve`, `--formal` only on request; see approve-merge.md step 4 |
| After the run's last fix commit | `run end --run <run>`, plus `--reveal-agree <n> --reveal-disagree <m>` after a reveal, and `--usage -` with the main session's usage when known; records HEAD as reviewed and prints `status` and `spent`, so skip a separate `status` call |

Always pass `--base` to every full pass (`pass start --kind full`, also for the second cycle): the pinned range's start (`<review_from>` for
an end-point review), `HEAD` for a working-diff target, or the pinned merge-base for an
MR/PR. Without it every branch commit counts as reviewed. For a commit or range target,
also pass `--head HEAD` (the fix head) to every `pass start` after the first full
review, and to the first one when testing-stage fixes moved HEAD
([testing.md](testing.md) step 6), to fix-check and reveal `list`, and to `run end`; `pass end`, `finding`, and
`resolve` take no `--head`. Only `reply` and `resolve --fixed`/`--not-fixed`/`--rejected`/`--reply`
add text.

`--reviewers -` reads a JSON array from stdin, one entry per reviewer: `model`,
`effort`, `harness`, `harness_version`, and `starting_context` (see **IDs and
signature** in [remote-comments.md](remote-comments.md)). A continued reviewer gives
only its `id` and `starting_context`. Add the main session as reviewer `fix` when
it fixes, with its model, effort, harness, and harness version. Test results go to
`agt qa` per [testing.md](testing.md) **Record**.

## Finding input

Convert each reviewer's prose return to this JSON. `pass end --findings`
reads one object or an array and rejects unknown fields. Add surviving
findings and killed ones, each killed one with its one-line reason.

| Field | Type | Required | Meaning |
|---|---|---|---|
| `type` | `bug`, `question`, `requirement`, `nit`, `comment` | yes | Finding class |
| `severity` | `high`, `medium`, `low` | for `bug` | Bug severity |
| `scenario` | string | yes | Failure scenario; becomes the first comment |
| `path` | string | with any line field | File, relative to the repository root |
| `line` | integer | no | New-side line; omit with `path` for a file-level finding |
| `start_line` | integer | no | First line of a multi-line range ending at `line` |
| `old_line` | integer | for `side: old` | Old-side line |
| `side` | `new`, `old` | no | Default `new`, or `old` when only `old_line` is set |
| `evidence` | string | no | Evidence for the finding |
| `tests_run` | array of strings | no | Tests or commands the reviewer ran |
| `post_reveal` | boolean | no | Found during the cycle 2 reveal |
| `killed` | boolean | no | `true` stores it as a killed finding on the pass |
| `reason` | string | when `killed` | Why it was killed; only for killed findings |
| `reviewer` | string | no | Reviewer ID (`r1`, `fix`); default `--reviewer` |

For a surviving finding, `scenario` is the step 3 comment text, suggestion block
included, without its kind label (remote-comments.md **Finding body**); `publish` adds it.
Record a `pre-existing` finding as type `comment` with a scenario that starts
`Pre-existing <type> (<severity>):`, so it never blocks approval or the step 7 gate.
Line numbers refer to the pass's reviewed head, or its tree for uncommitted work. The output lists the new finding IDs under `added` and `killed`.

## Usage input

Record what each reviewer spent when the harness reports it, such as the
`<usage>` line of a sub-agent result: one `usage` entry per reviewer, as
`{"reviewer": "r1", "tokens": <total_tokens>, "duration_ms": <ms>, "tool_uses": <n>}`.
Omit unknown fields; skip usage when none is reported. For `run end --usage -`,
send an array with `role` (`fix` or `main`) in place of `reviewer`,
only with numbers the harness reports. Never estimate. `run end` adds review and
fix time to its output and the summary.
