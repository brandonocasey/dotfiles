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

### Step 3: Review Phase

1. After implementation completes, perform a code review following review.md:
   - Run git diff to see all changes
   - Check for bugs, security issues, performance problems
   - Run tests and linting
   - Verify the plan was fully implemented
   - Keep review brief and focused on actionable items

2. Present review results to the user with three options:
   - **Accept**: Changes are good, proceed to commit
   - **Fix**: Launch fix agent to address review feedback
   - **Iterate**: Discuss and manually adjust

### Step 4: Fix Phase (if needed)

1. If user chooses "Fix", launch the fix-agent to address review feedback:
   - Use the Task tool with subagent_type: "general-purpose"
   - Pass the review feedback as the prompt
   - The agent will follow instructions from .claude/agents/fix-agent.md
   - Example Task call:
     ```
     Task(
       description: "Fix review feedback",
       subagent_type: "general-purpose",
       prompt: "You are the fix-agent. [Full review feedback here]"
     )
     ```
   - Wait for the agent to complete and report results

2. After fixes complete, return to Step 3 (Review Phase)

3. Track iteration count:
   - Maximum 10 review→fix cycles
   - If 10 iterations reached, ask user:
     - **Commit anyway**: Proceed with commit despite remaining issues
     - **Continue fixing**: Allow more iterations (reset counter)
     - **Abort**: Stop the workflow and report status

### Step 5: Commit Phase

1. When user accepts the changes, use commit.md to create commits:
   - Run git status, git diff, git log in parallel
   - Stage all files and run pre-commit hooks
   - Fix any hook failures
   - Create atomic commits following conventional commit format
   - NO emojis, NO attribution
   - Run git status after commit to verify

## Important Notes

- **State tracking**: Keep track of current iteration count (1-10)
- **Error handling**: If any agent fails, report error and ask user how to proceed
- **User control**: Always show review results and get user approval before proceeding
- **No auto-push**: DO NOT push to remote unless user explicitly requests
- **Agent isolation**: Each agent gets fresh context with relevant information
- **Main context responsibility**: Main context handles planning, review, and commit - agents handle implementation and fixes

## Example Usage

```
/ship add dark mode toggle to settings
/ship fix memory leak in data processor
/ship
```

## Workflow Summary

```
User Request → Plan (iterate with user) → Implement (agent) → Review (main) →
[Accept → Commit] OR [Fix (agent) → Review (main) → ...] (max 10 cycles)
```
