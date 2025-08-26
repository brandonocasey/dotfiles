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

# Extract model name/version from display_name, with special handling for Sonnet 4
if [ -n "$model_full" ] && [ "$model_full" != "null" ] && [ "$model_full" != '""' ]; then
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "Processing model_full: '$model_full'" >> "$debug_file"
    
    # Special case for Sonnet 4: show just "4"
    if echo "$model_full" | grep -qi "sonnet.*4"; then
        model="4"
        [ "$STATUSLINE_DEBUG" = "1" ] && echo "Detected Sonnet 4, using '4'" >> "$debug_file"
    else
        # For other models, extract version number first, then fall back to model name
        # Try to extract version like "3.5" or "3" from patterns like "Claude 3.5 Sonnet"
        version=$(echo "$model_full" | sed -E 's/^.*Claude[[:space:]]+([0-9]+(\.[0-9]+)?)[[:space:]]+.*$/\1/' | head -1)
        if [ "$version" != "$model_full" ] && [ -n "$version" ]; then
            model="$version"
            [ "$STATUSLINE_DEBUG" = "1" ] && echo "Extracted version: '$model'" >> "$debug_file"
        else
            # Fall back to extracting model name: "Claude 3.5 Sonnet" -> "Sonnet"
            model=$(echo "$model_full" | sed -E 's/^.*Claude[[:space:]]+[0-9]+(\.[0-9]+)?[[:space:]]+([A-Za-z]+).*$/\2/' | head -1)
            [ "$STATUSLINE_DEBUG" = "1" ] && echo "After regex extraction: '$model'" >> "$debug_file"
            # If extraction failed, try a simpler pattern for just the last word
            if [ "$model" = "$model_full" ] || [ -z "$model" ]; then
                [ "$STATUSLINE_DEBUG" = "1" ] && echo "Regex failed, trying awk fallback" >> "$debug_file"
                model=$(echo "$model_full" | awk '{print $NF}' | head -1)
                [ "$STATUSLINE_DEBUG" = "1" ] && echo "After awk fallback: '$model'" >> "$debug_file"
            fi
        fi
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
        # Special case for Sonnet 4: show just "4"
        if echo "$model_id" | grep -qi "sonnet.*4"; then
            model="4"
            [ "$STATUSLINE_DEBUG" = "1" ] && echo "Detected Sonnet 4 from model_id, using '4'" >> "$debug_file"
        else
            # Extract model name from ID: "claude-3-5-sonnet-20241022" -> "Sonnet"
            model=$(echo "$model_id" | sed -E 's/.*-(sonnet|opus|haiku)(-.*)?$/\1/' | sed 's/\b\w/\U&/g' | head -1)
            [ "$STATUSLINE_DEBUG" = "1" ] && echo "After model_id extraction: '$model'" >> "$debug_file"
            # If extraction failed, use the ID as-is
            if [ "$model" = "$model_id" ] || [ -z "$model" ]; then
                model="$model_id"
            fi
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
# Handle both regular repos and worktrees
working_dir=""
git_dir=""
actual_git_dir=""

# Determine working directory
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
    working_dir="$cwd"
elif [ -d "$PWD" ]; then
    working_dir="$PWD"
fi

if [ -n "$working_dir" ]; then
    # Check if working directory is within a git repository
    git_dir=$(cd "$working_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
    
    if [ -n "$git_dir" ] && [ -d "$git_dir" ]; then
        # Determine actual git directory (handles both regular repos and worktrees)
        if [ -d "$git_dir/.git" ]; then
            # Regular git repository
            actual_git_dir="$git_dir/.git"
        elif [ -f "$git_dir/.git" ]; then
            # Git worktree - read the gitdir from the .git file
            git_file_content=$(cat "$git_dir/.git" 2>/dev/null)
            if [[ "$git_file_content" == gitdir:* ]]; then
                actual_git_dir=$(echo "$git_file_content" | sed 's/^gitdir: *//' | tr -d '\n')
                # Handle relative paths in .git file
                if [[ "$actual_git_dir" != /* ]]; then
                    actual_git_dir="$git_dir/$actual_git_dir"
                fi
            fi
        fi
    fi
fi

if [ -n "$actual_git_dir" ] && [ -d "$actual_git_dir" ]; then
    # Try multiple methods to get the branch name, with worktree support
    branch=""
    
    # Method 1: git branch --show-current (Git 2.22+) - works well with worktrees
    if [ -z "$branch" ]; then
        branch=$(cd "$working_dir" 2>/dev/null && timeout 1 git branch --show-current 2>/dev/null | tr -d '\n')
    fi
    
    # Method 2: git symbolic-ref (works for most cases including worktrees)
    if [ -z "$branch" ]; then
        branch=$(cd "$working_dir" 2>/dev/null && timeout 1 git symbolic-ref --short HEAD 2>/dev/null | tr -d '\n')
    fi
    
    # Method 3: Read HEAD file directly (fastest, supports worktrees)
    if [ -z "$branch" ] && [ -f "$actual_git_dir/HEAD" ]; then
        head_content=$(cat "$actual_git_dir/HEAD" 2>/dev/null)
        if [[ "$head_content" == ref:* ]]; then
            # Extract branch name from ref
            branch=$(echo "$head_content" | sed 's|^ref: refs/heads/||' | tr -d '\n')
        else
            # Detached HEAD - get short commit hash
            branch=$(echo "$head_content" | cut -c1-7)
        fi
    fi
    
    # Method 4: Check for worktree-specific HEAD reference
    if [ -z "$branch" ]; then
        # In worktrees, sometimes we need to check the commondir
        common_dir="$actual_git_dir"
        if [ -f "$actual_git_dir/commondir" ]; then
            common_dir_path=$(cat "$actual_git_dir/commondir" 2>/dev/null | tr -d '\n')
            if [[ "$common_dir_path" != /* ]]; then
                common_dir="$actual_git_dir/$common_dir_path"
            else
                common_dir="$common_dir_path"
            fi
        fi
        
        # Try to read from the common git directory
        if [ -f "$common_dir/HEAD" ]; then
            head_content=$(cat "$common_dir/HEAD" 2>/dev/null)
            if [[ "$head_content" == ref:* ]]; then
                branch=$(echo "$head_content" | sed 's|^ref: refs/heads/||' | tr -d '\n')
            fi
        fi
    fi
    
    # Method 5: git describe for detached HEAD
    if [ -z "$branch" ]; then
        branch=$(cd "$working_dir" 2>/dev/null && timeout 1 git describe --contains --all HEAD 2>/dev/null | tr -d '\n')
    fi
    
    # Method 6: git name-rev as last resort
    if [ -z "$branch" ]; then
        branch=$(cd "$working_dir" 2>/dev/null && timeout 1 git name-rev --name-only HEAD 2>/dev/null | tr -d '\n')
    fi
    
    # Clean up branch name (remove any unwanted prefixes/suffixes)
    if [ -n "$branch" ]; then
        # Remove any trailing whitespace and common prefixes
        branch=$(echo "$branch" | sed 's/^remotes\/[^\/]*\///' | sed 's/~[0-9]*$//' | tr -d '\n')
    fi
    
    # If still no branch found, show detached state
    if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
        branch="detached"
    fi
    
    # Check for changes with reasonable timeout
    status_output=$(cd "$working_dir" 2>/dev/null && timeout 0.5 git status --porcelain --untracked-files=no 2>/dev/null)
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