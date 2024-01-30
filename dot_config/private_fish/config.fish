if status is-interactive
  if ! type -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update
  end

  if type -q tide && ! set -q -U tide_right_prompt_frame_enabled
    tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Slanted --powerline_prompt_heads=Slanted --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=Yes --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Few icons' --transient=Yes
  end

  if type -q brew && test -f $HOMEBREW_PREFIX/etc/brew-wrap.fish
    source $HOMEBREW_PREFIX/etc/brew-wrap.fish
    set -gx HOMEBREW_BREWFILE_LEAVES 1
    set -gx HOMEBREW_BREWFILE_TOP_PACKAGES 1
  end

  if type -q zoxide
    zoxide init fish | source
    abbr --add cd z
  end

  if type -q fzf and type -q fd
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  end


  function fish_greeting
    echo "----"
    echo "Remember to use web-search, btop, ctop, fzf, jq, entr, zi, navi, fd, bat, grex (regex gen), parallel"
    echo "----"
  end

end
