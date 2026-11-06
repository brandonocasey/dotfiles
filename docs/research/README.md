# Research record for agent setup

This folder records why the dotfiles agent setup changed: the sources behind each change and the results of the A/B tests and probes.

It sits outside the chezmoi root (`home/`), so chezmoi never applies it and agents never auto-load it. Read it on demand.

- [sources.md](sources.md): one section per change, grouped by topic. Each has the change, its status, commits, sources and how the session used them.
- [ab-tests.md](ab-tests.md): one section per test, newest first. Each has the question, setup, results, validity, decision, commits and sessions.

To add an entry, use the same block format. Put it newest first in its group (sources.md) or at the top (ab-tests.md). Verify each commit with `git cat-file -e <sha>^{commit}` and copy the real subject. Keep numbers and URLs as the source gave them. Link only raw data that still exists, and say "deleted" otherwise. Do not paste Claude session or artifact URLs.
