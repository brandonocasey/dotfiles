Perform a pull request style review of the code using a command like: `git diff $(git merge-base --fork-point main dev)..dev` where `main` is the main branch for this repository and `dev` is the current branch.

IMPORTANT: Do NOT use GitHub CLI (gh) or any other CLI tools to view pull requests. Only review local git changes.

Then, verify tests and linting:
- Check for and run any test commands (e.g., `npm test`, `pytest`, `cargo test`, etc.)
- Check for and run any linting commands (e.g., `npm run lint`, `eslint`, `pylint`, `cargo clippy`, etc.)
- Note: Look at package.json, Makefile, or other config files to determine the correct commands

Then analyze the changes and provide a comprehensive code review covering:

1. **Maintainability**: Are the changes easy to understand and modify in the future? Is there adequate separation of concerns?

2. **Consistency**: Do the changes follow existing code patterns, naming conventions, and project standards (check CLAUDE.md for project-specific conventions)?

3. **Simplicity**: Can the implementation be simplified? Are there unnecessary abstractions or overly complex logic?

4. **Possible Issues**: Identify potential bugs, edge cases, performance concerns, type safety issues, or security vulnerabilities.

5. **Duplication**: Are there duplicate implementations or repeated code that could be refactored into shared utilities?

6. **Tests and Linting**: Report the status of tests and linting. If tests fail or linting errors are found, include them as critical issues.

For each finding, provide:
- The file location (use `file_path:line_number` format)
- A clear explanation of the issue
- A specific, actionable suggestion for improvement

Prioritize findings by severity (critical issues first, then suggestions for improvement).

If the changes look good overall, confirm this and highlight any particularly well-implemented aspects.
