if type -q asdf
  # direnv add-ins
  set -gx ASDF_DIRENV_IGNORE_MISSING_PLUGINS 1
  set -gx DIRENV_LOG_FORMAT ""
  set -gx ASDF_DIRENV_NO_TOUCH_RC_FILE 1

  if test -z "$ASDF_DIR"
    if test -f ~/.asdf/asdf.fish
      set -gx ASDF_DIR ~/.asdf
      if test -f $ASDF_DIR/completions/asdf.fish -a not -L ~/.config/fish/completions/asdf.fish
        if not test -d ~/.config/fish/completions
          mkdir -p ~/.config/fish/completions
        end
        ln -s $ASDF_DIR/completions/asdf.fish ~/.config/fish/completions/asdf.fish
      end

    else if test -n "$HOMEBREW_PREFIX" -a -f $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.fish
      set -gx ASDF_DIR $HOMEBREW_PREFIX/opt/asdf/libexec
    end
  end

  if test -n "$ASDF_DIR"
    if test -z "$ASDF_DATA_DIR"
      if test -n "$XDG_DATA_HOME"
        set -gx ASDF_DATA_DIR $XDG_DATA_HOME/asdf
      else
        set -gx ASDF_DATA_DIR ~/.config/asdf/asdfrc
      end
    end

    if test -z "$ASDF_CONFIG_FILE"
      if test -n "$XDG_CONFIG_HOME"
        set -gx ASDF_CONFIG_FILE ~/.config/asdf/asdfrc
      else
        set -gx ASDF_CONFIG_FILE ~/.local/share/asdf/asdfrc
      end
    end

    if test -f $ASDF_DIR/asdf.fish
      #source $ASDF_DIR/asdf.fish
    else if test -f $ASDF_DIR/libexec/asdf.fish
      #source $ASDF_DIR/libexec/asdf.fish
    end
  end

end
