#!/bin/sh
# SessionStart hook: tells Claude which launch alias matches this session's account,
# so suggested terminal commands use it instead of plain `claude`.
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

case ${cfg%/} in
"$HOME/.claude-two") alias=claude-two ;;
*) exit 0 ;;
esac

cat <<EOF
This session runs on the account launched by the \`$alias\` fish alias (CLAUDE_CONFIG_DIR=$cfg).
When telling the user to run a Claude Code CLI command in their terminal, write \`$alias ...\`, not \`claude ...\`; plain \`claude\` opens a different account.
Inside \`!\` commands or the Bash tool, use \`claude ...\`: the alias is fish-only, and \`claude\` already inherits this account's CLAUDE_CONFIG_DIR.
EOF
