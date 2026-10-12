#!/bin/sh
# UserPromptSubmit hook: lets `$skill-name` in a prompt invoke that skill, like Codex.
# A token counts when it names a skill on disk, or when it starts the prompt
# (covers bundled skills with no SKILL.md on disk; those run only if listed).
input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

case $prompt in
*'$'[a-z]*) ;;
*) exit 0 ;;
esac

# Prints the SKILL.md path for a skill name, or nothing.
skill_path() {
  name=${1#*:}
  for root in "$cwd/.claude/skills" "$cfg/skills" "$HOME/.config/agents/skills"; do
    [ -f "$root/$name/SKILL.md" ] && { printf '%s\n' "$root/$name/SKILL.md"; return; }
  done
  find "$cfg/plugins" -path "*/skills/$name/SKILL.md" 2>/dev/null | head -n 1
}

# Drop code blocks, inline code, and quoted text so `$x` there stays literal.
# Single quotes count only at word edges, so apostrophes (don't) survive.
prompt=$(printf '%s' "$prompt" | perl -0777 -pe '
  s/```.*?(```|\z)//gs;
  s/`[^`]*`//g;
  s/"[^"]*"//g;
  s/\x{201C}[^\x{201D}]*\x{201D}//g;
  s/(^|\s)\x27[^\x27]*\x27(?!\w)/$1/g;
' -CSD)

first=$(printf '%s' "$prompt" | sed -n '1s/^[[:space:]]*\$\([a-z][a-z0-9_:-]*\).*/\1/p')
names=$(printf '%s\n' "$prompt" | grep -oE '(^|[[:space:]])\$[a-z][a-z0-9_-]*(:[a-z0-9_-]+)?' |
  sed 's/^[[:space:]]*\$//' | awk '!seen[$0]++')

ctx=
for name in $names; do
  path=$(skill_path "$name")
  [ -n "$path" ] || [ "$name" = "$first" ] || continue
  line="- \`\$$name\`: invoke skill \`$name\` with the Skill tool"
  if [ -n "$path" ]; then
    line="$line; if it is not in the Skill listing, read $path whole and follow it"
  else
    line="$line only if it is in the Skill listing; otherwise ignore this line and treat \`\$$name\` as plain text"
  fi
  ctx="$ctx
$line"
done
[ -n "$ctx" ] || exit 0

jq -n --arg ctx "The user invoked skills with \$ syntax. Treat each as if they typed /<name>, before other work. Pass the rest of the prompt as args.$ctx" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
