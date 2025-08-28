#!/bin/bash

# Quick self-test mode for branch directory detection
if [ "$1" = "test-branch" ]; then
    # Source the function
    directory_contains_branch() {
        local dir_name="$1"
        local branch_name="$2"
        
        # Skip check if either is empty or branch is "detached"
        if [ -z "$dir_name" ] || [ -z "$branch_name" ] || [ "$branch_name" = "detached" ]; then
            return 1
        fi
        
        # Extract just the directory name (not the full path)
        local base_dir=$(basename "$dir_name")
        
        # Convert both to lowercase for case-insensitive comparison
        local lower_dir=$(echo "$base_dir" | tr '[:upper:]' '[:lower:]')
        local lower_branch=$(echo "$branch_name" | tr '[:upper:]' '[:lower:]')
        
        # Check if directory name contains branch name (partial match)
        if echo "$lower_dir" | grep -q "$lower_branch"; then
            return 0  # Match found
        fi
        
        return 1  # No match
    }
    
    echo "=== Testing Branch Directory Detection ==="
    test_cases=(
        "/path/to/feature-auth:feature-auth:MATCH"
        "/path/to/feature-auth-updates:feature-auth:MATCH"
        "/path/to/Feature-Auth:feature-auth:MATCH"
        "/path/to/main-branch:main:MATCH"
        "/path/to/book-manager:book-manager:MATCH"
        "/path/to/project:feature-branch:NO_MATCH"
        "/path/to/src:main:NO_MATCH"
        "$(pwd):$(git branch --show-current 2>/dev/null || echo 'unknown'):CURRENT"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r test_dir test_branch expected <<< "$test_case"
        if directory_contains_branch "$test_dir" "$test_branch"; then
            result="MATCH"
        else
            result="NO_MATCH"
        fi
        
        status="✓"
        if [ "$result" != "$expected" ] && [ "$expected" != "CURRENT" ]; then
            status="✗"
        elif [ "$expected" = "CURRENT" ]; then
            status="?"
        fi
        
        echo "$status Directory: '$(basename "$test_dir")' Branch: '$test_branch' -> $result"
    done
    
    echo ""
    echo "Current directory test:"
    current_branch=$(git branch --show-current 2>/dev/null || echo "no-git")
    current_dir=$(basename "$(pwd)")
    echo "Current directory: '$current_dir'"
    echo "Current branch: '$current_branch'"
    if directory_contains_branch "$(pwd)" "$current_branch"; then
        echo "Result: MATCH - Branch indicator would be hidden ONLY if compression is also needed"
        echo "Note: Both conditions must be met for branch hiding:"
        echo "  1. Directory contains branch name (✓ MATCH)"
        echo "  2. Path compression is needed (depends on terminal width and path length)"
    else
        echo "Result: NO_MATCH - Branch indicator would always be shown (directory doesn't contain branch)"
    fi
    
    exit 0
fi

# Statusline with model display and path compression
# Read input - try with timeout first, fallback to non-timeout read

# Real-time mode: if STATUSLINE_REALTIME=1, use optimized fast execution
if [ "$STATUSLINE_REALTIME" = "1" ]; then
    # Cache directory for expensive operations
    CACHE_DIR="/tmp/.statusline-cache"
    mkdir -p "$CACHE_DIR" 2>/dev/null
    
    # Function to get terminal width using fastest available method
    get_terminal_width_fast() {
        local width
        # Method 1: stty (fastest)
        width=$(stty size 2>/dev/null | cut -d' ' -f2)
        [ -n "$width" ] && [ "$width" -gt 0 ] && { echo "$width"; return; }
        
        # Method 2: tput
        width=$(tput cols 2>/dev/null)
        [ -n "$width" ] && [ "$width" -gt 0 ] && { echo "$width"; return; }
        
        # Method 3: environment
        [ -n "$COLUMNS" ] && [ "$COLUMNS" -gt 0 ] && { echo "$COLUMNS"; return; }
        
        # Fallback
        echo "80"
    }
    
    # Override terminal width detection for real-time mode
    terminal_width=$(get_terminal_width_fast)
    
    # Enable caching for git operations in real-time mode
    ENABLE_GIT_CACHE=1
fi

# Dynamic path compression function based on available terminal space
# Compresses folders to their first character only (no ellipsis)
compress_path_dynamic() {
    local path="$1"
    local available_chars="$2"
    local path_length=${#path}
    
    # If path fits in available space, don't compress
    if [ $path_length -le $available_chars ]; then
        echo "$path"
        return
    fi
    
    # Split path into components
    IFS='/' read -ra path_parts <<< "$path"
    local num_parts=${#path_parts[@]}
    
    # Don't compress paths with 2 or fewer parts - they're already minimal
    if [ $num_parts -le 2 ]; then
        echo "$path"
        return
    fi
    
    # Calculate compression strategy based on available space
    local target_length=$((available_chars - 3))  # Reduced buffer for better space usage
    local compression_level=1
    
    # Determine compression level based on how much we need to save
    local chars_to_save=$((path_length - target_length))
    if [ $chars_to_save -gt 30 ]; then
        compression_level=3  # Aggressive compression
    elif [ $chars_to_save -gt 15 ]; then
        compression_level=2  # Medium compression
    else
        compression_level=1  # Light compression
    fi
    
    # Helper function to compress a part while preserving first character
    compress_part() {
        local part="$1"
        local level="$2"
        local part_length=${#part}
        
        # Never compress parts that are already very short
        if [ $part_length -le 2 ]; then
            echo "$part"
            return
        fi
        
        # For important system directories, keep them full
        if [[ "$part" =~ ^(src|lib|bin|etc|usr|opt|var|home|Users)$ ]]; then
            echo "$part"
            return
        fi
        
        case $level in
            3) 
                # Aggressive: first letter only (no ellipsis)
                if [ $part_length -gt 1 ]; then
                    echo "${part:0:1}"
                else
                    echo "$part"
                fi
                ;;
            2) 
                # Medium: first 2 chars or first letter only (no ellipsis)
                if [ $part_length -gt 3 ]; then
                    echo "${part:0:2}"
                elif [ $part_length -gt 1 ]; then
                    echo "${part:0:1}"
                else
                    echo "$part"
                fi
                ;;
            *) 
                # Light: first 3 chars, 2 chars, or 1 char (no ellipsis)
                if [ $part_length -gt 4 ]; then
                    echo "${part:0:3}"
                elif [ $part_length -gt 3 ]; then
                    echo "${part:0:2}"
                elif [ $part_length -gt 1 ]; then
                    echo "${part:0:1}"
                else
                    echo "$part"
                fi
                ;;
        esac
    }
    
    local compressed=""
    local i=0
    
    for part in "${path_parts[@]}"; do
        if [ $i -eq 0 ]; then
            # First part (empty or ~)
            compressed="$part"
        elif [ $i -eq 1 ]; then
            # Second part - apply compression based on level
            compressed="$compressed/$(compress_part "$part" "$compression_level")"
        elif [ $i -lt $((num_parts - 2)) ]; then
            # Middle parts - compress based on level
            compressed="$compressed/$(compress_part "$part" "$compression_level")"
        elif [ $i -eq $((num_parts - 2)) ]; then
            # Second to last part - compress less aggressively to maintain context
            if [ $compression_level -ge 3 ] && [ ${#part} -gt 8 ]; then
                # For very long names under aggressive compression, still preserve first char
                if [ ${#part} -gt 6 ]; then
                    compressed="$compressed/${part:0:4}"
                else
                    compressed="$compressed/$(compress_part "$part" 2)"  # Use medium compression
                fi
            else
                compressed="$compressed/$part"
            fi
        else
            # Last part - always keep full for context and readability
            compressed="$compressed/$part"
        fi
        ((i++))
    done
    
    # If compressed version is still too long, try more aggressive compression
    local compressed_length=${#compressed}
    if [ $compressed_length -gt $available_chars ] && [ $num_parts -gt 3 ]; then
        # Very aggressive fallback - preserve first chars of middle directories
        local first_part="${path_parts[0]}"
        local second_last="${path_parts[$((num_parts-2))]}"
        local last_part="${path_parts[$((num_parts-1))]}"
        
        # Create middle sections with first letters preserved
        local middle_compressed=""
        for ((j=1; j<num_parts-2; j++)); do
            local middle_part="${path_parts[j]}"
            if [ ${#middle_part} -gt 0 ]; then
                if [ -z "$middle_compressed" ]; then
                    middle_compressed="${middle_part:0:1}"
                else
                    middle_compressed="$middle_compressed/${middle_part:0:1}"
                fi
            fi
        done
        
        if [ -n "$middle_compressed" ]; then
            compressed="$first_part/$middle_compressed/$second_last/$last_part"
        else
            compressed="$first_part/$second_last/$last_part"
        fi
        
        # If still too long, compress the second-last part while preserving first char
        if [ ${#compressed} -gt $available_chars ] && [ ${#second_last} -gt 4 ]; then
            compressed="$first_part/$middle_compressed/${second_last:0:1}/$last_part"
        fi
    fi
    
    # Final safety check - if we couldn't compress enough, show minimal path with first chars
    if [ ${#compressed} -gt $available_chars ]; then
        if [ $num_parts -ge 2 ]; then
            local first_part="${path_parts[0]}"
            local last_part="${path_parts[$((num_parts-1))]}"
            
            # For very narrow terminals, be even more aggressive
            if [ $available_chars -lt 15 ]; then
                # Ultra-compact: just show first and last with minimal separators
                if [ $num_parts -gt 2 ]; then
                    compressed="$first_part/…/$last_part"
                else
                    compressed="$first_part/$last_part"
                fi
                
                # If still too long, truncate the last part
                if [ ${#compressed} -gt $available_chars ] && [ ${#last_part} -gt 4 ]; then
                    last_part="${last_part:0:3}…"
                    if [ $num_parts -gt 2 ]; then
                        compressed="$first_part/…/$last_part"
                    else
                        compressed="$first_part/$last_part"
                    fi
                fi
            else
                # Standard minimal compression with first letters
                if [ $num_parts -gt 2 ]; then
                    local middle_parts=""
                    for ((j=1; j<num_parts-1; j++)); do
                        local middle_part="${path_parts[j]}"
                        if [ ${#middle_part} -gt 0 ]; then
                            if [ -z "$middle_parts" ]; then
                                middle_parts="${middle_part:0:1}"
                            else
                                middle_parts="$middle_parts/${middle_part:0:1}"
                            fi
                        fi
                    done
                    compressed="$first_part/$middle_parts/$last_part"
                else
                    compressed="$first_part/$last_part"
                fi
            fi
        else
            # Single part path - truncate if necessary
            if [ ${#path} -gt $available_chars ] && [ $available_chars -gt 5 ]; then
                compressed="${path:0:$((available_chars-1))}…"
            else
                compressed="$path"
            fi
        fi
    fi
    
    echo "$compressed"
}

# Legacy compression function for backward compatibility and testing
compress_path() {
    local path="$1"
    local should_compress="$2"
    
    # Only compress if explicitly requested
    if [ "$should_compress" != "true" ]; then
        echo "$path"
        return
    fi
    
    # Use dynamic compression with a default available space
    compress_path_dynamic "$path" 35
}
input=""
if [ -t 0 ]; then
    # No input available (terminal), use empty JSON
    input='{}'
else
    # Read from stdin with reduced timeout for better performance
    input=$(timeout 0.5 cat 2>/dev/null)
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

# Test compression if STATUSLINE_TEST_COMPRESSION is set
# Quick test execution
if [ "$1" = "test" ]; then
    STATUSLINE_TEST_COMPRESSION=1
fi

if [ "$STATUSLINE_TEST_COMPRESSION" = "1" ]; then
    echo "=== Path Compression Tests (Clean First Letter Only, No Ellipsis) ==="
    echo "=== Legacy Compression (35 char threshold) ==="
    echo "Short path: $(compress_path "~/src" "true")"
    echo "Medium path: $(compress_path "~/Projects/my-project" "true")"
    echo "Long path: $(compress_path "~/Projects/brandonocasey/book-manager/src/components" "true")"
    echo "Very long path: $(compress_path "~/Projects/brandonocasey/book-manager/src/components/filesystem-browser/components" "true")"
    echo "System path: $(compress_path "/usr/local/bin/node_modules/package" "true")"
    echo ""
    echo "=== Dynamic Compression Tests (First letter only, no ellipsis) ==="
    test_path="~/Projects/brandonocasey/book-manager/src/components/filesystem-browser/components"
    echo "Test path: $test_path (${#test_path} chars)"
    echo "With 15 chars available: $(compress_path_dynamic "$test_path" 15)"
    echo "With 25 chars available: $(compress_path_dynamic "$test_path" 25)"
    echo "With 35 chars available: $(compress_path_dynamic "$test_path" 35)"
    echo "With 50 chars available: $(compress_path_dynamic "$test_path" 50)"
    echo "With 70 chars available: $(compress_path_dynamic "$test_path" 70)"
    echo ""
    echo "=== Additional Test Cases ==="
    echo "Deep nested: $(compress_path_dynamic "~/very/deep/nested/folder/structure/with/many/levels/final" 30)"
    echo "Mixed lengths: $(compress_path_dynamic "~/a/verylongfoldername/b/anotherlongone/final" 25)"
    echo "System path: $(compress_path_dynamic "/usr/local/bin/node_modules/package/dist" 30)"
    echo ""
    echo "Terminal width simulation (first char only, clean compression):"
    for width in 40 60 80 100 120 140; do
        # Simulate other elements: user@host (15) + git (8) + time (9) + port (7) + model (8) + margins (8)
        simulated_other_elements=55
        available=$((width - simulated_other_elements))
        if [ $available -lt 5 ]; then available=5; fi
        compressed=$(compress_path_dynamic "$test_path" "$available")
        echo "Terminal $width cols -> ${available} available -> '${compressed}' (${#compressed} chars)"
    done
    
    echo ""
    echo "=== Directory/Branch Match Tests ==="
    echo "Testing directory_contains_branch function:"
    
    # Test function directly
    test_cases=(
        "/path/to/feature-auth:feature-auth:MATCH"
        "/path/to/feature-auth-updates:feature-auth:MATCH"
        "/path/to/Feature-Auth:feature-auth:MATCH"
        "/path/to/main-branch:main:MATCH"
        "/path/to/book-manager:book-manager:MATCH"
        "/path/to/project:feature-branch:NO_MATCH"
        "/path/to/src:main:NO_MATCH"
        "/path/to/empty::NO_MATCH"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r test_dir test_branch expected <<< "$test_case"
        if directory_contains_branch "$test_dir" "$test_branch"; then
            result="MATCH"
        else
            result="NO_MATCH"
        fi
        
        status="✓"
        if [ "$result" != "$expected" ]; then
            status="✗"
        fi
        
        echo "$status Directory: '$(basename "$test_dir")' Branch: '$test_branch' -> $result (expected: $expected)"
    done
    
    echo ""
    echo "=== Branch Compression Tests ==="
    echo "Testing branch name compression:"
    
    # Test the compress_branch_name function directly
    test_branches=(
        "feature-authentication:1:feature"
        "feature-authentication:2:featu" 
        "feature-authentication:3:fea"
        "main:1:main"
        "develop-new-feature:1:develop"
        "develop-new-feature:2:devel"
        "develop-new-feature:3:dev"
        "fix:1:fix"
        "fix:2:fix"
        "fix:3:fix"
    )
    
    for test_case in "${test_branches[@]}"; do
        IFS=':' read -r test_branch level expected <<< "$test_case"
        result=$(compress_branch_name "$test_branch" "$level")
        if [ "$result" = "$expected" ]; then
            status="✓"
        else
            status="✗"
        fi
        echo "$status Branch: '$test_branch' Level $level -> '$result' (expected: '$expected')"
    done
    
    echo ""
    echo "Branch-first compression priority examples:"
    echo "PRIORITY 1 - Branch compression (preserves path info):"
    echo "- Directory 'src', Branch 'feature-authentication', Space needed -> Branch compressed to 'featu' first"
    echo "- Directory 'components', Branch 'develop-new-feature', Space needed -> Branch compressed to 'devel' first" 
    echo "- Directory 'feature-auth', Branch 'feature-auth', Space needed -> Branch hidden (directory match priority)"
    echo ""
    echo "PRIORITY 2 - Path compression (only after branch compression applied):"
    echo "- If still need space after branch compression -> Apply path compression"
    echo "- Path compression uses existing logic (first letter preservation)"
    echo ""
    echo "PRIORITY 3 - Emergency branch hiding (absolute last resort):"
    echo "- If both branch and path compression insufficient -> Hide branch completely"
    
    exit 0
fi

# Extract model name/version from display_name, removing "Claude" prefix
if [ -n "$model_full" ] && [ "$model_full" != "null" ] && [ "$model_full" != '""' ]; then
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "Processing model_full: '$model_full'" >> "$debug_file"
    
    # Remove "Claude" prefix and extract the rest
    # Handles various formats:
    # "Claude Sonnet 4" -> "Sonnet 4"
    # "Claude 3.5 Sonnet" -> "3.5 Sonnet"  
    # "Claude Opus 4.1" -> "Opus 4.1"
    model=$(echo "$model_full" | sed -E 's/^Claude[[:space:]]+//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | head -1)
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "After removing Claude prefix: '$model'" >> "$debug_file"
    
    # If the regex didn't match (no "Claude" prefix), use the original
    if [ "$model" = "$model_full" ]; then
        # Try extracting just the relevant parts if it's a different format
        # Look for pattern like "Model Name Version" or "Version Model"
        temp_model=$(echo "$model_full" | sed -E 's/^.*(Sonnet|Opus|Haiku)[[:space:]]*([0-9]+(\.[0-9]+)?)?.*$/\1 \2/' | sed 's/[[:space:]]*$//' | head -1)
        if [ "$temp_model" != "$model_full" ] && [ -n "$temp_model" ]; then
            model="$temp_model"
        else
            # Final fallback: use last few words or the full string if short
            model=$(echo "$model_full" | awk '{if(NF<=3) print $0; else print $(NF-1)" "$NF}' | head -1)
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
        # Extract model name and version from ID patterns like:
        # "claude-sonnet-4-20250514" -> "Sonnet 4"
        # "claude-3-5-sonnet-20241022" -> "3.5 Sonnet"
        # "claude-opus-4-1-20250101" -> "Opus 4.1"
        
        if echo "$model_id" | grep -qi "sonnet.*4"; then
            model="Sonnet 4"
            [ "$STATUSLINE_DEBUG" = "1" ] && echo "Detected Sonnet 4 from model_id, using 'Sonnet 4'" >> "$debug_file"
        elif echo "$model_id" | grep -qi "opus.*4"; then
            # Handle Opus 4.x patterns
            version=$(echo "$model_id" | sed -E 's/.*opus-([0-9]+(-[0-9]+)*).*/\1/' | tr '-' '.')
            if [ "$version" != "$model_id" ]; then
                model="Opus $version"
            else
                model="Opus 4"
            fi
            [ "$STATUSLINE_DEBUG" = "1" ] && echo "Detected Opus 4 from model_id, using '$model'" >> "$debug_file"
        else
            # Try to extract version and model name from patterns like "claude-3-5-sonnet"
            temp_model=$(echo "$model_id" | sed -E 's/^claude-([0-9]+(-[0-9]+)*)?-?(sonnet|opus|haiku)(-.*)?$/\1 \3/' | tr '-' '.' | sed 's/\b\w/\U&/g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [ "$temp_model" != "$model_id" ] && [ -n "$temp_model" ]; then
                model="$temp_model"
                [ "$STATUSLINE_DEBUG" = "1" ] && echo "Extracted from model_id pattern: '$model'" >> "$debug_file"
            else
                # Fallback: just extract the model name
                model=$(echo "$model_id" | sed -E 's/.*-(sonnet|opus|haiku)(-.*)?$/\1/' | sed 's/\b\w/\U&/g' | head -1)
                [ "$STATUSLINE_DEBUG" = "1" ] && echo "After model_id extraction: '$model'" >> "$debug_file"
                # If extraction failed, use the ID as-is
                if [ "$model" = "$model_id" ] || [ -z "$model" ]; then
                    model="$model_id"
                fi
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

# PORT environment variable (show if set with label)
port_info=""
if [ -n "$PORT" ] && [ "$PORT" != "null" ] && [ "$PORT" != '""' ]; then
    port_info=" p:$PORT"
fi

# Function to check if directory name contains branch name (case-insensitive, partial match)
directory_contains_branch() {
    local dir_name="$1"
    local branch_name="$2"
    
    # Skip check if either is empty or branch is "detached"
    if [ -z "$dir_name" ] || [ -z "$branch_name" ] || [ "$branch_name" = "detached" ]; then
        return 1
    fi
    
    # Extract just the directory name (not the full path)
    local base_dir=$(basename "$dir_name")
    
    # Convert both to lowercase for case-insensitive comparison
    local lower_dir=$(echo "$base_dir" | tr '[:upper:]' '[:lower:]')
    local lower_branch=$(echo "$branch_name" | tr '[:upper:]' '[:lower:]')
    
    # Check if directory name contains branch name (partial match)
    if echo "$lower_dir" | grep -q "$lower_branch"; then
        return 0  # Match found
    fi
    
    return 1  # No match
}

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
    # Use cached git info in real-time mode for performance
    if [ "$ENABLE_GIT_CACHE" = "1" ]; then
        git_cache_file="$CACHE_DIR/git_$(pwd | md5sum 2>/dev/null | cut -d' ' -f1 || echo 'default')"
        if [ -f "$git_cache_file" ]; then
            # Check if cache is less than 15 seconds old
            cache_age=$(($(date +%s) - $(stat -f %m "$git_cache_file" 2>/dev/null || stat -c %Y "$git_cache_file" 2>/dev/null || echo 0)))
            if [ $cache_age -lt 15 ]; then
                git_info=$(cat "$git_cache_file" 2>/dev/null || echo "")
                # Skip expensive git operations if we have recent cached data
                if [ -n "$git_info" ]; then
                    # Clean up any old cache files while we're here (non-blocking)
                    find "$CACHE_DIR" -name "git_*" -mtime +1m -delete 2>/dev/null &
                    # Continue to path compression
                    branch="cached"
                    git_status=""
                    git_info_cached=1
                fi
            fi
        fi
    fi
    
    # Only do expensive git operations if not using cached data
    if [ "$git_info_cached" != "1" ]; then
        # Simplified git branch detection - use only the fastest method
        branch=""
    
        # Use git branch --show-current with reduced timeout (fastest and most reliable)
        branch=$(cd "$working_dir" 2>/dev/null && timeout 0.5 git branch --show-current 2>/dev/null | tr -d '\n')
        
        # If that fails, try reading HEAD file directly (no network/git command overhead)
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
    
    # Clean up branch name (remove any unwanted prefixes/suffixes)
    if [ -n "$branch" ]; then
        # Remove any trailing whitespace and common prefixes
        branch=$(echo "$branch" | sed 's/^remotes\/[^\/]*\///' | sed 's/~[0-9]*$//' | tr -d '\n')
    fi
    
    # If still no branch found, show detached state
    if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
        branch="detached"
    fi
    
    # Simplified git status checking with reduced timeouts
    git_status=""
    
    # Quick status check with reduced timeout - combine checks for better performance
    if cd "$working_dir" 2>/dev/null; then
        # Use single git status command instead of multiple diff commands (more efficient)
        if timeout 0.5 git status --porcelain 2>/dev/null | head -1 | grep -q '.'; then
            git_status="●"
        fi
    fi
    
    # Initially format git info with branch name (normal display)
    if [ -n "$git_status" ]; then
        git_info_with_branch=" ($branch $git_status)"
        git_info_without_branch=" ($git_status)"
    else
        git_info_with_branch=" ($branch)"
        git_info_without_branch=""
    fi
    
    # Default to showing branch name
    git_info="$git_info_with_branch"
    branch_hidden=false
    
    # Store for later decision after compression calculations
    directory_contains_branch_result=false
    if directory_contains_branch "$working_dir" "$branch"; then
        directory_contains_branch_result=true
    fi
    
    # Cache the git info for real-time mode
    if [ "$ENABLE_GIT_CACHE" = "1" ] && [ "$git_info_cached" != "1" ]; then
        echo "$git_info" > "$git_cache_file" 2>/dev/null || true
    fi
    
    fi  # End of non-cached git operations
else
    git_info=''
fi

# Prepare the path for display with intelligent compression
display_path="$cwd"

# Replace home directory with ~ for cleaner display
if [[ "$display_path" == "$HOME"* ]]; then
    display_path="~${display_path#$HOME}"
fi

# Handle empty or invalid paths
if [ -z "$display_path" ] || [ "$display_path" = "null" ]; then
    display_path="~"
fi

# Dynamic compression with branch-first priority
original_path="$display_path"

# Get terminal width with real-time detection (skip if already set by real-time mode)
if [ -z "$terminal_width" ]; then
    # Try multiple methods to get current terminal width
    if [ -t 1 ]; then
        # Method 1: tput (most reliable)
        terminal_width=$(tput cols 2>/dev/null)
        
        # Method 2: stty (fallback)
        if [ -z "$terminal_width" ]; then
            terminal_width=$(stty size 2>/dev/null | cut -d' ' -f2)
        fi
        
        # Method 3: environment variable (last resort)
        if [ -z "$terminal_width" ]; then
            terminal_width="$COLUMNS"
        fi
    fi
    
    # Final fallback to reasonable default
    if [ -z "$terminal_width" ] || [ "$terminal_width" -le 0 ]; then
        terminal_width="80"
    fi
fi

# Compress model names first to get accurate length
compressed_model="$model"
if [[ "$model" == *"Sonnet"* ]]; then
    compressed_model=$(echo "$model" | sed 's/Sonnet[[:space:]]*/S/g')
elif [[ "$model" == *"Opus"* ]]; then
    compressed_model=$(echo "$model" | sed 's/Opus[[:space:]]*/O/g')
fi

# Function to compress branch names when needed
compress_branch_name() {
    local branch_name="$1"
    local compression_level="$2"
    
    # Skip compression for very short branch names or special cases
    if [ -z "$branch_name" ] || [ ${#branch_name} -le 3 ] || [ "$branch_name" = "detached" ]; then
        echo "$branch_name"
        return
    fi
    
    case $compression_level in
        3) 
            # Aggressive: first 2-3 characters
            if [ ${#branch_name} -gt 6 ]; then
                echo "${branch_name:0:3}"
            elif [ ${#branch_name} -gt 4 ]; then
                echo "${branch_name:0:2}"
            else
                echo "$branch_name"
            fi
            ;;
        2) 
            # Medium: first 4-5 characters
            if [ ${#branch_name} -gt 8 ]; then
                echo "${branch_name:0:5}"
            elif [ ${#branch_name} -gt 6 ]; then
                echo "${branch_name:0:4}"
            else
                echo "$branch_name"
            fi
            ;;
        1) 
            # Light: first 6-7 characters
            if [ ${#branch_name} -gt 10 ]; then
                echo "${branch_name:0:7}"
            elif [ ${#branch_name} -gt 8 ]; then
                echo "${branch_name:0:6}"
            else
                echo "$branch_name"
            fi
            ;;
        *) 
            # No compression
            echo "$branch_name"
            ;;
    esac
}

# PRIORITY 1: Branch compression when space is needed
# Calculate initial space used by other status line elements
# Format: user@host path git_info time p:port | model
# Example: "user@host /path (branch) 12:34 PM p:3001 | S4"
user_host_part="$user@$host "
time_part=" $time"
port_part="$port_info"
model_part=" | $compressed_model"

# Reserve space for potential auto-compact message (only on wider terminals)
auto_compact_reserve=0
if [ $terminal_width -gt 80 ]; then
    auto_compact_reserve=15  # Reserve space for " [auto-compact]"
fi

# Calculate available space for path and git_info combined
# Account for spaces and separators between elements
separators_length=1  # One space before path

# Calculate safety margins
safety_margin=8
if [ $terminal_width -lt 60 ]; then
    safety_margin=12  # More conservative for narrow terminals
elif [ $terminal_width -lt 80 ]; then
    safety_margin=10
fi

# Calculate total space needed by fixed elements
fixed_elements_length=$((${#user_host_part} + ${#time_part} + ${#port_part} + ${#model_part} + auto_compact_reserve + separators_length + safety_margin))

# Available space for path + git_info
available_space_for_path_and_git=$((terminal_width - fixed_elements_length))

# Ensure we have minimum space
min_total_space=15
if [ $terminal_width -lt 40 ]; then
    min_total_space=10
elif [ $terminal_width -lt 60 ]; then
    min_total_space=12
fi

if [ $available_space_for_path_and_git -lt $min_total_space ]; then
    available_space_for_path_and_git=$min_total_space
fi

# Initial git_info to measure
current_git_info="$git_info_with_branch"
branch_compression_applied=0
branch_hidden=false

# Calculate space if we use full git_info
total_needed_space=$((${#original_path} + ${#current_git_info}))

# Apply branch compression if needed
if [ $total_needed_space -gt $available_space_for_path_and_git ]; then
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "Space constraint detected: need $total_needed_space, have $available_space_for_path_and_git" >> "$debug_file"
    
    # Step 1: Check if directory contains branch name (existing logic - highest priority)
    if [ "$directory_contains_branch_result" = "true" ]; then
        # Hide branch completely if directory contains branch name
        current_git_info="$git_info_without_branch"
        branch_hidden=true
        branch_compression_applied=1
        [ "$STATUSLINE_DEBUG" = "1" ] && echo "Branch hidden (directory contains branch): '$current_git_info'" >> "$debug_file"
    else
        # Step 2: Compress the branch name itself (new priority)
        chars_to_save=$((total_needed_space - available_space_for_path_and_git))
        
        # Determine compression level based on how much we need to save
        if [ $chars_to_save -gt 15 ]; then
            compression_level=3  # Aggressive
        elif [ $chars_to_save -gt 8 ]; then
            compression_level=2  # Medium  
        else
            compression_level=1  # Light
        fi
        
        # Apply branch name compression
        if [ -n "$branch" ] && [ "$branch" != "detached" ]; then
            compressed_branch=$(compress_branch_name "$branch" "$compression_level")
            
            # Rebuild git_info with compressed branch
            if [ -n "$git_status" ]; then
                current_git_info=" ($compressed_branch $git_status)"
            else
                current_git_info=" ($compressed_branch)"
            fi
            
            branch_compression_applied=$compression_level
            [ "$STATUSLINE_DEBUG" = "1" ] && echo "Branch name compressed (level $compression_level): '$branch' -> '$compressed_branch', git_info: '$current_git_info'" >> "$debug_file"
        fi
    fi
    
    # Recalculate total needed space after branch compression
    total_needed_space=$((${#original_path} + ${#current_git_info}))
fi

# Update git_info with the compressed version
git_info="$current_git_info"

# PRIORITY 2: Path compression (only if still needed after branch compression)
# Calculate available space for path specifically
available_path_chars=$((available_space_for_path_and_git - ${#git_info}))

# Ensure minimum path space
min_path_chars=8
if [ $terminal_width -lt 40 ]; then
    min_path_chars=5  # Very narrow terminal
elif [ $terminal_width -lt 60 ]; then
    min_path_chars=6
fi

if [ $available_path_chars -lt $min_path_chars ]; then
    available_path_chars=$min_path_chars
fi

# Apply path compression if still needed
display_path=$(compress_path_dynamic "$original_path" "$available_path_chars")

# Final check: if we still don't fit and branch wasn't hidden, consider hiding it as last resort
final_total_space=$((${#display_path} + ${#git_info}))
if [ $final_total_space -gt $available_space_for_path_and_git ] && [ "$branch_hidden" = "false" ]; then
    # Even after compression, we still need more space - hide branch as absolute last resort
    git_info="$git_info_without_branch"
    branch_hidden=true
    branch_compression_applied=999  # Special value indicating emergency hiding
    [ "$STATUSLINE_DEBUG" = "1" ] && echo "Emergency branch hiding applied after compression failed: '$git_info'" >> "$debug_file"
fi

# Determine if we should show auto-compact message
show_auto_compact=""
if [ ${#original_path} -gt ${#display_path} ] && [ ${#original_path} -gt 30 ]; then
    # Only show auto-compact if we have enough terminal space and significant compression occurred
    if [ $terminal_width -gt 80 ] && [ $((${#original_path} - ${#display_path})) -gt 10 ]; then
        show_auto_compact=" [auto-compact]"
    fi
fi

# Debug output for branch-first compression
if [ "$STATUSLINE_DEBUG" = "1" ]; then
    echo "Branch-first compression analysis:" >> "$debug_file"
    echo "  Terminal width: $terminal_width" >> "$debug_file"
    echo "  Fixed elements length: $fixed_elements_length" >> "$debug_file"
    echo "  Auto-compact reserve: $auto_compact_reserve" >> "$debug_file"
    echo "  Available for path+git: $available_space_for_path_and_git" >> "$debug_file"
    echo "  Original path: '$original_path' (${#original_path} chars)" >> "$debug_file"
    echo "  Original git_info: '$git_info_with_branch' (${#git_info_with_branch} chars)" >> "$debug_file"
    echo "  Total needed initially: $((${#original_path} + ${#git_info_with_branch})) chars" >> "$debug_file"
    echo "Branch compression:" >> "$debug_file"
    echo "  Directory contains branch: $directory_contains_branch_result" >> "$debug_file"
    echo "  Branch compression applied: $branch_compression_applied" >> "$debug_file"
    echo "  Branch hidden: $branch_hidden" >> "$debug_file"
    echo "  Final git_info: '$git_info' (${#git_info} chars)" >> "$debug_file"
    echo "Path compression:" >> "$debug_file"
    echo "  Available for path after branch: $available_path_chars" >> "$debug_file"
    echo "  Final path: '$display_path' (${#display_path} chars)" >> "$debug_file"
    echo "  Show auto-compact: '$show_auto_compact'" >> "$debug_file"
    if [ "$original_path" != "$display_path" ]; then
        path_saved=$((${#original_path} - ${#display_path}))
        echo "  Path chars saved: $path_saved" >> "$debug_file"
    else
        echo "  No path compression applied" >> "$debug_file"
    fi
    if [ ${#git_info_with_branch} -gt ${#git_info} ]; then
        branch_saved=$((${#git_info_with_branch} - ${#git_info}))
        echo "  Branch chars saved: $branch_saved" >> "$debug_file"
    else
        echo "  No branch compression applied" >> "$debug_file"
    fi
    echo "  Final total space used: $((${#display_path} + ${#git_info})) chars" >> "$debug_file"
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
# Enhanced color scheme for better visual distinction:
# - Branch (git_info): Orange (\033[91m) - warm, stands out for git context
# - Time: Bright cyan (\033[96m) - cool, high visibility for time info
# - Port: Bright yellow (\033[93m) - maintained for good port visibility
# Auto-compact message in dim gray (\033[90m) to be subtle
printf "\033[36m%s\033[0m@\033[32m%s\033[0m \033[35m%s\033[0m\033[91m%s\033[0m \033[96m%s\033[0m\033[93m%s\033[0m\033[90m%s\033[0m | \033[34m%s\033[0m" \
    "$user" "$host" "$display_path" "$git_info" "$time" "$port_info" "$show_auto_compact" "$compressed_model"