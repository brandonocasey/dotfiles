## Code comments

- Comment only what the code cannot show: a reason, constraint, workaround, required behavior, or warning about code that deliberately breaks convention. Do not repeat what the code says or describe the change; put the bug, investigation, and ticket in the commit message. Remove redundant comments, and update or remove comments when the code changes. Each comment must make sense to someone who has not read the conversation.
- Put the comment at the method or block level, in 1–2 complete sentences
- State a real requirement with a capitalized RFC 2119 keyword (MUST, SHOULD, MAY, …) https://www.rfc-editor.org/rfc/rfc2119 : `Callers MUST hold the lock`. Lowercase in ordinary prose
- Link external context at the point of use: the source of copied code, the spec tricky logic implements, the issue a workaround works around, and `TODO` plus an issue reference for known-incomplete code
