if status is-interactive
  if ! type -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update
  end

  if type -q tide && ! $tide_right_prompt_frame_enabled
    tide configure --auto --style=Classic --prompt_colors='True color' --classic_prompt_color=Darkest --show_time='12-hour format' --classic_prompt_separators=Slanted --powerline_prompt_heads=Slanted --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=Yes --prompt_connection_andor_frame_color=Darkest --prompt_spacing=Compact --icons='Few icons' --transient=Yes
  end

  if type -q antidot
    antidot init | source
  end

  if type -q zoxide
    abbr --add cd z
  end

  if type -q fzf
    if type -q fd
      set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix'
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    end
    # onedark theme for fzf
    set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS --color=dark --color=fg:-1,bg:-1,hl:#c678dd,fg+:#ffffff,bg+:#4b5263,hl+:#d858fe --color=info:#98c379,prompt:#61afef,pointer:#be5046,marker:#e5c07b,spinner:#61afef,header:#61afef"
  end

  if type -q myfly && type -q myfly-fzf && type -q fzf
    mcfly init fish | source
    mcfly-fzf init fish | source
  end

  function scratch --description "Open a scratch pad in your editor for quick notes"
    set -l file "$(mktemp -t scratch).md"
    $EDITOR "$file"
    if [ ! -s "$file" ]
      rm -f "$file"
    else
      echo "$file"
    end
  end

  # send OSC 133 to mark prompt start
  function mark_prompt_start --on-event fish_prompt
    echo -en "\e]133;A\e\\"
  end


  function fish_greeting
  end

  function _zi
    zi
    clear
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
  bind \ch '_zi'
  # * CTRL-f -> fzf search for file and nvim
  bind \cf 'fzf-fd-nvim'
  # * CTRL-s -> fzf search for text and nvim
  bind \cs 'fzf-rg-nvim'
  # * CTRL-o -> use the scratch function
  bind \co 'scratch'
  # * CTRL-j -> find replace using sad?

end
