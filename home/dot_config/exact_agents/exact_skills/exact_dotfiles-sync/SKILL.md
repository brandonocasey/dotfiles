---
disable-model-invocation: true
name: dotfiles-sync
description: "Explicit-only: sync changed chezmoi targets to sources, scan for secrets, commit, and push."
---

Optional argument: target paths. Without one, use the targets this session changed.

Invoking this skill is the consent to commit and push the current branch of the
chezmoi source repo, for this run only. It gives no standing consent. No rule
runs it automatically. Force-push stays forbidden.

Resolve the repo once: `git -C "$(chezmoi source-path)" rev-parse --show-toplevel`.
Shell variables do not persist between tool calls, so write that literal path
wherever `<src>` appears below.

1. **Scope.** Use the named targets, or the targets this session changed.
   Never include `~/.ssh`, `*credentials*`, `*.pem`, `*.key`, token files, or
   paths in `.chezmoiignore`. Report each excluded path by name only. Never
   print its contents. Never restore a path that a source commit removed.
2. **Status.** Run `chezmoi status <targets>`. Report listed targets that this
   session did not edit. Do not include them unless the user names them.
   Agent config directories are exact: applying removes files absent from their sources.
   For requested deletions, remove the source entry; deleting only the target restores it.
   Keep `synced/` ignored and preserve GitHub CLI ownership of `frontend-design/`.
3. **Copy.** For each managed target, show `diff -u "$(chezmoi source-path <target>)" <target>`.
   For a new target, show `diff -u /dev/null <target>`.
   - Plain source: copy the target to that source path.
   - Source name starts with `symlink_`, `modify_`, `run_`, `create_`, or
     `encrypted_`, or ends in `.tmpl`: do not copy. Edit the source by hand
     and show the diff. For `symlink_`, sync the link target instead.
   - New file: run `chezmoi source-path <parent-directory>`. Add the file with
     the prefixes its siblings use, such as `private_` or `executable_`.
     Prefix every new owned skill source directory with `exact_`, including nested directories.
   - Never run `chezmoi add`, `re-add`, `edit`, `merge`, or `update`. With
     `autoCommit` or `autoPush` on, they commit or push on their own.
4. **Scan.** Stage only those source paths: `git -C <src> add <paths>`.
   Run the repo's secret scanner when it has one. Always run this scan too:
   `git -C <src> grep --cached -nEi 'token|secret|passw|api[_-]?key|PRIVATE KEY|glpat-|ghp_|github_pat_|xox[bp]-|AKIA' -- <paths>`
   Judge each match. Ignore plain prose, such as token counts.
   On a real secret, stop. Print the file, line, and match with the value
   replaced by `<redacted>`. Unstage the path and remove the secret from the source.
5. **Commit.** Load [commit](../commit/SKILL.md). Make one commit per concern.
6. **Pull and push.** Run `git -C <src> pull` with no strategy flags, so the
   repo's configured strategy applies. Resolve clear conflicts. Stop and ask
   when the intended result is not clear. Then run `git -C <src> push`.
7. **Check.** `chezmoi status <targets>` must print nothing, and
   `git -C <src> status -sb` must show no ahead count.
   Report the pushed SHAs, the targets you left out, and why.
