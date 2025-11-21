# Automated Review Loop

This command performs an automated review-fix loop until all issues are resolved.

## Workflow

1. **Launch code-reviewer agent** to review changes
2. **If issues found**: Launch fix-agent to address them
3. **Repeat** until no issues remain or max iterations reached
4. **Report final status** to user

## Execution Steps

### Step 1: Initial Review

Launch the code-reviewer agent using the Task tool:
```
Task(
  description: "Review code changes",
  subagent_type: "code-reviewer",
  prompt: "Review the current branch changes against the base branch. Report all issues found."
)
```

### Step 2: Review-Fix Loop

**Loop configuration:**
- Maximum iterations: 5
- Exit conditions: No issues found OR max iterations reached

**For each iteration:**

1. Parse the review output for actionable issues
2. If no issues found, exit loop with success
3. If issues found, launch fix-agent:
   ```
   Task(
     description: "Fix review issues",
     subagent_type: "fix-agent",
     prompt: "Fix the following issues from code review:\n\n[LIST OF ISSUES]\n\nMake minimal, targeted fixes. Run tests after fixes."
   )
   ```
4. After fixes complete, launch code-reviewer agent again
5. Increment iteration counter and continue loop

### Step 3: Final Report

After loop exits, report to user:
- **Success**: "No issues found. Changes are ready to merge."
- **Max iterations reached**: List remaining unresolved issues and ask user how to proceed

## Important Notes

- **No user interaction** during the review-fix loop
- **Track iteration count** and report progress
- **Preserve all changes** made by fix-agent
- Run tests and linting as part of each review cycle
- If fix-agent introduces new issues, they will be caught in the next review cycle
