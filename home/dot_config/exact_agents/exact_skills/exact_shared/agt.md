# agt availability

`agt` is the single CLI for the review store, tasks, watching, and CI triage
(`agt review`, `agt task`, `agt watch`, `agt ci`). The skill that points here names
the minimum version.

Run `agt --version` once per run. When it fails or prints an older version than the
stated minimum, run `mise install github:brandonocasey/agent-review` (it reads the
GitHub token of `gh`), then check again. When it still fails, stop and report:
`agt <minimum> missing: run gh auth login, then mise install; Windows is not supported`.
