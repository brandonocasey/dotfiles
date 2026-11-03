function android --wraps android
    for argument in $argv
        switch $argument
            case --
                break
            case --no-metrics
                command android $argv
                return $status
        end
    end
    command android --no-metrics $argv
end
