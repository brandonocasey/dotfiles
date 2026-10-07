# Compare shared agent setup across hosts

Run `host-preflight` before depending on remote tools. The read-only helper
needs Node and Chezmoi on each host. Run it from this skill directory:

```sh
node scripts/check-drift.cjs --remote root@koof.win
```

Repeat `--remote` for more hosts. Repeat `--path` with home-relative files or
directories to narrow the scope. The default covers managed `.config/agents`,
`.codex/agents`, and the four `agent-*` helpers named in the script.
App-owned synced skills are excluded. Unmanaged files need a separate explicit
comparison; their absence from a managed inventory does not prove agreement.

The JSON reports host coverage, source or installed drift, missing sources,
unreadable files, and broken relative Markdown links. `--details` adds resolved
paths and SHA-256 hashes. Exit 1 means drift or incomplete coverage; exit 2
means invalid arguments. No files change and no scripts or hooks run.

The comparison checks installed content against `chezmoi cat`, including
host-rendered templates. Identical templates may produce different content
on each host. Other intentional differences need a reason and exact installed
hashes in an exceptions file passed with `--exceptions`:

```json
[
  {
    "path": ".config/agents/example.md",
    "reason": "The approved host-specific instruction",
    "hosts": {"local": "SHA256", "root@koof.win": "SHA256"}
  }
]
```

An exception applies only when every named hash still matches and each file
matches its own source. It cannot suppress a stale installation or broken link.
Inspect each mismatch before treating one host as authoritative.

For authorized synchronization, preserve unrelated work and required backups,
update the owning source, then apply only the approved paths. Check automatic
Git settings and hooks first. Run this comparison after installation on every
named host. Report every unresolved mismatch and intentional difference.
