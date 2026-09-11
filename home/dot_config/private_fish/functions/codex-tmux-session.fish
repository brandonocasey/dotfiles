function codex-tmux-session --description "Sync the current tmux session with a Codex session title"
    if not set -q TMUX; or not set -q TMUX_PANE; or not command -q jq; or not command -q tmux
        return 0
    end

    set -l hook_input (cat | string collect)
    set -l codex_session_id (string match -r '"session_id"\s*:\s*"([^"]+)"' -- "$hook_input")[2]
    if test -z "$codex_session_id"
        return 0
    end

    set -l codex_home "$CODEX_HOME"
    if test -z "$codex_home"
        set codex_home "$HOME/.codex"
    end

    set -l index_file "$codex_home/session_index.jsonl"
    if not test -r "$index_file"
        return 0
    end

    for attempt in (seq 1 10)
        set -l thread_name (
            jq -sr --arg id "$codex_session_id" '
                map(select(.id == $id)) |
                if length > 0 then .[-1].thread_name // empty else empty end
            ' "$index_file" 2>/dev/null
        )
        if test -n "$thread_name"
            set -l tmux_session_id (tmux display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null)
            if test -n "$tmux_session_id"
                tmux rename-session -t "$tmux_session_id" "$thread_name" 2>/dev/null
            end
            return 0
        end
        sleep 0.1
    end
end
