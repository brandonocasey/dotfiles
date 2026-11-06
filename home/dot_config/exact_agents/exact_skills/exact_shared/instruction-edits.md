---
paths:
  - "**/*AGENTS*.md"
  - "**/CLAUDE.md"
  - "**/SKILL.md"
  - "**/skills/**/*.md"
  - "**/exact_skills/**/*.md"
  - "**/.claude/agents/*.md"
  - "**/.claude/rules/**/*.md"
  - "**/output-styles/*.md"
  - "**/output-styles/*.tmpl"
  - "**/.chezmoitemplates/*.md"
  - "**/.chezmoitemplates/agents/*.md"
  - "**/exact_agents/exact_agents/*.tmpl"
  - "**/dot_codex/exact_agents/*.tmpl"
  - "**/dot_claude/exact_rules/*"
  - ".config/agents/**/*.md"
  - ".codex/agents/*.toml"
  - ".claude/output-styles/*.md"
  - ".claude-two/output-styles/*.md"
  - ".local/share/chezmoi/home/.chezmoitemplates/**"
  - ".local/share/chezmoi/home/dot_config/exact_agents/**"
  - ".local/share/chezmoi/home/dot_codex/exact_agents/**"
  - ".local/share/chezmoi/home/dot_claude/output-styles/**"
  - "**/*claude*/settings*.json"
---
# Editing agent instructions

For skills and their references, rules files, role files, output styles, and the templates that render them. Applies when you add, move, trim, or change a rule, step, command, path, or default. Skip it for typo, formatting, and link-only fixes, and when you only read the file.

Before editing:
- Write one line: the behavior change you intend, and the behavior that must stay. When the user approved wording or a plan, keep to it.
- Search every instruction root (global and main rules, all skills and references, role bodies and templates, project AGENTS.md or CLAUDE.md) for the topic and for the text you will change. List each file that states, cites, or depends on it.

While editing:
- Change the rule in the file that owns it; elsewhere, point there instead of restating it. When a new rule meets a sibling rule, edit both so they agree, or say which wins.
- Give each new rule a trigger and a scope. Read it literally: where could it fire when it should not, or never fire?
- Check every command, subcommand, flag, env name, and output field you write against the installed tool's help or source, and against the minimum version the skill names. Run it when safe.
- For each reader (main session, each role, Codex, and harnesses that get the file through links), confirm it loads the text and can do the step: tools, write access, asking the user, spawning agents.
- Walk the flow through its failure, empty, and missing-tool branches, and name who runs each step.
- When options combine (splits, fan-out, retries, reviewers, models), state the worst-case total of agents, calls, and cost, and cap it.

After editing:
- Search again for each moved, renamed, trimmed, or deleted rule, heading, step number, flag, and path. Fix every stale pointer.
- When trimming or merging, map each removed clause to where it now lives, or say why no reader acts on it.
- Compare the result with your intent line. In the report, name any widened or narrowed scope, dropped guard, changed default, or added stop point.
