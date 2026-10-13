# Visual choices

Use this workflow when [preview](../SKILL.md) calls for choices.
Return to preview for live previews and requested screenshots.

## Ask one decision per question

Split the choices into separate questions, one decision each. Do not ask the user to type option codes into notes.

- Use `select: "one"` when only one answer can win, and `select: "many"` when several can.
- Give each question a `prompt` that says what to decide.
- Keep each option's `description` to what differs from the other options.
- Show faithful HTML or existing visual assets. Use screenshots only when requested,
  captured from the real app at the size the user cares about.
- Show 3–4 options per question, as `preview` requires. Offer more through a later round.

Per [task-resources.md](../../host-preflight/references/task-resources.md), put the
config and disposable visual assets in the task scratch directory. Keep private gallery
state (access token and feedback) under the external XDG cache scratch directory in a
separate `preview-state/` directory, and never serve it as static files. Reuse one random
port for this gallery. Write a JSON config with stable question and option IDs:

```json
{
  "title": "Pick the header icons",
  "questions": [
    {
      "id": "icon-size",
      "title": "Icon size",
      "prompt": "Which size should every header icon use?",
      "select": "one",
      "options": [
        { "id": "size-20", "label": "20 px", "kind": "image", "path": "./size-20.png", "description": "Matches the dock." },
        { "id": "size-24", "label": "24 px", "kind": "html", "path": "./size-24.html" }
      ]
    }
  ]
}
```

Paths are relative to the config file unless absolute. `kind` is `image` or `html`. IDs contain letters, digits, dots, underscores, or hyphens. Option IDs are unique across all questions and stay stable across revisions.

HTML options render in a sandbox without scripts or network access. Inline images as `data:` URIs.

## Start the server detached

Start the server detached, so harness time limits on background commands cannot stop it:

```sh
agent-preview serve --config <config> --state-dir <state-dir> --port <port> --detach true
```

The command prints JSON with `url`, `token`, and `pid`, then returns. Share only that `url`. Check that the URL, the steps, and the exact option IDs render before sharing it. The token lives in the state directory, so a restart with the same state directory keeps the same URL. If the server stops, start it again the same way and share the same URL.

## Wait in the background

Text written before a blocking tool call can stay hidden until the turn ends, so never run the
wait in the foreground. Put the full gallery URL on its own line in a chat message (repeat it
in every later message about the gallery), start the wait in the background (Claude Code:
`run_in_background`), and end the turn with the URL on the line before `Next:`. The exit
notification starts your next turn; if the harness gives none, read the wait's output at the
start of each later turn.

Start with cursor `0`, then pass the returned `cursor` as `--after`:

```sh
agent-preview wait --state-dir <state-dir> --after 0 --timeout-seconds 3600
```

The call returns as soon as a submission arrives. A timeout prints nothing and does not discard
feedback: run it again with the same cursor, in the background, and show the URL again. Do not
poll a model or ask the user to type that they submitted.

## Read the answers

Each event carries `answers`, keyed by question ID, with the chosen option `ids` and that question's `notes`. The top-level `notes` holds the general notes from the Submit section. An event's `action` is `select` for submitted answers, or `more` when the user asks for more options.

For a `more` response, or for the next round, update the same config file with valid questions and stable IDs. The running server validates the edit and keeps the same URL. Picks whose IDs remain are kept. An invalid config edit leaves the last valid gallery active; correct the file without restarting the server.

Apply selections, notes, and requests for more options to the active task. When the choice must survive a resumed session, use `agent-task update --correction` to record the option IDs, feedback, and resulting correction. Continue the requested work after each response.

## Stop

Stop the gallery server per `task-resources.md` retention rules:

```sh
agent-preview stop --state-dir <state-dir>
```

Keep private state until the task finishes and the user has finished with the
URL. Save any decisions needed across sessions through `session-resume` before
removing disposable state. Stop background waits before removing their files.
