# Review store

Review runs, passes, findings, threads, and MR/PR comments live in the
`agent-review` CLI, one store per repository. Its README
(`~/Projects/brandonocasey/agent-review/README.md`) and `agent-review --help`
document every command, flag, and output field. This file names what the review
skill uses.

## Availability

Run `agent-review status --help` once per run. When it fails, stop and report:
agent-review missing: run `mise run install` in
`~/Projects/brandonocasey/agent-review`.

## Commands

Setup runs `sync` and `status`; the main session runs the rest. Reviewers never run
`agent-review`. Run every store command from the review worktree, `sync` included.
Pick the target the same way on every command of a review:

- GitHub or GitLab MR/PR: after checkout, setup runs `agent-review sync --pr <n|url>`,
  which imports the MR/PR's threads and records and prints the target key (`gh-<n>` or
  `gl-<iid>`). Setup reports the key; pass `--target <key>` on every later command for
  that review. Never run a store command for an MR/PR without `--target`. For a
  self-hosted GitLab, prefix every `agent-review` command with `GITLAB_HOST=<host>`.
  Runs that
  ended before the target got its MR/PR do not count for it.
- MR/PR on any other forge (Forgejo, unknown hosts): `--range <pinned range>`, read-only:
  no `sync`, no `publish`, no skip check.
- Commit or range the user named: `--range <from>..<to>` (or `--range <sha>`).
- Anything else, including an end-point review of the session's own work
  (`<review_from>..HEAD` plus uncommitted work, [when-to-run.md](when-to-run.md)): no
  flag, so the branch target records it, uncommitted work included.

| When | Command |
|---|---|
| Before a run's first pass | `run start`; it prints the run ID |
| Before reviewers start | `pass start --run <run> --kind full\|fix-check\|reveal --base <base> --reviewers -` |
| After re-verifying a reviewer's findings | `finding add --run <run> --pass <pass> --reviewer <id> < findings.json` |
| When the pass's findings are added | `pass end --run <run> --pass <pass>`; `--lock` for the blind review |
| Kill a blind finding after the reveal | `finding kill <id> --reason <text>`; works on a locked pass |
| Fix applied | `reply <id> --body "Fixed in <sha>." --run <run> --pass <pass> --reviewer fix`, then `resolve <id> --triage fixed --resolution "fixed <sha>"` |
| Fix check says not fixed | `reply <id> --body "Not fixed: <reason>" --run <run> --pass <pass> --reviewer <id>`, then `resolve <id> --reopen --resolution "not fixed: <reason>"` |
| Held question | `resolve <id> --triage question`; record the user's answer with `reply <id> --local --body <answer>` (never posted) |
| Fix-check inputs | `list --run <run> --cycle <n> --format prompt` (`--head HEAD` for a commit or range target) |
| Reveal inputs | `list --run <run> --cycle 1 --format prompt` (`--head HEAD` for a commit or range target) |
| Prior reviews, open items, review range | `status [--head <sha>]`, `list --open` |
| Post to an MR/PR | `publish`, also the final record of each ended run; `publish --dry-run` prints every payload; on another person's MR/PR when the user asks, `publish --not-own --findings --only <ids>` after a `--dry-run` with the same flags (findings and user-written threads, never records) |
| After the run's last fix commit | `run end --run <run>`, plus `--reveal-agree <n> --reveal-disagree <m>` after a reveal; records HEAD as reviewed |

Always pass `--base` to `pass start`: the pinned range's start (`<review_from>` for an
end-point review), `HEAD` for a working-diff target, or the pinned merge-base for an
MR/PR. Without it every branch commit counts as reviewed. For a commit or range target,
also pass `--head HEAD` (the fix head) to every `pass start` after the first full
review, to fix-check and reveal `list`, and to `run end`. `resolve` posts no text; only `reply`
does.

`--reviewers -` reads a JSON array from stdin, one entry per reviewer: `model`,
`effort`, `harness`, `harness_version`, and `starting_context` (see **IDs and
signature** in [remote-comments.md](remote-comments.md)). A continued reviewer gives
only its `id` and `starting_context`. Add the main session as reviewer `manual` when
it runs the manual pass and as reviewer `fix` when it fixes, each with its model,
effort, harness, and harness version.

## Finding input

Convert each reviewer's prose return to this JSON. `finding add` reads one object or
an array from stdin and rejects unknown fields. Add surviving findings and killed
ones, each killed one with its one-line reason.

| Field | Type | Required | Meaning |
|---|---|---|---|
| `type` | `bug`, `question`, `requirement`, `nit`, `comment` | yes | Finding class |
| `severity` | `high`, `medium`, `low` | for `bug` | Bug severity |
| `scenario` (alias `body`) | string | yes | Failure scenario; becomes the first comment |
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

For a surviving finding, `scenario` is the step 3 comment text, suggestion block
included, without its leading `**<type> (<severity>):**` label; `publish` adds it.
Line numbers refer to the pass's reviewed head, or its tree for uncommitted work. The output lists the new finding IDs under `added` and `killed`.
