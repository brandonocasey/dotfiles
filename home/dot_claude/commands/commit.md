---
description: Create a git commit without emojis or Claude attribution
---

Create a git commit by following these steps:

**Optional parameter**: If the user provides a target (e.g., `/commit auth.ts` or `/commit authentication changes`), commit ONLY that specific file or logical chunk. Otherwise, commit all unstaged/un-added files organized into logical chunks.

1. Run these git commands in parallel:
   - git status to see all untracked files
   - git diff to see both staged and unstaged changes
   - git log --oneline -10 to see recent commit message style
   - git rev-parse --abbrev-ref HEAD to get current branch name
   - git merge-base HEAD main (or origin/main) to find fork point from main branch

2. Determine commit scope to analyze:
   - **If on main branch** (or default branch): analyze only the most recent commit (HEAD)
   - **If on feature branch**: find the fork point and analyze ALL commits since diverging from main
     - Use: `git log --format='%H|%an <%ae>|%s' <fork-point>..HEAD` to get all commits since fork
     - This gives you the full context of work done on this branch

3. Decide whether to amend or create new commit:
   - **Amend the most recent commit if ALL of these conditions are true**:
     - The most recent commit author matches you (Claude)
     - The current changes are directly related to ANY commit since the fork point (same type, scope, and purpose)
     - The most recent commit has NOT been pushed to remote (check with `git log @{u}..HEAD` or `git cherry -v`)
     - The changes would logically belong in the same atomic commit as the most recent commit
     - No other developer has committed since the commit you'd be amending
   - **Create a new commit if ANY of these conditions are true**:
     - The most recent commit author is NOT you
     - The changes serve a different purpose than all commits since the fork point
     - The most recent commit has been pushed to remote
     - The changes represent a distinct logical unit of work
     - There are commits by other authors between the fork point and HEAD
   - When in doubt, prefer creating a new commit over amending

4. Analyze all changes (both staged and unstaged) and draft commit messages:
   - Consider the context of ALL commits since the fork point to understand the branch's purpose
   - Do not commit files that likely contain secrets (.env, credentials.json, etc.)
   - Follow the "Best Practices for Commits" section below
   - DO NOT use any emojis in the commit message
   - DO NOT add any attribution or co-author information
   - If amending, keep the existing commit message unless the changes significantly alter the commit's purpose

5. Stage files and run pre-commit hooks to fix issues:
   - **If target parameter provided**: Stage ONLY the specified file(s) or files matching the logical chunk
   - **If no parameter provided**: Stage ALL relevant files at once
   - Run pre-commit hooks (lefthook run pre-commit, .husky/pre-commit, or .git/hooks/pre-commit)
   - If hooks fail with errors, FIX the issues (type errors, lint violations, etc.) - do not ignore them
   - Stage any hook-generated changes (formatting, auto-fixes) and verify hooks pass
   - Once hooks pass, do NOT run them again

6. Commit with --no-verify:
   - **If amending**: Use `git commit --amend --no-verify` to amend the previous commit
     - Keep the original commit message with `-C HEAD` unless changes warrant a message update
     - If updating message, use the same format as the original commit
   - **If creating new commit**:
     - **If a target parameter was provided**: commit ONLY the specified file or logical chunk (single commit)
     - **If no parameter provided**: commit all staged files, splitting into multiple logical commits when appropriate (see "Guidelines for Splitting Commits")
   - Use --no-verify since hooks already passed
   - Run git status after to verify the intended files are committed

## Best Practices for Commits

- **Atomic commits**: Each commit should contain related changes that serve a single purpose
- **Conventional commit format**: Use the format `<type>(<scope>): <description>` or `<type>: <description>`
  - **Type** (required): feat, fix, docs, visual, refactor, perf, test, chore, ci, revert, ops
  - **Scope** (optional): Contextual information (e.g., `feat(api):` or `fix(auth):` or `visual(header):`)
  - **Breaking changes**: Add exclamation mark before colon, like feat! or feat(api)!
- **Present tense, imperative mood**: "add feature" not "added" or "adds"
- **Message quality**:
  - Focus on "why" not "what" - explain why the change was necessary
  - Avoid vague messages: "fixed bug", "changed style", "oops"
  - Eliminate filler: "though", "maybe", "I think", "kind of"
- **Format**: Lowercase start, no period at end, subject under 50 chars (max 72)
- **Body**: Add a brief, concise description after the subject only if it adds meaningful context. Skip if the subject is self-explanatory.

## Guidelines for Splitting Commits

Split commits when changes involve different concerns, types, or file patterns.

Examples:
- feat(api): add auth endpoints + docs: update API guide
- feat(ui): add modal component + refactor(ui): extract button styles

## Commit Message Examples

Good:
- feat(auth): add OAuth2 provider support
- fix: add margin to nav items to prevent logo overlap
- docs: update API documentation with new endpoints
- refactor: simplify error handling logic
- perf: optimize database query performance
- feat(api)!: remove deprecated status endpoint

Bad:
- "fixed bug" / "changed style" / "oops" (too vague, no context)

## Important Notes

- DO NOT push to the remote repository unless the user explicitly asks
- DO NOT use the -i flag with git commands (not supported)
- DO NOT create empty commits if there are no changes
- Use heredoc format for commit messages like this example:

```
git commit --no-verify -m "$(cat <<'EOF'
type: commit message description here
EOF
)"
```
