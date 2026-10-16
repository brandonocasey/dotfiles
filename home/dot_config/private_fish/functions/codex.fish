function codex --wraps codex
    for argument in $argv
        switch $argument
            case --
                break
            case --no-daemon
                command codex $argv
                return $status
        end
    end
    command codex --no-daemon $argv
end
