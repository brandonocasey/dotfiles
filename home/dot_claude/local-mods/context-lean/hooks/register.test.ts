import { expect, test } from 'claude-code/testing'

const ENGINE = { plugin: 'engine', tier: 'core' } as const
const HEADER = 'The following deferred tools are now available via ToolSearch.'

test('defers the Artifact tools with a note', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  const artifact = await $.tool.describe({ tool: 'Artifact', description: 'publish', provider: ENGINE })
  expect(artifact.isDeferred).toBe(true)
  expect(artifact.description).toContain('explicitly asks')
  expect(artifact.description).toContain('publish')
})

test('defers rare built-ins and connector tools without a note', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  for (const tool of ['ScheduleWakeup', 'SendFeedback', 'ReportFindings', 'ListAgents', 'AskUserQuestion', 'Workflow', 'ShareOnboardingGuide', 'Agent', 'mcp__claude_ai_Claude_Docs__batch', 'mcp__claude_ai_Atlassian_MCP__search']) {
    const result = await $.tool.describe({ tool, description: 'text', provider: ENGINE })
    expect(result.isDeferred).toBe(true)
    expect(result.description).toBe('text')
  }
})

test('leaves other tools alone', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  for (const tool of ['Bash', 'Read', 'mcp__chrome-devtools__click']) {
    const result = await $.tool.describe({ tool, description: 'run', provider: ENGINE })
    expect(result.isDeferred).toBeUndefined()
    expect(result.description).toBe('run')
  }
})

test('tells ToolSearch the rare tools are loadable', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  const search = await $.tool.describe({ tool: 'ToolSearch', description: 'find tools', provider: ENGINE })
  expect(search.description).toContain('find tools')
  expect(search.description).toContain('Not in the deferred tools list but loadable with select:<name>')
  expect(search.description).toContain('ScheduleWakeup')
  expect(search.description).toContain('Workflow')
  expect(search.description).toMatch(/\bAgent\b/)
  expect(search.isDeferred).toBeUndefined()
})

test('replaces the Artifact entry and drops rare and connector names', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = [HEADER, 'Agent', 'Artifact: publishes pages on claude.ai. Load it before writing any document.', 'Monitor', 'mcp__claude_ai_Datadog__search_logs', 'mcp__claude_ai_Slack__slack_send_message'].join('\n')
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).toContain('Artifact: reads claude.ai artifact links; publishes pages on claude.ai. Use only when the user explicitly asks for an artifact.')
  expect(result.text).not.toContain('before writing any document')
  expect(result.text).not.toMatch(/^Agent$/m)
  expect(result.text).toContain('Monitor')
  expect(result.text).not.toContain('mcp__claude_ai_')
  expect(result.text).toContain('tools from Datadog, Slack.')
})

test('drops a paragraph left with only its header', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = `${HEADER}\nMonitor\n\nThe following tools just became available:\nmcp__claude_ai_Claude_Docs__batch`
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).not.toContain('just became available')
  expect(result.text).toContain('Monitor')
})

test('leaves a deferred list with nothing to hide unchanged', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = `${HEADER}\nArtifactComments\nMonitor`
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).toBe(text)
})

test('passes an empty deferred list through', async ($, on) => {
  on('prompt.attachment', () => ({ text: null }))

  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text: 'ignored' })
  expect(result.text).toBeNull()
})

test('keeps only Atlassian server notes', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# MCP Server Instructions\n\nIntro.\n\n## claude.ai Atlassian MCP\nUse Jira.\n\n## claude.ai Claude Docs\nMake docs.\n\n## claude.ai monday.com\nBoards.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toContain('Use Jira.')
  expect(result.text).not.toContain('Make docs.')
  expect(result.text).not.toContain('Boards.')
})

test('drops the server notes when no server is left', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# MCP Server Instructions\n\nIntro.\n\n## claude.ai Notion\nSearch.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toBeNull()
})
