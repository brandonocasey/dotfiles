# One ssh-agent per host on a fixed socket, so every shell (local, SSH, tmux)
# shares the same keys. A stale inherited SSH_AUTH_SOCK can't spawn orphan
# agents because the path never changes. A forwarded agent (ssh -A) that holds
# keys is kept as-is.
function __ssh_agent_use_fixed_socket
    if test -n "$SSH_CONNECTION" -a -n "$SSH_AUTH_SOCK"
        ssh-add -l >/dev/null 2>&1
        and return
    end

    set -l sock $HOME/.ssh/agent.sock
    set -gx SSH_AUTH_SOCK $sock
    set -e SSH_AGENT_PID
    ssh-add -l >/dev/null 2>&1
    if test $status -eq 2
        rm -f $sock
        ssh-agent -a $sock >/dev/null
    end
end

__ssh_agent_use_fixed_socket
functions -e __ssh_agent_use_fixed_socket
