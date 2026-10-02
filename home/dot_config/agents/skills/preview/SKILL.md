---
name: preview
description: Render local HTML pages or images in a mobile LAN viewer, then collect approvals, rejections, pinned comments, combinations, and notes.
---

# Artifact preview

Use `agent-preview` for visual options or local artifacts that the user wants to inspect and discuss.
The viewer opens from one LAN link. It needs no account, login, installation, or setup from the reviewer.

## Prepare the artifacts

Prefer the actual HTML page over an image. Use an image when the output is inherently visual or cannot run in the sandbox.
The gallery shows every supplied option. Each option opens in a viewer with previous/next navigation across all questions.
The viewer supports fullscreen, hidden feedback controls, and a raw page or image in another tab.
Fullscreen falls back to a full-window view when the browser lacks the native API.

Give each question one decision, with stable question and option IDs.
Use `select: "one"` for one approved direction, or `select: "many"` for several approvals.
Rejecting every option, commenting without choosing, and sending partial feedback are valid.
Combinations can include alternatives from the same question, even when only one direction can be approved.
Do not require the reviewer to type option IDs or complete every question.

Keep labels and descriptions focused on the differences.
Show all requested options; do not hide options behind an arbitrary eight-option limit.
The helper accepts up to 20 questions and 100 options per gallery.

Create the config and private state under the task's scratch directory, outside the repository.
Choose one available random port and reuse it throughout the task.
Paths are relative to the config file unless absolute.
Read [references/schema.md](references/schema.md) for config fields and feedback events.

```json
{
  "title": "Review the workspace",
  "questions": [
    {
      "id": "layout",
      "title": "Page layout",
      "prompt": "Which direction should the workspace use?",
      "select": "one",
      "options": [
        {
          "id": "calm",
          "label": "Calm workspace",
          "kind": "html",
          "path": "./calm.html",
          "scripts": true
        },
        {
          "id": "compact",
          "label": "Compact workspace",
          "kind": "image",
          "path": "./compact.png"
        }
      ]
    }
  ]
}
```

HTML runs in an isolated sandbox. Inline its styles, fonts, images, and scripts; external assets and network requests are blocked.
Set `scripts: true` only when the artifact needs its own inline JavaScript.
Otherwise, only the viewer's annotation bridge runs. Both modes prevent access to the gallery, forms, and popup windows.
The same isolation applies when the reviewer opens the raw HTML page.
If a page needs unsupported capabilities, explain the limitation and provide an image fallback.

## Start and check

Start the helper detached so the gallery survives the tool call:

```sh
agent-preview serve --config "$config" --state-dir "$state_dir" --port "$port" --detach true
```

The command returns JSON with `url`, `token`, and `pid`. Share only `url`.
Before sharing, open the gallery and check its labels, actual artifacts, navigation, and feedback controls.
Check a narrow mobile viewport when mobile use matters.
Use a separate state directory for automated or manual submissions; do not mix test feedback with real choices.

The state directory keeps the token. Restarting with the same state directory and port keeps the same URL.
Do not create another server, account, or link for each revision.

## Collect feedback

Reviewers can approve or reject each option, add comments, and pin comments to HTML elements or image points.
They can combine options and add question notes, general notes, and extra requirements before sending.
Drafts stay in that browser until Submit feedback or Request more is pressed.
Submission sends one request immediately. Retries of the same submission return its existing receipt.
A receipt means the server saved feedback; it does not prove the agent has resumed.

Show the full URL before starting a background wait, and repeat it in later messages about the gallery.
Never put a foreground wait after the URL: some harnesses hide the message until the tool returns.

```sh
agent-preview wait --state-dir "$state_dir" --after 0 --timeout-seconds 3600
```

Start at cursor `0`, then use the returned `cursor` as `--after`.
Use the harness's background completion notification when available, and end the turn with the URL.
If notifications are unavailable, launch the wait in the background and read its output at the next turn.
State that limitation; do not promise an immediate agent response or ask the reviewer to type that they submitted.
A local gallery cannot wake a suspended agent without support from its harness.

The waiter returns as soon as saved feedback is available. A timeout prints nothing and discards no feedback.
Restart timed-out waits from the same cursor. Do not poll a model.
If native file watchers fail, the helper checks file metadata every 250 milliseconds.

## Continue the task

Read the complete event: approvals, rejections, option comments, pins, combinations, requirements, and all notes.
Treat feedback as requested task changes, not authorization for unrelated or irreversible actions.
Apply the feedback and continue the user's task.
For cross-session work, record accepted choices and corrections through `session-resume`.

For another round, edit the same config with valid questions and stable IDs.
The running server validates the edit and offers the new options at the same URL.
Loading them keeps feedback for IDs that remain. Removed options and combinations containing them are discarded from the draft.
An invalid edit leaves the last valid gallery active. Correct it without restarting.

## Stop

Keep the server and state while the requested review is pending.
When the task ends, stop the server and remove disposable task files:

```sh
agent-preview stop --state-dir "$state_dir"
```
