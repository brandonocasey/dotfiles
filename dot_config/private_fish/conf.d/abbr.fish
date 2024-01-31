# Ask before over-writing a file
abbr --add mv mv -iv

# Ask before deleting a file, and automatically make it recursive
abbr --add rm rm -riv

# Ask before over-writing a file and recursively copy by default
abbr --add cp cp -irv

# We want free disc space in human readable output, trust me
abbr --add df df -h

# Automatically make directories recursively
abbr --add mkdir mkdir -pv

abbr --add gs git status

# Vim misspellings
abbr --add vim nvim
abbr --add cim nvim
abbr --add bim nvim
abbr --add fim nvim
abbr --add gim nvim
abbr --add vi nvim
abbr --add vimdiff nvim -d
abbr --add nvimdiff nvim -d

if type -q s
  abbr --add s s --provider duckduckgo
  abbr --add web-search s --provider duckduckgo
end

if type -q chezmoi
  abbr --add cm chezmoi
end

# use coreutils ls if it exists
if type -q eza
  alias ls 'eza'
  alias ll 'ls -l --git --icons --time-style=long-iso'
  alias la 'll -ah'
  alias la_size 'la --total-size'
  alias ll_size 'll --total-size'
  alias la_tree 'la --tree'
  alias ll_tree 'll --tree'
  alias ls_tree 'eza --tree'
  alias tree 'lstree'
else
  if [ "$UNAME" = 'Darwin' ] && ! type -q gls
    # Show me all files and info about them
    abbr --add ll ls -lh --color=auto

    # Show me all files, including .dotfiles, and all info about them
    abbr --add la ls -lha --color=auto

    # Show me colors for regular ls too
    abbr --add ls ls --color=auto
  else
    set -l lsbin ls

    if type -q gls
      set lsbin gls
    end

    abbr --add ls "$lsbin" --color=auto
    # Show me all files and info about them
    abbr --add ll "$lsbin" -lh --color=auto
    # Show me all files, including .dotfiles, and all info about them
    abbr --add la "$lsbin" -lha --color=auto
  end
end

if type -q s
  abbr --add s s --provider duckduckgo
  abbr --add web-search s --provider duckduckgo
end

#abbr --add brewup brew update; brew upgrade; brew cleanup; brew doctor'

# abbr --add grep grep --color="always"'
#
# # easy mysql connection just tack on a -h
# abbr --add sql mysql -umysql -pmysql'
#
# # easy mysql dump just tack on a -h
# abbr --add sqld mysqldump -umysql -pmysql --routines --single-transaction'
#
# # reverse a string
# alias reverse="perl -e 'print reverse <>'"
#
# # go to root git directory
# abbr --add cdgitroot cd "$(git rev-parse --show-toplevel)"'
#
# node module bs
alias npmre="rm -rf ./node_modules && npm i"
alias npmrews="rm -rf 'packages/**/node_modules' && npmre"

# node workspace module bs
alias npmrere="rm -f ./package-lock.json && npmre"
alias npmrerews="rm -rf 'packages/**/node_modules' && npmre"

#
# # keep env when going sudo
# abbr --add sudo sudo --preserve-env'
#
# if cmd_exists rlwrap; then
#   abbr --add telnet rlwrap telnet'
# fi
#
# if cmd_exists multitail; then
#   abbr --add tail multitail'
# else
#   abbr --add tail tail -f'
# fi
