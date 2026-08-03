---
name: todo
description: Add a concise todo entry to TODO.md at project root
---

Add a todo item to `TODO.md` at the project root.

1. If no description argument was provided, reply "Error: /todo requires a description. Usage: /todo <description>" and stop.
2. Find the project root (look for `.git`, `package.json`, or similar); fall back to the current directory.
3. Append the item to the end of `TODO.md` as `- <description>`, creating the file with a `# TODO` header if it doesn't exist.
4. Keep the entry to one line: clear, specific, and actionable. Tighten vague input into an actionable item without changing its meaning.
