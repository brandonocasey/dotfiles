# Global Git policy


- Git settings/remotes changes require explicit consent; reads do not. Incidental config from `git push -u`, `git branch -u`/`--unset-upstream`, branch deletion, or `git submodule update --init` needs none.
- Push only with authorization; default-branch push/merge needs my request or consent. Scoped local push consent applies. Fixing an MR/PR or linked thread authorizes `ship` and branch pushes. Invoked/implied ship or an existing branch MR/PR grants session-long task-branch push consent unless withdrawn.
- When work will push to an MR/PR with auto-merge on, pause it first and restore it after the last push, per [auto-merge-pause.md](auto-merge-pause.md).
- Approve/merge/change tickets only when asked for that MR/PR or ticket; move the task's own ticket forward when its MR/PR opens/merges.
- Commit finished task changes to the worktree branch before reporting done unless the workflow leaves commits to me. Leave no task dirt; preserve unrelated work.
- Resolve clear conflicts and continue; stop on ambiguous intent. Fetch before remote-state claims. Never suggest Git operations for unchanged files.
- Update MR/PR titles/descriptions only when asked, or while actively working on one you pushed or that is outdated.
