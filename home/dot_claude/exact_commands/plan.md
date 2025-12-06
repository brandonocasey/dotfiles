# Plan Command

## Critical Workflow Requirement

MANDATORY PLANNING STEP: Before executing ANY tool (Read, Write, Edit, Bash, Grep, Glob, WebSearch, etc.), you MUST:

1. FIRST: Use thinking tokens to analyze the request and break it down
2. SECOND: Use ExitPlanMode tool to present your plan
3. WAIT: For explicit user approval before proceeding  
4. ONLY THEN: Execute the planned actions

## Thinking Tokens Usage

Before creating your plan, use thinking tokens to:
- Analyze what the user is asking for
- Break down the task into logical steps
- Consider potential issues or dependencies
- Ensure each step is 5 words or less
- Think through the complete workflow

## Zero Exceptions Policy

This applies to EVERY INDIVIDUAL USER REQUEST involving tool usage, regardless of:
- Complexity (simple or complex)
- Tool type (file operations, searches, web requests, etc.)
- User urgency or apparent simplicity
- Whether you previously got approval in this conversation

## Critical Rules

- APPROVAL DOES NOT CARRY OVER BETWEEN USER INSTRUCTIONS
- Each new user message requiring tools = new planning step required
- Previous approvals are invalid for new requests
- You must reset and plan for each individual user instruction

## Enforcement

If you execute ANY tool without first using ExitPlanMode for the current user instruction, you have violated this requirement. Always plan first, execute second.

## Workflow for Each Request

Think → Plan → User Approval → Execute (NEVER: Execute → Plan → Think)

## Chain of Draft Prompting

Plans must be broken down step by step with each step being no more than 5 words.

### Example Plan Format:

**Thinking Process:**
<thinking>
User wants me to update a configuration file. I need to:
- Understand what changes are needed
- Read the current file to see structure
- Make the specific edits requested
- Verify the changes work correctly
- Ensure code quality standards are met
</thinking>

**Plan Steps:**
1. Read target file contents
2. Search for specific pattern
3. Edit file with changes
4. Run tests to verify
5. Check lint and formatting