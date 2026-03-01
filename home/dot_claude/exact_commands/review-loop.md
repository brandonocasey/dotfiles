# Review-Fix Loop
Automated review-fix cycles (max 5) until resolution.

## Workflow
1. **Review**: `Task(subagent_type: "code-reviewer", prompt: "Review branch vs base. Report all issues.")`
2. **Resolve**:
   - No issues: Exit (Success).
   - Issues: `Task(subagent_type: "fix-agent", prompt: "Fix review issues: [ISSUES]. Apply minimal fixes and run tests.")`
3. **Report & Loop**: Report status after each iteration, then repeat from Step 1.

## Rules
- **Autonomous**: No user interaction during loop.
- **Status Updates**: Report iteration count and fix summary after each cycle.
- **Verification**: Include tests/linting; preserve all fixes.
- **Final Report**: Report "Success" or list remaining issues if max iterations reached.
