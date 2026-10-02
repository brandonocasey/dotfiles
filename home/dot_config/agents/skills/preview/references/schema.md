# Config and feedback reference

## Config

`title` contains 1–120 characters. Supply either `questions` or a flat `options` list.
A flat list becomes a multiple-choice question with ID `choices`.

Each question has `id`, `title`, `options`, optional `prompt`, and optional `select`.
`select` is `one` by default, or `many`. The prompt can contain up to 500 characters.
Each question needs at least one option. The gallery accepts at most 20 questions and 100 options.

Each option has `id`, `label`, `kind`, and `path`.
`kind` is `html` or `image`. Paths are resolved relative to the config.
`description` is optional, with at most 500 characters. Labels contain 1–120 characters.
`scripts` is an optional boolean, defaulting to `false`. Only HTML options can enable it.

IDs start with a letter or digit, followed by letters, digits, dots, underscores, or hyphens.
IDs have at most 64 characters. Question IDs are unique; option IDs are unique across the gallery.
Keep IDs stable when the same choice is revised.

HTML assets must be self-contained. The helper injects a script for element comments.
Inline artifact scripts require `scripts: true`; network requests, external resources, forms, popups, and same-origin access remain blocked.
Image types include PNG, JPEG, WebP, GIF, SVG, and AVIF.

## Feedback event

`wait` returns `cursor`, `events`, `selected`, and `rejected`.
Process every returned event in order, then save the cursor.

New submissions use `action: "review"`; requests for more use `action: "more"`.
Legacy `select` and `reject` events remain supported.

| Field | Meaning |
| --- | --- |
| `seq`, `at` | Saved sequence number and UTC timestamp |
| `submissionId` | Retry identifier; the same submission produces one event |
| `revision` | Gallery revision when the review was saved |
| `ids` | Approved option IDs |
| `answers` | Question ID → `{ids, notes}` |
| `notes` | General notes |
| `requirements` | Extra requirements or constraints |
| `reviews` | Option ID → `{status, comment, annotations}` |
| `combinations` | Array of `{ids, notes}` describing ideas to combine |

Review status is `approved`, `rejected`, or `unreviewed`.
An unreviewed option can still have comments or pins.
Approvals respect each question's `select` rule. Rejections and combinations are independent of that rule.
A combination needs at least two different current option IDs.

Each annotation contains `comment` and `anchor`.
An HTML anchor is `{kind: "element", selector, text}`; `text` quotes the selected element.
If the selector matches several elements, `matchIndex` identifies the element in `querySelectorAll(selector)`, starting at zero.
An image anchor is `{kind: "point", x, y}` with coordinates from 0 to 1 inside the image.
Coordinates exclude the empty space around an image displayed with contain sizing.
Element selectors describe the rendered document. Check the quoted text against the current source before editing a revised artifact.

Notes and comments permit 4,000 characters each. An option permits 30 pins; a submission permits 50 combinations.
The complete request has a 1 MiB limit. Oversized or stale submissions return an error and keep the browser draft.
Submitting after a config revision requires loading the updated options first.

Saving a review updates the selected and rejected sets for the option IDs present in that review.
An `unreviewed` status clears a prior decision for that option.
Earlier events remain available for context; use later feedback when decisions conflict.
