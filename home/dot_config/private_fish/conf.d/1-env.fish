
if test -z "$UNAME"
  set -gx UNAME $(uname)
end

if test -z "$XDG_DATA_HOME"
  set -gx XDG_DATA_HOME "$HOME/.local/share"
end


if test -z "$XDG_CONFIG_HOME"
  set -gx XDG_CONFIG_HOME "$HOME/.config"
end

if test -z "$XDG_STATE_HOME"
  set -gx XDG_STATE_HOME "$HOME/.local/state"
end

if test -z "$XDG_CACHE_HOME"
  set -gx XDG_CACHE_HOME "$HOME/.cache"
end

if [ $UNAME = Darwin ]
  set -gx MACPREFS_BACKUP_DIR "$XDG_DATA_HOME/macprefs/"
end

# TODO: do we need this?
if test -z "$XDG_RUNTIME_DIR"
  if test $UNAME = 'Darwin'
    set -gx XDG_RUNTIME_DIR "$HOME/Library/Application Support"
  else if test $UNAME = 'Linux'
    set -gx XDG_RUNTIME_DIR "/run/user/$(id -u)"
  end
end

if ! set -q MANPATH
  set -gx MANPATH ''
end

if ! set -q INFOPATH
  set -gx INFOPATH
end

for brew_location in "/usr/local" "/opt/homebrew" "/home/linuxbrew/.linuxbrew"
  if [ -s "$brew_location/bin/brew" ]
    set -gx HOMEBREW_PREFIX "$brew_location";
    set -gx HOMEBREW_CELLAR "$brew_location/Cellar";
    set -gx HOMEBREW_REPOSITORY "$brew_location/Homebrew";
    fish_add_path -a "$brew_location/bin"
    fish_add_path -a "$brew_location/sbin"

    if ! contains "$brew_location/share/man" $MANPATH
      set -gx MANPATH "$brew_location/share/man" $MANPATH
    end

    if ! contains "$brew_location/share/info" $INFOPATH
      set -gx INFOPATH "$brew_location/share/info" $INFOPATH
    end
    break;
  end
end

fish_add_path -a "$HOME/.local/bin"
set -gx PATH $PATH ./node_modules/.bin

set -gx EDITOR nano
# Set default command editor to vim
if type -q nvim
  set -gx MANPAGER "nvim +Man!"
  set -gx EDITOR nvim
else if type -q vim; then
  set -gx EDITOR vim
else if type -q vi; then
  set -gx EDITOR vi
end

set -gx FCEDIT $EDITOR
set -gx VISUAL $EDITOR
set -gx VISUAL_EDITOR $EDITOR
set -gx SVN_EDITOR $EDITOR
set -gx GIT_EDITOR $EDITOR

# themed ls colors
if type -q vivid
  set -gx LS_COLORS "$(vivid generate one-dark)"
else
  set -gx LSCOLORS GxFxCxDxBxegedabagaced
end

# XDG config location overrides
set -gx ANDROID_USER_HOME "$XDG_DATA_HOME/android"
set -gx DOCKER_CONFIG "$XDG_CONFIG_HOME/docker"
set -gx GNUPGHOME "$XDG_DATA_HOME/gnupg"
set -gx LESSHISTFILE "$XDG_CACHE_HOME/less/history"
set -gx NODE_REPL_HISTORY "$XDG_DATA_HOME/node_repl_history"
set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
set -gx PGPASSFILE "$XDG_CONFIG_HOME/pg/pgpass"
set -gx GEM_HOME "$XDG_DATA_HOME/gem"
set -gx GEM_SPEC_CACHE "$XDG_CACHE_HOME/gem"
set -gx MYSQL_HISTFILE "$XDG_DATA_HOME/mysql_history"
set -gx XAUTHORITY "$XDG_RUNTIME_DIR/Xauthority"
set -gx KODI_DATA "$XDG_DATA_HOME/kodi"
set -gx WGETRC "$XDG_CONFIG_HOME/wgetrc"

# set -gx GVIMINIT 'let $MYGVIMRC = !has("nvim") ? "$XDG_CONFIG_HOME/vim/gvimrc" : "$XDG_CONFIG_HOME/nvim/init.gvim" | so $MYGVIMRC'
set -gx VIMINIT 'let $MYVIMRC = !has("nvim") ? "$XDG_CONFIG_HOME/vim/vimrc" : "$XDG_CONFIG_HOME/nvim/init.lua" | so $MYVIMRC'

set -gx BUNDLE_USER_CONFIG "$XDG_CONFIG_HOME/bundle"
set -gx BUNDLE_USER_CACHE "$XDG_CACHE_HOME/bundle"
set -gx BUNDLE_USER_PLUGIN "$XDG_DATA_HOME/bundle"
set -gx INPUTRC "$XDG_CONFIG_HOME/readline/inputrc"

set -gx PYTHONSTARTUP "$XDG_CONFIG_HOME/python/pythonrc"
set -gx RIPGREP_CONFIG_PATH "$XDG_CONFIG_HOME/ripgrep/config"

# finding things
set -gx GREP_OPTIONS "--color=auto"
set -gx BAT_THEME "TwoDark"
