# Fish completion for claude-worktree

# Complete branch names for --clean (only existing worktrees/branches)
function __claude_worktree_existing_branches
    # Get branches that have corresponding worktrees
    if git rev-parse --git-dir >/dev/null 2>&1
        set repo_name (basename (git rev-parse --show-toplevel))
        set parent_dir (dirname (git rev-parse --show-toplevel))
        
        for branch in (git branch --format='%(refname:short)' 2>/dev/null)
            set worktree_dir "$parent_dir/$repo_name-$branch"
            if test -d "$worktree_dir"
                echo $branch
            end
        end
    end
end

# Complete feature names (any valid branch name or new feature name)
function __claude_worktree_all_branches
    if git rev-parse --git-dir >/dev/null 2>&1
        git branch --format='%(refname:short)' 2>/dev/null
    end
end

# Complete options
complete -c claude-worktree -s h -l help -d "Show help message"
complete -c claude-worktree -l clean -d "Remove worktree, branch, and localias" -xa "(__claude_worktree_existing_branches)"

# Complete feature names for the main argument
complete -c claude-worktree -f -n "not __fish_seen_subcommand_from --clean" -xa "(__claude_worktree_all_branches)"