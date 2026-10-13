---
name: dotfiles-sync
description: "Sync changed chezmoi targets to sources, scan for secrets, commit, push, and apply. Use when the user asks to commit or push chezmoi or dotfiles changes."
---

Optional argument: target paths. Without one, use the targets this session changed.

A user request to commit or push dotfiles is the consent to commit and push the
current branch of the chezmoi source repo, for this run only. It gives no standing
consent. Never run it without that request. Force-push stays forbidden.

Resolve the repo once: `cd "$(chezmoi source-path)" && git rev-parse --show-toplevel`.
Shell variables do not persist between tool calls, so write that literal path
wherever `<src>` appears below.

Run each Git command below as `cd <src> && git ...`: one Git command per call,
with no pipes, `;`, or variable assignments. Only plain `git` commands run
outside the sandbox, which signing and SSH pushes need; `git -C` stays inside.

1. **Scope.** Use the named targets, or the targets this session changed.
   Never include `*credentials*`, `*.pem`, `*.key`, token files, or paths in
   `.chezmoiignore`. Never include any `~/.ssh` path except `~/.ssh/config`.
   Include that file only when the user names it exactly; `~/.ssh`, a glob, or
   "ssh stuff" does not name it. After step 3 shows its diff, stop until the user
   says yes; show it again if it changes before staging. Step 4 misses hosts
   and users, and the repo is public.
   Report each excluded path by name only. Never print its contents. Never
   restore a path that a source commit removed.
2. **Status.** Run `chezmoi status <targets>`. Report listed targets that this
   session did not edit. Do not include them unless the user names them.
   Agent config directories are exact: applying removes files absent from their sources.
   For requested deletions, remove the source entry; deleting only the target restores it.
   Keep `synced/` ignored and never add `frontend-design/` to the source;
   `gh skill` installs it.
3. **Copy.** For each managed target, show `diff -u "$(chezmoi source-path <target>)" <target>`.
   For a new target, show `diff -u /dev/null <target>`. Skip the copy for a target
   whose source this session edited directly; step 7 applies it.
   - Plain source: copy the target to that source path.
   - Source name starts with `symlink_`, `modify_`, `run_`, `create_`, or
     `encrypted_`, or ends in `.tmpl`: do not copy. Edit the source by hand
     and show the diff. Edit any `.chezmoitemplates/` partial it renders. For `symlink_`, sync the link target instead.
   - New file: run `chezmoi source-path <parent-directory>`. Add the file with
     the prefixes its siblings use, such as `private_` or `executable_`.
     Prefix every new owned skill source directory with `exact_`, including nested directories.
   - Never run `chezmoi add`, `re-add`, `edit`, `merge`, or `update`. With
     `autoCommit` or `autoPush` on, they commit or push on their own.
4. **Scan.** Stage only those source paths: `git add <paths>`.
   Run the repo's secret scanner when it has one. Always run this scan too:
   `git grep --cached -nEi 'token|secret|passw|api[_-]?key|PRIVATE KEY|glpat-|ghp_|github_pat_|xox[bp]-|AKIA' -- <paths>`
   Judge each match. Ignore plain prose, such as token counts.
   On a real secret, stop. Print the file, line, and match with the value
   replaced by `<redacted>`. Unstage the path and remove the secret from the source.
5. **Commit.** Load [commit](../commit/SKILL.md). Make one commit per concern.
6. **Pull and push.** Run `git pull` with no strategy flags, so the
   repo's configured strategy applies. Resolve clear conflicts. Stop and ask
   when the intended result is not clear. Then run `git push`.
7. **Apply.** Run `chezmoi apply <targets>`, so the pushed sources take effect.
   Apply only the scoped targets; a wider apply overwrites unsynced target edits.
   When the sandbox reports `operation not permitted`, rerun it outside the sandbox.
8. **Check.** `chezmoi status <targets>` must print nothing, and
   `git status -sb` must show no ahead count.
   Report the pushed SHAs, the targets you left out, and why.
