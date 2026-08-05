function copy --description "Copy a file (or stdin) to the local clipboard via OSC 52; works over ssh"
    if test (count $argv) -gt 0
        set -f data (base64 < $argv[1] | tr -d '\n')
    else
        # Command substitutions don't see the function's piped stdin; read -z does.
        read --null --function input
        set -f data (printf '%s' $input | base64 | tr -d '\n')
    end
    if set -q TMUX
        # tmux needs the sequence wrapped in a passthrough escape.
        printf '\ePtmux;\e\e]52;c;%s\a\e\\' $data
    else
        printf '\e]52;c;%s\a' $data
    end
end
