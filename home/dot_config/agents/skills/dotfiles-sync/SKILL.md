---
disable-model-invocation: true
name: dotfiles-sync
description: "Explicit-only: sync changed chezmoi targets to sources, scan for secrets, commit, and push."
---

Scope: Copy changed chezmoi targets to their sources, scan for secrets, commit, and push the chezmoi source repo. Explicit-only.


Optional argument: target paths. Without one, use the targets this session changed.

Invoking this skill is the consent to commit and push the current branch of the
chezmoi source repo, for this run only. It gives no standing consent. No rule
runs it automatically. Force-push stays forbidden.

Set the repo once: `SRC=$(git -C "$(chezmoi source-path)" rev-parse --show-toplevel)`.

1. **Scope.** Use the named targets, or the targets this session changed.
   Never include `~/.ssh`, `*credentials*`, `*.pem`, `*.key`, token files, or
   paths in `.chezmoiignore`. Report each excluded path by name only. Never
   print its contents. Never restore a path that a source commit removed.
2. **Status.** Run `chezmoi status <targets>`. Report listed targets that this
   session did not edit. Do not include them unless the user names them.
3. **Copy.** For each managed target, show `diff -u "$(chezmoi source-path <target>)" <target>`.
   For a new target, show `diff -u /dev/null <target>`.
   - Plain source: copy the target to that source path.
   - Source name starts with `symlink_`, `modify_`, `run_`, `create_`, or
     `encrypted_`, or ends in `.tmpl`: do not copy. Edit the source by hand
     and show the diff. For `symlink_`, sync the link target instead.
   - New file: run `chezmoi source-path <parent-directory>`. Add the file with
     the prefixes its siblings use, such as `private_` or `executable_`.
   - Never run `chezmoi add`, `re-add`, `edit`, `merge`, or `update`. With
     `autoCommit` or `autoPush` on, they commit or push on their own.
4. **Scan.** Stage only those source paths: `git -C "$SRC" add <paths>`.
   Run the repo's secret scanner when it has one. Always run this scan too:
   `git -C "$SRC" grep --cached -nEi 'token|secret|passw|api[_-]?key|PRIVATE KEY|glpat-|ghp_|github_pat_|xox[bp]-|AKIA' -- <paths>`
   Judge each match. Ignore plain prose, such as token counts.
   On a real secret, stop. Print the file, line, and match with the value
   replaced by `<redacted>`. Unstage the path and remove the secret from the source.
5. **Commit.** Load [commit](../commit/SKILL.md). Make one commit per concern.
6. **Pull and push.** Run `git -C "$SRC" pull` with no strategy flags, so the
   repo's configured strategy applies. Resolve clear conflicts. Stop and ask
   when the intended result is not clear. Then run `git -C "$SRC" push`.
7. **Check.** `chezmoi status <targets>` must print nothing, and
   `git -C "$SRC" status -sb` must show no ahead count.
   Report the pushed SHAs, the targets you left out, and why.
