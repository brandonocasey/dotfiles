# shellcheck shell=sh

# Shared environment for POSIX shells. Fish mirrors these values in
# conf.d/1-env.fish because Fish cannot source POSIX shell syntax.

if [ -z "${XDG_DATA_HOME:-}" ]; then
	export XDG_DATA_HOME="$HOME/.local/share"
fi

if [ -z "${XDG_CONFIG_HOME:-}" ]; then
	export XDG_CONFIG_HOME="$HOME/.config"
fi

if [ -z "${XDG_STATE_HOME:-}" ]; then
	export XDG_STATE_HOME="$HOME/.local/state"
fi

if [ -z "${XDG_CACHE_HOME:-}" ]; then
	export XDG_CACHE_HOME="$HOME/.cache"
fi

if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
	case "$(uname -s 2>/dev/null)" in
	Darwin)
		export XDG_RUNTIME_DIR="$HOME/Library/Application Support"
		;;
	Linux)
		runtime_dir="/run/user/$(id -u)"
		if [ -d "$runtime_dir" ] && [ -w "$runtime_dir" ]; then
			export XDG_RUNTIME_DIR="$runtime_dir"
		else
			export XDG_RUNTIME_DIR="$XDG_CACHE_HOME/xdg-runtime"
			mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
		fi
		;;
	esac
fi

_shell_path_prepend() {
	_shell_path_remove "$1"
	PATH="$1${PATH:+:$PATH}"
}

_shell_path_remove() {
	case ":${PATH:-}:" in
	*":$1:"*)
		PATH="$(printf '%s' "${PATH:-}" | awk -v RS=: -v ORS=: -v target="$1" '$0 != target')"
		PATH="${PATH%:}"
		;;
	esac
}

_shell_path_append() {
	_shell_path_remove "$1"
	PATH="${PATH:+$PATH:}$1"
}

_shell_path_remove './node_modules/.bin'
_shell_path_remove '/Users/bcasey/.lmstudio/bin'

# Local wrappers must win over Homebrew binaries.
_shell_path_prepend "$HOME/.local/bin"

if [ -d "$HOME/.cargo/bin" ]; then
	_shell_path_append "$HOME/.cargo/bin"
fi

if [ -d "$XDG_DATA_HOME/npm/bin" ]; then
	_shell_path_append "$XDG_DATA_HOME/npm/bin"
fi

if [ -d "$HOME/bin" ]; then
	_shell_path_append "$HOME/bin"
fi

if [ -d "$HOME/.lmstudio/bin" ]; then
	_shell_path_append "$HOME/.lmstudio/bin"
fi

for brew_location in /usr/local /opt/homebrew "$HOME/.linuxbrew" \
	"/home/linuxbrew/.linuxbrew"; do
	if [ -x "$brew_location/bin/brew" ]; then
		export HOMEBREW_PREFIX="$brew_location"
		export HOMEBREW_CELLAR="$brew_location/Cellar"
		export HOMEBREW_REPOSITORY="$brew_location/Homebrew"
		_shell_path_append "$brew_location/bin"
		_shell_path_append "$brew_location/sbin"
		if [ -d "$brew_location/opt/python/libexec/bin" ]; then
			_shell_path_append "$brew_location/opt/python/libexec/bin"
		fi
		if [ -d "$brew_location/opt/trash/bin" ]; then
			_shell_path_append "$brew_location/opt/trash/bin"
		fi
		break
	fi
done

export PATH
unset -f _shell_path_prepend _shell_path_append _shell_path_remove

if command -v brew >/dev/null 2>&1; then
	_brew_manpath="${HOMEBREW_PREFIX:-$(brew --prefix)}/share/man"
	_brew_infopath="${HOMEBREW_PREFIX:-$(brew --prefix)}/share/info"
	case ":${MANPATH:-}:" in
	*":$_brew_manpath:"*) ;;
	*) MANPATH="$_brew_manpath:${MANPATH:-}" ;;
	esac
	case ":${INFOPATH:-}:" in
	*":$_brew_infopath:"*) ;;
	*) INFOPATH="$_brew_infopath:${INFOPATH:-}" ;;
	esac
	export MANPATH INFOPATH
fi

export PAGER="${PAGER:-less}"
export GIT_PAGER="${GIT_PAGER:-less}"
if command -v delta >/dev/null 2>&1; then
	export GIT_PAGER=delta
elif command -v bat >/dev/null 2>&1; then
	export PAGER=bat
	export GIT_PAGER=bat
fi

if [ -z "${EDITOR:-}" ]; then
	if command -v nvim >/dev/null 2>&1; then
		export EDITOR=nvim
		export MANPAGER='nvim +Man!'
	elif command -v vim >/dev/null 2>&1; then
		export EDITOR=vim
	elif command -v vi >/dev/null 2>&1; then
		export EDITOR=vi
	else
		export EDITOR=nano
	fi
fi

if [ -z "${MANPAGER:-}" ] && [ "$EDITOR" = nvim ]; then
	export MANPAGER='nvim +Man!'
fi

export FCEDIT="$EDITOR"
export VISUAL="${VISUAL:-$EDITOR}"
export VISUAL_EDITOR="${VISUAL_EDITOR:-$EDITOR}"
export SVN_EDITOR="${SVN_EDITOR:-$EDITOR}"
export GIT_EDITOR="${GIT_EDITOR:-$EDITOR}"

# These variables keep tools that do not implement XDG discovery in the same
# locations in Bash and Fish.
export ANDROID_USER_HOME="$XDG_DATA_HOME/android"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export LESSHISTFILE="$XDG_CACHE_HOME/less/history"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"
export GEM_HOME="$XDG_DATA_HOME/gem"
export GEM_SPEC_CACHE="$XDG_CACHE_HOME/gem"
export MYSQL_HISTFILE="$XDG_DATA_HOME/mysql_history"
export KODI_DATA="$XDG_DATA_HOME/kodi"
export WGETRC="$XDG_CONFIG_HOME/wgetrc"
export VALE_CONFIG_PATH="$XDG_CONFIG_HOME/vale/.vale.ini"
export VALE_STYLES_PATH="$XDG_DATA_HOME/vale/styles"
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
export VACUUM="$XDG_CONFIG_HOME/vacuum/config.yaml"
export VIMINIT="let \$MYVIMRC = !has(\"nvim\") ? \"\$XDG_CONFIG_HOME/vim/vimrc\" : \"\$XDG_CONFIG_HOME/nvim/init.lua\" | so \$MYVIMRC"
export BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME/bundle"
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle"
export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle"
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export PASSWORD_STORE_DIR="$XDG_DATA_HOME/pass"
export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"

if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
	export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"
fi

if [ -z "${GPG_TTY:-}" ]; then
	GPG_TTY="$(tty 2>/dev/null || true)"
	export GPG_TTY
fi

if [ -d "$XDG_DATA_HOME/wasi-sdk" ]; then
	export WASI_SDK_PATH="$XDG_DATA_HOME/wasi-sdk"
fi

if command -v fd >/dev/null 2>&1; then
	export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
	export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

if command -v vivid >/dev/null 2>&1; then
	LS_COLORS="$(vivid generate one-dark)"
	export LS_COLORS
else
	export LSCOLORS=GxFxCxDxBxegedabagaced
fi

export BAT_THEME="${BAT_THEME:-OneHalfDark}"
export LESS="${LESS:--R}"
export LANG="${LANG:-en_US.UTF-8}"
