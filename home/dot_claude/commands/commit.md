---
description: Create a git commit without emojis or Claude attribution
---

Create a git commit by following these steps:

**Optional parameter**: If the user provides a target (e.g., `/commit auth.ts` or `/commit authentication changes`), commit ONLY that specific file or logical chunk. Otherwise, commit all unstaged/un-added files organized into logical chunks.

1. Run these git commands in parallel:
   - git status to see all untracked files
   - git diff to see both staged and unstaged changes
   - git log --oneline -10 to see recent commit message style

2. Analyze all changes (both staged and unstaged) and draft commit messages:
   - Do not commit files that likely contain secrets (.env, credentials.json, etc.)
   - Follow the "Best Practices for Commits" section below
   - DO NOT use any emojis in the commit message
   - DO NOT add any attribution or co-author information

3. Stage files and run pre-commit hooks to fix issues:
   - **If target parameter provided**: Stage ONLY the specified file(s) or files matching the logical chunk
   - **If no parameter provided**: Stage ALL relevant files at once
   - Run pre-commit hooks (lefthook run pre-commit, .husky/pre-commit, or .git/hooks/pre-commit)
   - If hooks fail with errors, FIX the issues (type errors, lint violations, etc.) - do not ignore them
   - Stage any hook-generated changes (formatting, auto-fixes) and verify hooks pass
   - Once hooks pass, do NOT run them again

4. Commit with --no-verify:
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
