# Stage part of a file

Use when one file spans multiple logical changes. Keep each logical change,
including its supporting tests and docs, together.

Write a patch under the task scratch location from AGENTS.md:
`git diff -U0 -- <file> > <patch>`. Delete hunks belonging to the other change,
then stage it with `git apply --cached --unidiff-zero <patch>`.
Check `git diff --staged` before committing. Repeat for the remaining change.
The `commit` skill's **Constraints** ban `git add -p`/`-i` and require removing the patch after the commit.
