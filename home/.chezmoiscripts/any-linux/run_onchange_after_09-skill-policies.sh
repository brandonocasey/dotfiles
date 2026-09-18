#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin"

skill_dir="$(
  gh skill list --agent codex --scope user --json skillName,path \
    --jq '.[] | select(.skillName == "frontend-design") | .path'
)"

if [[ -z "$skill_dir" || ! -f "$skill_dir/SKILL.md" ]]; then
  echo "frontend-design must be installed before setting its policy." >&2
  exit 1
fi

policy_dir="$skill_dir/agents"
policy_file="$policy_dir/openai.yaml"
mkdir -p "$policy_dir"
policy_temp="$(mktemp "$policy_dir/.openai.yaml.XXXXXX")"
trap 'rm -f "$policy_temp"' EXIT

{
  if [[ -s "$policy_file" ]]; then
    cat "$policy_file"
  else
    printf '{}\n'
  fi
} | chezmoi execute-template --with-stdin \
  '{{ .chezmoi.stdin | fromYaml | setValueAtPath "policy.allow_implicit_invocation" false | toYaml }}' \
  > "$policy_temp"

if ! cmp -s "$policy_temp" "$policy_file"; then
  mv "$policy_temp" "$policy_file"
fi
