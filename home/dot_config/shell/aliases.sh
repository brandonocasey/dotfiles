# shellcheck shell=sh

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gp='git push'
alias gl='git log'
alias l='ls'

if command -v eza >/dev/null 2>&1; then
	alias ls='eza'
	alias ll='eza -l --git --icons --time-style=long-iso'
	alias la='eza -la --git --icons --time-style=long-iso'
	alias tree='eza --tree'
elif command -v gls >/dev/null 2>&1; then
	alias ls='gls --color=auto'
	alias ll='gls -lh --color=auto'
	alias la='gls -lha --color=auto'
elif [ "$(uname -s 2>/dev/null)" = Darwin ]; then
	alias ls='ls -G'
	alias ll='ls -lh -G'
	alias la='ls -lha -G'
else
	alias ls='ls --color=auto'
	alias ll='ls -lh --color=auto'
	alias la='ls -lha --color=auto'
fi

if command -v bat >/dev/null 2>&1; then
	alias cat='bat'
fi

if command -v curlie >/dev/null 2>&1; then
	alias curl='curlie'
fi

if command -v wget2 >/dev/null 2>&1; then
	alias wget='wget2'
fi

if command -v chezmoi >/dev/null 2>&1; then
	alias cm='chezmoi'
fi

case "$(uname -s 2>/dev/null)" in
Darwin)
	if command -v ggrep >/dev/null 2>&1; then
		alias grep='ggrep --color=auto'
		alias fgrep='ggrep --color=auto -F'
		alias egrep='ggrep --color=auto -E'
	fi
	;;
*)
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
	;;
esac

if command -v notify-send >/dev/null 2>&1; then
	alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
fi

alias vim='${EDITOR:-vi}'
alias vi='${EDITOR:-vi}'
alias cim='${EDITOR:-vi}'
alias bim='${EDITOR:-vi}'
alias fim='${EDITOR:-vi}'
alias gim='${EDITOR:-vi}'

if [ "${EDITOR:-}" = nvim ]; then
	alias vimdiff='nvim -d'
	alias nvimdiff='nvim -d'
fi

alias docker-compose-update='docker-compose pull && docker-compose up --force-recreate --build -d && docker image prune -f'
alias cdroot='cd "$(find-root)"'
