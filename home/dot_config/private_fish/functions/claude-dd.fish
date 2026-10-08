# Same as claude-two (the cc abbreviation), but with the Datadog connector loaded.
function claude-dd --wraps claude
    CLAUDE_CONFIG_DIR=~/.claude-two command claude $argv
end
