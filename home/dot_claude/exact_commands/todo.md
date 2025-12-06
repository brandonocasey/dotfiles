---
description: Add a concise todo entry to TODO.md at project root
---

Add a concise, actionable todo item to the TODO.md file at the root of the project.

IMPORTANT: This command REQUIRES a parameter describing the todo item to add.
If no parameter is provided, respond with: "Error: /todo requires a description. Usage: /todo <description>"

Instructions:
1. Check if a prompt argument was provided - if not, show the error message above and stop
2. Find the project root by looking for common indicators (.git directory, package.json, etc.)
3. Read the existing TODO.md file if it exists, or create a new one
4. Add the new todo item in a clean, organized format
5. Use the provided prompt argument to describe the todo item
6. Format the todo as a simple dash list item: `- <description>`
7. Add the todo at the end of the file
8. If the file is empty or new, create a "# TODO" header first
9. Keep entries concise and actionable

The todo item should be clear, specific, and actionable.
