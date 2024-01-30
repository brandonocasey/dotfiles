if status is-interactive
  if ! type -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update
  end

  if type -q tide && ! set -q -U tide_right_prompt_frame_enabled
    tide configure --auto --style=Classic --prompt_colors='True color' --classic_prompt_color=Darkest --show_time='12-hour format' --classic_prompt_separators=Slanted --powerline_prompt_heads=Slanted --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=Yes --prompt_connection_andor_frame_color=Darkest --prompt_spacing=Compact --icons='Few icons' --transient=Yes
  end

  if type -q zoxide
    zoxide init fish | source
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

  if type -q myfly and type -q myfly-fzf and type -q fzf
    mcfly init fish | source
    mcfly-fzf init fish | source
  end

  function fish_greeting
  end

  fish_add_path -a "$HOME/.local/bin"

end
