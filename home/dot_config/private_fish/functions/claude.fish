# Datadog's ~400 tool names cost ~13k tokens per session, so block it unless claude-dd is used.
function claude --wraps claude
    command claude --settings '{"deniedMcpServers":[{"serverName":"claude.ai Datadog"}]}' $argv
end
