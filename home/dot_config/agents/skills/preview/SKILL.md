---
name: preview
description: Show requested visual options in a LAN gallery and wait for selection, rejection, notes, or a request for more options.
---

# Visual choice preview

Use `agent-preview` when the user requests visual choices that benefit from a browser gallery.

Create a private state directory for the current task. Keep it outside the repository. Choose one available random port and reuse it for this task. Write a JSON config with stable option IDs:

```json
{
  "title": "Choose an icon",
  "options": [
    {
      "id": "round-blue",
      "label": "Round blue icon",
      "kind": "image",
      "path": "./round-blue.png",
      "description": "Compact mark on a blue field."
    },
    {
      "id": "wide-layout",
      "label": "Wide layout",
      "kind": "html",
      "path": "./wide-layout.html"
    }
  ]
}
```

Paths are relative to the config file unless absolute. `kind` is `image` or `html`. IDs contain letters, digits, dots, underscores, or hyphens and remain stable across revisions.

Start the server on all interfaces:

```sh
agent-preview serve --config "$config" --state-dir "$state_dir" --port "$port"
```

Read the token from the command output. Share only `http://<lan-ip>:<port>/?token=<token>`. Validate that the URL, gallery, and exact option IDs render before sharing it.

Keep the agent turn active and wait for browser feedback. Start with cursor `0`, then pass the returned `cursor` as `--after`:

```sh
agent-preview wait --state-dir "$state_dir" --after 0 --timeout-seconds 900
```

The wait returns JSON after a new submission. A timeout prints nothing and does not discard feedback. Run it again with the same cursor. Do not poll a model or ask the user to type that they submitted.

For a `more` response, update the same config file with valid options and stable IDs. The running server validates the edit and keeps the same URL and token. The open gallery shows a **New options available** button. The button reloads the options while preserving notes and selections whose IDs remain present. An invalid config edit leaves the last valid gallery active; correct the file without restarting the server.

Apply selections, rejections, notes, and requests for more options to the active task. When the choice must survive a resumed session, use `agent-task update --correction` to record the option IDs, feedback, and resulting correction. Continue the requested work after each response.

Stop the server when the task ends. Keep the private state until the task finishes so accepted and rejected IDs remain available.
