---
description: Complete workflow from planning to implementation to review to commit
---

# Ship Command - Full Development Workflow

This command orchestrates the complete development cycle: plan → implement → review → fix → commit.

## Task Parameter

**Optional parameter**: Task description (e.g., `/ship add user authentication` or `/ship fix login bug`)
- If provided: Use the parameter as the task to implement
- If not provided: Ask the user what they want to build/fix

## Workflow Steps

### Step 1: Planning Phase

1. Use thinking tokens to analyze the task and break it down
2. Create a detailed plan following the plan.md format:
   - Each step should be 5 words or less
   - Use chain-of-thought reasoning
   - Consider dependencies and potential issues
3. Present the plan and iterate with the user until approved
4. Once plan is approved, proceed to implementation

### Step 2: Implementation Phase

1. Launch the implementation-agent to implement the plan:
   - Use the Task tool with subagent_type: "general-purpose"
   - Pass the approved plan as the prompt
   - The agent will follow instructions from .claude/agents/implementation-agent.md
   - Example Task call:
     ```
     Task(
       description: "Implement approved plan",
       subagent_type: "general-purpose",
       prompt: "You are the implementation-agent. [Full approved plan here]"
     )
     ```
   - Wait for the agent to complete and report results

### Step 3: Automated Review-Fix Loop

After implementation completes, run the automated review-fix loop (no user interaction):

1. **Launch code-reviewer agent**:
   ```
   Task(
     description: "Review code changes",
     subagent_type: "code-reviewer",
     prompt: "Review the current branch changes against the base branch. Report all issues found."
   )
   ```

2. **Review-Fix Loop** (max 5 iterations):
   - Parse review output for actionable issues
   - If no issues found, exit loop and proceed to commit
   - If issues found, launch fix-agent:
     ```
     Task(
       description: "Fix review issues",
       subagent_type: "fix-agent",
       prompt: "Fix the following issues from code review:\n\n[LIST OF ISSUES]\n\nMake minimal, targeted fixes. Run tests after fixes."
     )
     ```
   - After fixes, run code-reviewer agent again
   - Increment counter and continue

3. **Loop Exit Conditions**:
   - **Success**: No issues found → proceed to Step 4 (Commit)
   - **Max iterations reached**: Report remaining issues and ask user:
     - **Commit anyway**: Proceed despite remaining issues
     - **Continue fixing**: Allow more iterations (reset counter)
     - **Abort**: Stop workflow and report status

### Step 4: Commit Phase

1. After review loop completes successfully, use commit.md to create commits:
   - Run git status, git diff, git log in parallel
   - Stage all files and run pre-commit hooks
   - Fix any hook failures
   - Create atomic commits following conventional commit format
   - NO emojis, NO attribution
   - Run git status after commit to verify

## Important Notes

- **State tracking**: Keep track of current iteration count (1-5)
- **Error handling**: If any agent fails, report error and ask user how to proceed
- **Automated review**: Review-fix loop runs without user interaction until complete or max iterations reached
- **No auto-push**: DO NOT push to remote unless user explicitly requests
- **Agent isolation**: Each agent gets fresh context with relevant information
- **Main context responsibility**: Main context handles planning and commit - agents handle implementation, review, and fixes

## Example Usage

```
/ship add dark mode toggle to settings
/ship fix memory leak in data processor
/ship
```

## Workflow Summary

```
User Request → Plan (iterate with user) → Implement (agent) →
Automated Review-Fix Loop (max 5 cycles, no user interaction) → Commit
```
