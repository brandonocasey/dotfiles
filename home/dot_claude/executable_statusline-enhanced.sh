#!/bin/bash

# Statusline with model display and full path (no shortening)
# Read input - try with timeout first, fallback to non-timeout read
input=""
if [ -t 0 ]; then
    # No input available (terminal), use empty JSON
    input='{}'
else
    # Read from stdin with reasonable timeout
    input=$(timeout 1 cat 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$input" ]; then
        # Timeout or empty, try one more time without timeout but with limit
        input=$(head -c 10000 2>/dev/null || echo '{}')
    fi
fi

# Extract data from JSON input using robust grep/sed (no jq dependency)
# Extract current_dir from workspace object - handle various spacing patterns
cwd=$(echo "$input" | grep -o '"current_dir"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/.*"current_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)

# Also try extracting from top-level cwd field as fallback
if [ -z "$cwd" ]; then
    cwd=$(echo "$input" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
fi

# Extract display_name from model object - handle various spacing patterns  
# First try to extract from within the model object context
model_section=$(echo "$input" | sed -n '/"model"[[:space:]]*:[[:space:]]*{/,/}/p' 2>/dev/null)
if [ -n "$model_section" ]; then
    model_full=$(echo "$model_section" | grep -o '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/.*"display_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
else
    # Fallback to global search
    model_full=$(echo "$input" | grep -o '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/.*"display_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
fi

# Enable debug logging if environment variable is set
if [ "$STATUSLINE_DEBUG" = "1" ]; then
    debug_file="/tmp/statusline-debug.log"
    echo "=== DEBUG $(date) ===" >> "$debug_file"
    echo "Raw input: $input" >> "$debug_file"
    echo "Extracted model_full: '$model_full'" >> "$debug_file"
fi

# Extract just the model name (Sonnet, Opus, Haiku) from display_name
if [ -n "$model_full" ] && [ "$model_full" != "null" ] && [ "$model_full" != '""' ]; then
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "Processing model_full: '$model_full'" >> "$debug_file"
    # Extract model name: "Claude 3.5 Sonnet" -> "Sonnet", "Claude 3 Opus" -> "Opus", etc.
    model=$(echo "$model_full" | sed -E 's/^.*Claude[[:space:]]+[0-9]+(\.[0-9]+)?[[:space:]]+([A-Za-z]+).*$/\2/' | head -1)
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "After regex extraction: '$model'" >> "$debug_file"
    # If extraction failed, try a simpler pattern for just the last word
    if [ "$model" = "$model_full" ] || [ -z "$model" ]; then
        [ "$STATUSLINE_DEBUG" = "1" ] && echo "Regex failed, trying awk fallback" >> "$debug_file"
        model=$(echo "$model_full" | awk '{print $NF}' | head -1)
        [ "$STATUSLINE_DEBUG" = "1" ] && echo "After awk fallback: '$model'" >> "$debug_file"
    fi
else
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "No model_full found, trying model id fallback" >> "$debug_file"
    # Fallback: try extracting model id from model object context
    if [ -n "$model_section" ]; then
        model_id=$(echo "$model_section" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    else
        model_id=$(echo "$input" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | head -1)
    fi
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "Extracted model_id: '$model_id'" >> "$debug_file"
    if [ -n "$model_id" ] && [ "$model_id" != "null" ] && [ "$model_id" != '""' ]; then
        # Extract model name from ID: "claude-3-5-sonnet-20241022" -> "Sonnet"
        model=$(echo "$model_id" | sed -E 's/.*-(sonnet|opus|haiku)(-.*)?$/\1/' | sed 's/\b\w/\U&/g' | head -1)
        [ "$STATUSLINE_DEBUG" = "1" ] && echo "After model_id extraction: '$model'" >> "$debug_file"
        # If extraction failed, use the ID as-is
        if [ "$model" = "$model_id" ] || [ -z "$model" ]; then
            model="$model_id"
        fi
    else
        model=""
    fi
fi
[ "$STATUSLINE_DEBUG" = "1" ] && echo "Final model value: '$model'" >> "$debug_file"

# Fallback to PWD if extraction fails or returns empty/null
if [ -z "$cwd" ] || [ "$cwd" = "null" ] || [ "$cwd" = '""' ]; then
    cwd="$PWD"
fi

# Fallback model name if extraction fails or returns empty/null
if [ -z "$model" ] || [ "$model" = "null" ] || [ "$model" = '""' ]; then
    model="Claude"
fi

# Ensure cwd is an absolute path and exists
if [ ! -d "$cwd" ]; then
    cwd="$PWD"
fi

# Current time and user info with fallbacks
time=$(date '+%I:%M %p' 2>/dev/null || date '+%H:%M' 2>/dev/null || echo "??:??")
user=$(whoami 2>/dev/null || echo "user")
host=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "host")

# Git information - check both cwd and PWD to ensure we find git repo
git_dir=""
if [ -n "$cwd" ] && [ -d "$cwd" ] && [ -d "$cwd/.git" ]; then
    git_dir="$cwd"
elif [ -d "$PWD/.git" ]; then
    git_dir="$PWD"
elif [ -n "$cwd" ] && [ -d "$cwd" ]; then
    # Check if cwd is within a git repository
    git_dir=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
elif [ -d "$PWD" ]; then
    # Check if PWD is within a git repository
    git_dir=$(git rev-parse --show-toplevel 2>/dev/null)
fi

if [ -n "$git_dir" ] && [ -d "$git_dir" ]; then
    # Try multiple methods to get the branch name, with longer timeout
    branch=""
    
    # Method 1: git branch --show-current (Git 2.22+)
    if [ -z "$branch" ]; then
        branch=$(cd "$git_dir" 2>/dev/null && timeout 1 git branch --show-current 2>/dev/null | tr -d '\n')
    fi
    
    # Method 2: git symbolic-ref (works for most cases)
    if [ -z "$branch" ]; then
        branch=$(cd "$git_dir" 2>/dev/null && timeout 1 git symbolic-ref --short HEAD 2>/dev/null | tr -d '\n')
    fi
    
    # Method 3: Read .git/HEAD directly (fastest, most reliable)
    if [ -z "$branch" ] && [ -f "$git_dir/.git/HEAD" ]; then
        head_content=$(cat "$git_dir/.git/HEAD" 2>/dev/null)
        if [[ "$head_content" == ref:* ]]; then
            branch=$(echo "$head_content" | sed 's|^ref: refs/heads/||' | tr -d '\n')
        else
            # Detached HEAD - get short commit hash
            branch=$(echo "$head_content" | cut -c1-7)
        fi
    fi
    
    # Method 4: git describe for detached HEAD
    if [ -z "$branch" ]; then
        branch=$(cd "$git_dir" 2>/dev/null && timeout 1 git describe --contains --all HEAD 2>/dev/null | tr -d '\n')
    fi
    
    # Method 5: git name-rev as last resort
    if [ -z "$branch" ]; then
        branch=$(cd "$git_dir" 2>/dev/null && timeout 1 git name-rev --name-only HEAD 2>/dev/null | tr -d '\n')
    fi
    
    # If still no branch found, show detached state
    if [ -z "$branch" ]; then
        branch="detached"
    fi
    
    # Check for changes with reasonable timeout
    status_output=$(cd "$git_dir" 2>/dev/null && timeout 0.5 git status --porcelain --untracked-files=no 2>/dev/null)
    if [ -n "$status_output" ]; then
        git_status=' ●'
    else
        git_status=''
    fi
    git_info=" ($branch$git_status)"
else
    git_info=''
fi

# Prepare the full path for display (no shortening)
display_path="$cwd"

# Replace home directory with ~ for cleaner display
if [[ "$display_path" == "$HOME"* ]]; then
    display_path="~${display_path#$HOME}"
fi

# Handle empty or invalid paths
if [ -z "$display_path" ] || [ "$display_path" = "null" ]; then
    display_path="~"
fi

# Ensure all variables have safe default values and are not empty
user="${user:-unknown}"
host="${host:-localhost}"  
time="${time:-??:??}"
model="${model:-Claude}"
git_info="${git_info:-}"

# Double-check time is not empty (critical for debugging)
if [ -z "$time" ] || [ "$time" = "null" ]; then
    time=$(date '+%I:%M %p' 2>/dev/null || date '+%H:%M' 2>/dev/null || echo "$(date '+%H:%M' 2>/dev/null)")
    if [ -z "$time" ]; then
        time="??:??"
    fi
fi

# Build and output the status line with Fish/Tide inspired styling
# Changed time from dim gray (\033[90m) to bright white (\033[97m) for better visibility
printf "\033[36m%s\033[0m@\033[32m%s\033[0m \033[35m%s\033[0m\033[33m%s\033[0m \033[97m%s\033[0m | \033[34m%s\033[0m" \
    "$user" "$host" "$display_path" "$git_info" "$time" "$model"