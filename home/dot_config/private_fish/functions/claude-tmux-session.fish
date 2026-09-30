function claude-tmux-session --description "Sync the current tmux session with a Claude Code session title"
    if not set -q TMUX; or not set -q TMUX_PANE; or not command -q jq; or not command -q tmux
        return 0
    end

    set -l hook_input (cat | string collect)
    set -l transcript (printf '%s' "$hook_input" | jq -r '.transcript_path // empty' 2>/dev/null)
    if test -z "$transcript"
        return 0
    end

    # The title entry can land just after the hook fires, so retry briefly.
    for attempt in (seq 1 10)
        if test -r "$transcript"
            # /rename writes custom-title; it wins over the generated ai-title.
            set -l title (
                jq -rn '
                    reduce (inputs | select(.type == "custom-title" or .type == "ai-title")) as $e
                        ({}; .[$e.type] = ($e.customTitle // $e.aiTitle)) |
                    .["custom-title"] // .["ai-title"] // empty
                ' "$transcript" 2>/dev/null
            )
            if test -n "$title"
                set -l tmux_session_id (tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null)
                if test -n "$tmux_session_id"
                    tmux rename-session -t "$tmux_session_id" "$title" 2>/dev/null
                end
                return 0
            end
        end
        sleep 0.1
    end
end
