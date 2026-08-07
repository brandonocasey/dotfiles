---
name: write-docs
description: >
  Diátaxis rules for documentation. Load before creating, editing, or restructuring
  any docs page — README sections, docs/ trees, tutorials, how-tos, reference pages,
  or explanations.
---

- Structure docs by [Diátaxis](https://diataxis.fr/): every page serves exactly one
  mode — tutorial (learning by doing), how-to (working task), reference (working
  facts), explanation (learning background). Map an existing repo's folders onto
  those modes; in a new docs tree, name the folders after them
- Unsure where content belongs? Ask: doing or thinking, learning or working.
  Doing+learning = tutorial, doing+working = how-to, thinking+working = reference,
  thinking+learning = explanation
- When a section drifts into another mode, move it to the owning page and leave a
  one-line link both ways — never duplicate content across pages
- Improve docs one page, one flaw at a time — never plan a restructure; good
  structure emerges from small fixes
- Docs must be useful at every state: no "coming soon" stubs, and don't hold back a
  page because it isn't finished
