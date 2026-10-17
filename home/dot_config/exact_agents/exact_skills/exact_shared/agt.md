# agt availability

`agt` is the single CLI for the review store, tasks, watching, CI triage, and issues
(`agt review`, `agt task`, `agt watch`, `agt ci`, `agt issue`). The skill that points here names
the minimum version.

Run `agt --version` once per run. When it fails or prints an older version than the
stated minimum, run `mise install github:brandonocasey/agt` (it reads the
GitHub token of `gh`), then check again. When it still fails, stop and report:
`agt <minimum> missing: run gh auth login, then mise install; Windows is not supported`.

A skill that works without `agt` says so and skips the install above. It uses its
own fallback instead.
