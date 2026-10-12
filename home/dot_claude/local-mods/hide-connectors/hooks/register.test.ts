import { expect, test } from 'claude-code/testing'

const ENGINE = { plugin: 'engine', tier: 'core' } as const
const HEADER = 'The following deferred tools are now available via ToolSearch.'

test('defers hidden connector tools', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  const docs = await $.tool.describe({ tool: 'mcp__claude_ai_Claude_Docs__batch', description: 'docs', provider: ENGINE })
  expect(docs.isDeferred).toBe(true)
  expect(docs.description).toBe('docs')
})

test('leaves kept connectors and other tools alone', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  for (const tool of ['mcp__claude_ai_Atlassian__getJiraIssue', 'mcp__claude_ai_Atlassian_MCP__search', 'mcp__chrome-devtools__click', 'Bash']) {
    const result = await $.tool.describe({ tool, description: 'text', provider: ENGINE })
    expect(result.isDeferred).toBeUndefined()
  }
})

test('drops hidden names from the deferred list and notes them', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = [HEADER, 'Monitor', 'mcp__claude_ai_Datadog__search_logs', 'mcp__claude_ai_Gmail__send_message', 'mcp__claude_ai_Slack__slack_send_message'].join('\n')
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).toContain('Monitor')
  expect(result.text).toContain('mcp__claude_ai_Slack__slack_send_message')
  expect(result.text).not.toContain('mcp__claude_ai_Datadog__')
  expect(result.text).toContain('tools from Datadog, Gmail.')
})

test('drops a paragraph left with only its header', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = `${HEADER}\nMonitor\n\nThe following tools just became available:\nmcp__claude_ai_Claude_Docs__batch`
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).not.toContain('just became available')
  expect(result.text).toContain('Monitor')
})

test('keeps an untouched deferred list as is', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = `${HEADER}\nMonitor`
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).toBe(text)
})

test('drops instructions of hidden servers', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# MCP Server Instructions\n\nIntro.\n\n## claude.ai Atlassian MCP\nUse Jira.\n\n## claude.ai Claude Docs\nMake docs.\n\n## claude.ai monday.com\nBoards.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toContain('Use Jira.')
  expect(result.text).not.toContain('Make docs.')
  expect(result.text).not.toContain('Boards.')
})

test('drops the instructions when no server is left', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# MCP Server Instructions\n\nIntro.\n\n## claude.ai Notion\nSearch.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toBeNull()
})
