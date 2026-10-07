#!/bin/bash
# chezmoi modify_ script, shared by ~/.claude and ~/.claude-two via .chezmoitemplates. It reads the live settings.json on stdin and
# prints the file chezmoi should apply. Every key below is enforced from this
# file EXCEPT the ones in KEEP_KEYS, whose live values are carried through, so
# changing them in the TUI never shows up as chezmoi drift.
# To hand another key to the app, add its name to KEEP_KEYS.
set -euo pipefail

KEEP_KEYS='["model", "effortLevel", "modelSettings"]'

# Values here are the fallback for a machine that has no settings.json yet.
managed=$(
  cat <<'JSON'
{
  "attribution": {
    "commit": "",
    "pr": ""
  },
  "permissions": {
    "allow": [
      "Bash",
      "Edit",
      "Glob",
      "Grep",
      "LS",
      "MultiEdit",
      "NotebookEdit",
      "NotebookRead",
      "Read",
      "Skill",
      "Task",
      "TodoWrite",
      "WebFetch",
      "WebSearch",
      "Write",
      "Bash(glab mr approve*)",
      "Bash(glab mr merge*)",
      "Bash(gh pr merge*)",
      "Bash(gh pr review*--approve*)",
      "Bash(jira-api GET *)",
      "Bash(jira-api POST *)",
      "Bash(jira-api PUT *)",
      "mcp__claude_ai_Atlassian__createJiraIssue",
      "mcp__claude_ai_Atlassian__editJiraIssue",
      "mcp__claude_ai_Atlassian__transitionJiraIssue",
      "Bash(git worktree prune*)"
    ],
    "ask": [],
    "deny": [
      "Skill(frontend-design:frontend-design)",
      "Skill(frontend-design:frontend-design *)",
      "Bash(gh pr merge*--admin*)",
      "mcp__claude_ai_Datadog"
    ],
    "additionalDirectories": ["~/.cache/agents"],
    "defaultMode": "auto"
  },
  "autoMode": {
    "environment": [
      "$defaults",
      "Trusted source control: gitlab.com/jwpconnatix/* and forgejo.koof.win/bcasey/*. Trusted Jira: jwplayer.atlassian.net."
    ],
    "allow": [
      "$defaults",
      "Approving an MR/PR with `glab mr approve`, `glab api --method POST .../merge_requests/<iid>/approve`, or `gh pr review --approve` when the user asked to approve that MR/PR in this session. Read-only polling of MR/PR state (`glab mr view`, GET `glab api`) is never Self-Approval.",
      "Commenting on, closing, or editing MRs in gitlab.com/jwpconnatix/*, and updating Jira issues or fix versions in jwplayer.atlassian.net, when the user asked for that action in this session.",
      "Editing files under ~/.config/agents/, ~/.local/share/chezmoi/, ~/.claude/, ~/.claude-two/, or ~/.codex/ (settings, hooks, skills, agents), running `chezmoi apply`, and committing, amending unpushed commits, or `git pull --rebase` in ~/.local/share/chezmoi, when the user ran /llm-setup-audit or asked for that change in this session."
    ]
  },
  "model": "opus",
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "claude-sonnet-5-5"
  },
  "skillOverrides": {
    "frontend-design": "user-invocable-only",
    "dataviz": "name-only",
    "claude-api": "name-only",
    "anthropic-skills:docs": "user-invocable-only",
    "anthropic-skills:google-workspace": "user-invocable-only",
    "anthropic-skills:docx": "name-only",
    "anthropic-skills:pdf": "name-only",
    "anthropic-skills:pptx": "name-only",
    "anthropic-skills:xlsx": "name-only",
    "anthropic-skills:skill-creator": "name-only",
    "anthropic-skills:morning": "user-invocable-only",
    "anthropic-skills:import-memory": "user-invocable-only",
    "keybindings-help": "name-only",
    "fewer-permission-prompts": "name-only",
    "simplify": "name-only",
    "workflow-authoring": "name-only",
    "loop": "name-only",
    "schedule": "name-only",
    "code-review": "user-invocable-only",
    "anthropic-skills:deep-research": "name-only",
    "run": "name-only",
    "plugin-authoring": "name-only",
    "anthropic-skills:built-in-browser": "name-only",
    "anthropic-skills:chrome-browser": "name-only",
    "anthropic-skills:computer-use": "name-only"
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/prune-agent-dirs.sh",
            "async": true,
            "timeout": 120
          }
        ]
      },
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/agent-tmux-session.sh claude",
            "async": true,
            "timeout": 3
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/promote-ai-title.sh",
            "async": true,
            "timeout": 5
          }
        ]
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/agent-tmux-session.sh claude",
            "async": true,
            "timeout": 3
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/cache-keepalive.sh prompt",
            "timeout": 5
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/cache-keepalive.sh idle",
            "asyncRewake": true,
            "timeout": 3300
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  },
  "enabledPlugins": {
    "rust-analyzer-lsp@claude-plugins-official": false,
    "playwright@claude-plugins-official": false,
    "frontend-design@claude-plugins-official": false
  },
  "extraKnownMarketplaces": {},
  "feedbackSurveyRate": 0,
  "syntaxHighlightingDisabled": true,
  "effortLevel": "medium",
  "tui": "fullscreen",
  "autoMemoryEnabled": false,
  "skipDangerousModePermissionPrompt": true,
  "skipWorkflowUsageWarning": true,
  "theme": "custom:onedark",
  "fileCheckpointingEnabled": true,
  "skipAutoPermissionPrompt": true,
  "inputNeededNotifEnabled": true,
  "remoteControlAtStartup": false
}
JSON
)

live=$(cat)

# The merge needs jq. It ships in the shared brew bundle that the pre-install
# script installs before chezmoi applies any file, so this is the bootstrap
# edge case only. Never destroy the live file: pass it through untouched, and
# fall back to the managed defaults only when there is no live file yet.
if ! command -v jq >/dev/null 2>&1; then
  if [ -n "${live//[[:space:]]/}" ]; then
    printf '%s\n' "$live"
  else
    printf '%s\n' "$managed"
  fi
  exit 0
fi

# A corrupt or non-object live file MUST fall back to the managed defaults.
# Slurp so a half-written file with two concatenated values still parses.
live=$(printf '%s' "$live" | jq -s -c 'first // {} | if type == "object" then . else {} end' 2>/dev/null) || live='{}'
[ -n "$live" ] || live='{}'

jq -n \
  --argjson keep "$KEEP_KEYS" \
  --argjson managed "$managed" \
  --argjson live "$live" \
  '(
     $live
     | to_entries
     | map(select(.key as $k |
         (($managed | has($k)) or ($keep | index($k) != null))))
     | map(
         if (.key as $k | ($keep | index($k) != null)) then .
         else .value = $managed[.key]
         end
       )
     | from_entries
   ) + (
     $managed
     | to_entries
     | map(select(.key as $k | ($live | has($k) | not)))
     | from_entries
   )'
