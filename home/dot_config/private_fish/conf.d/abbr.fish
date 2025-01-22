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
abbr --add gd git diff
abbr --add gp git push
abbr --add gl git log

abbr --add l ls
abbr --add g git

# Vim misspellings
abbr --add vim $EDITOR
abbr --add cim $EDITOR
abbr --add bim $EDITOR
abbr --add fim $EDITOR
abbr --add gim $EDITOR
abbr --add vi $EDITOR
abbr --add v $EDITOR
alias vim $EDITOR

if [ $EDITOR = 'nvim' ]
  abbr --add vimdiff nvim -d
  abbr --add nvimdiff nvim -d
end

if type -q s
  abbr --add s s --provider duckduckgo
  abbr --add web-search s --provider duckduckgo
end

if type -q chezmoi
  abbr --add cm chezmoi
end

# use eza if it exists
if type -q eza
  alias ls 'eza'
  alias ll 'ls -l --git --icons --time-style=long-iso'
  alias la 'll -ahoH'

  alias la-size 'la --total-size'
  alias ll-size 'll --total-size'
  alias lh 'la-size'

  alias la-tree 'la --tree'
  alias ll-tree 'll --tree'

  alias tree 'ls-tree'
  alias ls-tree 'eza --tree'
else
  set -l lsbin ls
  # use coreutils ls if it exists
  if type -q gls
    set lsbin gls
  end

  # ls with color
  alias ls "$lsbin --color=auto"
  # Show me all files and info about them
  alias ll "ls -lh --color=auto"
  # Show me all files, including .dotfiles, and all info about them
  alias la "$lsbin -lha --color=auto"
end

if type -q curlie
  abbr --add curl curlie
end

if type -q bat
  abbr --add cat bat
end


if type -q duf
  abbr --add disk-info duf
  abbr --add disc-info duf
end

if type -q dust
  abbr --add file-sizes dust
  abbr --add sizes dust
  abbr --add tree-size dust
end

if type -q btm
  abbr --add htop btm -b
  abbr --add top btm -b
end

if type -q wget2
  abbr --add wget wget2
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
#
# node module bs


alias docker-compose-update 'docker-compose pull && docker-compose up --force-recreate --build -d && docker image prune -f'

abbr --add cdroot cd "$(find-root)"

if [ (uname) = 'Darwin' ]
  alias ollama:start='sudo launchctl load /Library/LaunchDaemons/ollama.plist'
  alias ollama:stop='sudo launchctl unload /Library/LaunchDaemons/ollama.plist'
end

#
# # keep env when going sudo
# abbr --add sudo sudo --preserve-env'
#
# if type -q rlwrap; then
#   abbr --add telnet rlwrap telnet'
# fi
#
# if type -q multitail; then
#   abbr --add tail multitail'
# else
#   abbr --add tail tail -f'
# fi
