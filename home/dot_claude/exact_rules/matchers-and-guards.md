---
paths:
  - "**/*guard*"
  - "**/*.rules"
  - "**/hooks/shell.ts"
---
# Matchers and guards

- **Code that matches, blocks, or rewrites shell commands:** tokenize with a shell-aware parser, not a regex over raw text. Keep a table of must-match and must-not-match commands and rerun all of it after every change. Rows: wrappers with options (`env X=1`, `sudo -u x`, `timeout 5`, `nohup`, `nice -n 5`, `xargs`); `sh -c '...'`, subshells, pipelines, `if`/`for`/`while`; commands after `;`, `&&`, `||`, `&`, or a newline; attached or grouped flags (`-pc`, `-ubob`, `--flag=x`, `-p)`); quoted text, heredocs, and words that merely contain the name. A rewrite leaves any command it cannot fully parse unchanged.
- **Code that allows, denies, selects, caps, or filters text you do not control (regex, glob, allowlist, prefix or substring test, search query, URL test, size limit, mention or markup escaping, path guard):** list inputs it must accept and inputs it must reject, and run it on both before handoff. Include near misses and equivalent forms: the key word inside a longer name, quoted or commented-out text, text your own code wrote earlier, a URL on another host or forge, names with `:` or `/`, other encodings or introducers (C1 and ESC forms, a user-group mention beside `@here`), a path's case variant on a case-insensitive file system, symlinks and special files, and data that grows after the check (decompression, repeat, copy). Match whole tokens or parsed fields, not the raw string, and enforce the check at the one place all forms pass through. After each fix, list the forms again; a fix for one form often opens another.
