if status is-interactive
    if type -q tide && ! $tide_right_prompt_frame_enabled
        fish -c "tide configure --auto --style=Classic --prompt_colors='True color' --classic_prompt_color=Darkest --show_time='12-hour format' --classic_prompt_separators=Slanted --powerline_prompt_heads=Slanted --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Dotted --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Few icons' --transient=Yes"
    end

    if type -q zoxide
        abbr --add cd z
    end

    if type -q fzf
        if type -q fd
            set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix'
            set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        end
    end

    function journal -a filename --description "Open a journal entry in your editor for quick notes"
        if [ -z "$filename" ]
            set filename default
        end
        if [ (path extension "$filename") != '.md' ]
            set filename "$filename.md"
        end
        set -l file "$HOME/Journal/$filename"
        if [ ! -d "$HOME/Journal" ]
            mkdir -p "$HOME/Journal"
        end

        $EDITOR "$file"
        if [ ! -s "$file" ]
            rm -f "$file"
        end
    end

    # send OSC 133 to mark prompt start
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    function fzf-fd-nvim -a cwd --description "Open nvm to Telescope find_files selector"
        if [ -z "$cwd" ] || [ ! -d "$cwd" ]
            set cwd "$(find-root)"
        end
        nvim -c "cd $cwd" -c "Telescope find_files"
    end

    function fzf-rg-nvim -a cwd --description "Open nvm to Telescope live_grep selector"
        if [ -z "$cwd" ] || [ ! -d "$cwd" ]
            set cwd "$(find-root)"
        end
        nvim -c "cd $cwd" -c "Telescope live_grep"
    end

    # * keybinds
    # * CTRL-h -> fzf Change directory
    bind \ch zi
    # * CTRL-f -> fzf search for file and nvim
    bind \cf fzf-fd-nvim
    # * CTRL-s -> fzf search for text and nvim
    bind \cs fzf-rg-nvim
    # * CTRL-o -> use the scratch function
    bind \co scratch
    # * CTRL-j -> find replace using sad?

    function add_all_ssh_identities -d "Add ssh identities"
        set -l existing_keys (ssh-add -l)
        for file in (grep -slR "PRIVATE" $HOME/.ssh/ | sort)
            if not string match -q (string join '' '*' (ssh-keygen -lf "$file") '*') "$existing_keys"
                # 2592000 seconds = 30 days
                ssh-add -t 2592000 "$file"
            end
        end
    end

    # suppress welcome to fish
    function fish_greeting
    end

    add_all_ssh_identities

    if type -q vibetree
        vibetree shell init fish | source
    end
    alias claude-two="CLAUDE_CONFIG_DIR=~/.claude-two claude"
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/bcasey/.lmstudio/bin
# End of LM Studio CLI section
