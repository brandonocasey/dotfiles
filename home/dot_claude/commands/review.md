Review all currently unstaged or untracked file changes in the repository.

First, run `git status` and `git diff` to see all unstaged and untracked changes.

Then analyze the changes and provide a comprehensive code review covering:

1. **Maintainability**: Are the changes easy to understand and modify in the future? Is there adequate separation of concerns?

2. **Consistency**: Do the changes follow existing code patterns, naming conventions, and project standards (check CLAUDE.md for project-specific conventions)?

3. **Simplicity**: Can the implementation be simplified? Are there unnecessary abstractions or overly complex logic?

4. **Possible Issues**: Identify potential bugs, edge cases, performance concerns, type safety issues, or security vulnerabilities.

5. **Duplication**: Are there duplicate implementations or repeated code that could be refactored into shared utilities?

For each finding, provide:
- The file location (use `file_path:line_number` format)
- A clear explanation of the issue
- A specific, actionable suggestion for improvement

Prioritize findings by severity (critical issues first, then suggestions for improvement).

If the changes look good overall, confirm this and highlight any particularly well-implemented aspects.
