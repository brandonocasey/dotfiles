if status is-interactive
    if type -q zoxide
        abbr --add cd z
    end

    function journal -a filename --description "Open a journal entry in your editor for quick notes"
        if [ -z "$filename" ]
            set filename default
        end
        if [ (path extension "$filename") != '.md' ]
            set filename "$filename.md"
        end
        set -l journal_dir "$XDG_DATA_HOME/journal"
        if [ ! -d "$journal_dir" ] && [ -d "$HOME/Journal" ]
            set journal_dir "$HOME/Journal"
        end
        if [ ! -d "$journal_dir" ]
            mkdir -p "$journal_dir"
        end

        set -l file "$journal_dir/$filename"
        $EDITOR "$file"
        if [ ! -s "$file" ]
            rm -f "$file"
        end
    end

    # LazyVim.pick opens LazyVim's configured picker (Snacks by default).
    function fzf-fd-nvim -a cwd --description "Open nvim to the file picker"
        if [ -z "$cwd" ] || [ ! -d "$cwd" ]
            set cwd "$(find-root)"
        end
        nvim -c "cd $cwd" -c "lua LazyVim.pick('files', { root = false })()"
    end

    function fzf-rg-nvim -a cwd --description "Open nvim to the live grep picker"
        if [ -z "$cwd" ] || [ ! -d "$cwd" ]
            set cwd "$(find-root)"
        end
        nvim -c "cd $cwd" -c "lua LazyVim.pick('live_grep', { root = false })()"
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
        # macOS: read/store passphrases in the login keychain so reloads after
        # a reboot don't prompt (falls back to a prompt if it's locked).
        set -l keychain_flag
        if test (uname) = Darwin
            set keychain_flag --apple-use-keychain
        end
        for file in (grep -slR "PRIVATE" $HOME/.ssh/ | sort)
            if not string match -q (string join '' '*' (ssh-keygen -lf "$file") '*') "$existing_keys"
                # 2592000 seconds = 30 days
                ssh-add $keychain_flag -t 2592000 "$file"
            end
        end
    end

    # suppress welcome to fish
    function fish_greeting
    end

    # Only walk ~/.ssh when the agent has no identities loaded; once keys are
    # added (with a 30-day expiry) later shells skip the grep/ssh-keygen scan.
    # Keys are pulled/refreshed from the Bitwarden vault via setup-bw-ssh-keys.
    if not ssh-add -l >/dev/null 2>&1
        add_all_ssh_identities
    end

    if type -q vibetree
        vibetree shell init fish | source
    end
    alias claude-two="CLAUDE_CONFIG_DIR=~/.claude-two claude"
end
