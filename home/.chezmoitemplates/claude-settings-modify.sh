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
      "Edit",
      "Glob",
      "Grep",
      "NotebookEdit",
      "Read",
      "Skill",
      "TodoWrite",
      "WebFetch",
      "WebSearch",
      "Write",
      "mcp__claude_ai_Atlassian_MCP__createJiraIssue",
      "mcp__claude_ai_Atlassian_MCP__editJiraIssue",
      "mcp__claude_ai_Atlassian_MCP__executeWrite",
      "mcp__claude_ai_Atlassian_MCP__transitionJiraIssue",
      "Bash(jira-api GET *)",
      "Bash(git worktree prune*)",
      "Bash(tmux capture-pane *)",
      "Bash(chezmoi source-path)",
      "Bash(chezmoi source-path *)",
      "Bash(chezmoi status)",
      "Bash(chezmoi status *)",
      "Bash(chezmoi diff *)",
      "Bash(chezmoi apply *)",
      "Bash(chezmoi add *)",
      "Bash(chezmoi re-add *)",
      "Edit(~/.local/share/chezmoi/home/dot_config/exact_agents/private_AGENTS.md)",
      "Edit(~/.local/share/chezmoi/home/.chezmoitemplates/main-rules.md)",
      "Bash(glab mr list *)",
      "Bash(glab mr view *)",
      "Bash(claude plugin validate *)",
      "Bash(jenkins-api GET *)",
      "Bash(shellcheck *)",
      "Bash(agent-task search *)",
      "Bash(chezmoi managed)",
      "Bash(chezmoi managed *)",
      "Bash(chezmoi cat *)",
      "Bash(npm view *)",
      "mcp__claude_ai_Atlassian_MCP__getJiraIssue",
      "mcp__claude_ai_Atlassian_MCP__searchJiraIssuesUsingJql",
      "mcp__claude_ai_Atlassian_MCP__executeRead",
      "mcp__claude_ai_Atlassian_MCP__discover",
      "mcp__claude_ai_Notion__notion-fetch",
      "mcp__claude_ai_Google_Drive__search_files",
      "mcp__chrome-devtools__list_console_messages"
    ],
    "ask": [],
    "deny": [
      "Bash(gh pr merge*--admin*)",
      "Agent(Explore)",
      "Agent(Plan)",
      "Agent(statusline-setup)",
      "mcp__claude_ai_Claude_Docs",
      "Read(~/.netrc)",
      "Read(~/.ssh/**)",
      "Read(~/.config/glab-cli/**)",
      "Read(~/.config/gh/hosts.yml)",
      "Read(~/.aws/**)"
    ],
    "additionalDirectories": ["~/.cache/agents"],
    "defaultMode": "auto"
  },
  "sandbox": {
    "enabled": false
  },
  "autoMode": {
    "environment": [
      "$defaults",
      "Organization: JW Player / Connatix. Trusted source control: gitlab.com/jwpconnatix/*, forgejo.koof.win/bcasey/*. Trusted internal domains: jwplayer.atlassian.net."
    ],
    "allow": [
      "$defaults",
      "MR/PR and Jira actions the user asked for in this session: approve, merge, enable or re-enable auto-merge, comment, close, edit, and update Jira issues or fix versions. Read-only MR/PR polling is never Self-Approval. Re-enabling auto-merge that this session paused before pushing, with the same method, restores the user's setting and is not a new merge.",
      "Review comments on MRs/PRs the user authored, during a review the user asked for in this session: post, reply, resolve, and reopen. Never on MRs/PRs others authored.",
      "Agent setup changes the user asked for in this session or that /llm-setup-audit applies: edit ~/.config/agents/, ~/.local/share/chezmoi/, ~/.claude/, ~/.claude-two/, ~/.codex/, or a repo's .claude/settings.local.json after backing up to ~/.local/state/agents/backups/; run chezmoi apply; commit, amend unpushed commits, or git pull --rebase in ~/.local/share/chezmoi. Short tmux test runs of claude or codex from ~/.cache/agents/scratch/ only check such a change and never do other task work.",
      "In agent-created worktrees under <repo>/.worktrees/ with a clean tree and a backed-up tip: detached checkouts, cherry-picks, rebases, and rewording local commits. Force-pushes still need the user's request.",
      "When the user asked to test on a LAN device in this session: serve a repo dev server or local build on 0.0.0.0. A static file server never serves a repo root or home directory. Stop the server when testing ends."
    ]
  },
  "model": "opus",
  "autoCompactWindow": 433000,
  "promptCacheTtl": "1h",
  "env": {
    "CLAUDE_CODE_DISABLE_FILE_MENTIONS": "1",
    "CLAUDE_CODE_SUBAGENT_MODEL": "claude-sonnet-5-5",
    "CLAUDE_CODE_TMPDIR": "{{ .chezmoi.homeDir }}/.cache/claude-tmp"
  },
  "skillOverrides": {
    "frontend-design": "user-invocable-only",
    "jira-triage": "name-only",
    "mr-triage": "name-only",
    "release-verify": "name-only",
    "preview": "name-only",
    "session-resume": "name-only",
    "pr-fix": "name-only",
    "host-preflight": "name-only",
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
    "keybindings-help": "user-invocable-only",
    "fewer-permission-prompts": "user-invocable-only",
    "simplify": "user-invocable-only",
    "workflow-authoring": "name-only",
    "loop": "name-only",
    "schedule": "name-only",
    "code-review": "user-invocable-only",
    "anthropic-skills:deep-research": "name-only",
    "run": "name-only",
    "plugin-authoring": "name-only",
    "llm-setup-audit": "name-only",
    "device-test": "name-only",
    "investigate": "name-only",
    "land": "name-only",
    "anthropic-skills:built-in-browser": "name-only",
    "anthropic-skills:chrome-browser": "name-only",
    "anthropic-skills:computer-use": "name-only",
    "artifact-design": "user-invocable-only",
    "artifact-diagramming": "user-invocable-only",
    "artifact-capabilities": "user-invocable-only",
    "update-config": "name-only",
    "init": "user-invocable-only",
    "security-review": "user-invocable-only"
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/cache-keepalive.sh prompt",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/auto-title.sh",
            "timeout": 20
          },
          {
            "type": "command",
            "command": "echo 'Be concise: lead with the result, skip preamble and narration, keep only what the user needs.'",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/session-port.sh",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "resume|fork",
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/cold-cache-warn.sh",
            "timeout": 5
          }
        ]
      },
      {
        "matcher": "startup|clear",
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/auto-title.sh new",
            "timeout": 5
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
      },
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/tmux-bell.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/.claude/hooks/tmux-bell.sh",
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
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh",
    "refreshInterval": 15
  },
  "enabledPlugins": {
    "playwright@claude-plugins-official": false,
    "frontend-design@claude-plugins-official": false,
    "pyright-lsp@claude-plugins-official": true,
    "rust-analyzer-lsp@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "context-lean@local-mods": true,
    "cc-plugin-sec-default@builtin": false
  },
  "extraKnownMarketplaces": {
    "local-mods": {
      "source": {
        "source": "directory",
        "path": "{{ .chezmoi.homeDir }}/.claude/local-mods"
      }
    }
  },
  "feedbackSurveyRate": 0,
  "syntaxHighlightingDisabled": true,
  "effortLevel": "medium",
  "modelSettings": {
    "claude-sonnet-5-5": { "effortLevel": "medium" },
    "claude-opus-5-5": { "effortLevel": "medium" },
    "claude-haiku-5-5": { "effortLevel": "xhigh" }
  },
  "tui": "fullscreen",
  "autoMemoryEnabled": false,
  "skipDangerousModePermissionPrompt": true,
  "skipWorkflowUsageWarning": true,
  "theme": "custom:onedark",
  "fileCheckpointingEnabled": true,
  "skipAutoPermissionPrompt": true,
  "inputNeededNotifEnabled": true,
  "outputStyle": "main",
  "remoteControlAtStartup": false
}
JSON
)

live=$(cat)

# The merge needs jq. It ships in the shared CLI Brewfile that the brew-cli
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
