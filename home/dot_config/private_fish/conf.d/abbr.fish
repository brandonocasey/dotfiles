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
  alias la 'll -ah'

  alias la-size 'la --total-size'
  alias ll-size 'll --total-size'

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

if type -q s
  abbr --add s s --provider duckduckgo
  abbr --add web-search s --provider duckduckgo
end

if type -q curlie
  abbr --add curl curlie
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
# # go to root git directory
# abbr --add cdgitroot cd "$(git rev-parse --show-toplevel)"'
#
# node module bs

function find-up -a filename cwd --description "Find a specific file, searching recursibly above the cwd"
  if [ -z "$filename" ]
    echo "Usage find-up <filename>"
    return 1
  end

  if [ -z "$cwd" ]
    set cwd "$PWD"
  end

  if [ -f "$cwd/$filename" ] || [ -d "$cwd/$filename" ]
    echo "$cwd"
    return 0
  end

  if [ -z "$cwd" ] || [ "$cwd" = "/" ] || [ "$cwd" = "." ]
    return 1
  end

  find-up "$filename" "$(dirname "$cwd")"
  return $status
end

function find-root --description "Find the root of a git directory or package, defaults to PWD"
  set -l dir "" 
  for test in .git package.json
    set dir $(find-up "$test")
    if [ -n "$dir" ] && [ -d "$dir" ]
      echo "$dir"
      return
    end
  end
  echo "$PWD"
end


function npmre --description "remove ./node_modules and reinstall"
  set -l tmpdir $(mktemp -d)
  mkdir -p "$tmpdir"
  if [ -d "./node_modules" ]
    echo "Removing ./node_modules"
    mv ./node_modules "$tmpdir" 
  end

  rm -rf "$tmpdir" &
  disown
  npm i 
end

function npmrere --description "Remove ./node_modules && ./package-lock.json and reinstall"
  echo 'Removing ./package-lock.json' 
  rm -f ./package-lock.json 
  npmre
end

function npmlsws --description "print all workspace directories"
  set -l workspaces $(node -e "console.log(require(`./package.json`).workspaces.join(`\n`))")
  for w in $workspaces
    eval "set -l dirs $w" 
    for d in $dirs 
      echo $d
    end
  end
end

function npmrews --description "Remove all workspace node_modules and reinstall"
  set -l tmpdir $(mktemp -d)
  mkdir -p "$tmpdir"
  for d in $(npmlsws)
    if [ -d "$d/node_modules" ]
      echo "Removing $d/node_modules"
      mkdir -p "$tmpdir/$d"
      mv $d/node_modules "$tmpdir/$d/node_modules"
    end
  end
  rm -rf "$tmpdir" &
  disown
  npmre
end

# move things to a temp dir and then remove that temp dir
function npmrerews --description "Remove all workspace node_modules/package-lock and reinstall"
  for d in $(npmlsws)
    if [ -f "$d/package-lock.json" ]
      echo "Removing $d/package-lock.json"
      rm -f $d/package-lock.json
    end
  end

  if [ -f "./package-lock.json" ]
    echo "Removing ./package-lock.json"
  end
  disown
  npmrews
end

function nvim-x -a filename --description "Create the file as an executable and then enter with nvim"
  touch "$filename"
  chmod +x "$filename"
  nvim "$filename"
  if ! test -s "$filename"
    rm -f $filename
    echo "removing empty file $filename"
  end
end


alias docker-compose-update 'docker-compose pull && docker-compose up --force-recreate --build -d && docker image prune -f'

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
