import { expect, test } from 'claude-code/testing'

const ENGINE = { plugin: 'engine', tier: 'core' } as const

// The text a row draws: a Box's children one per line, a Text's runs joined.
type Drawn = string | { type?: string; children?: Drawn[] } | null | undefined
const textOf = (node: Drawn): string =>
  typeof node === 'string' ? node : (node?.children ?? []).map(textOf).join(node?.type === 'Box' && (node as { props?: { flexDirection?: string } }).props?.flexDirection === 'column' ? '\n' : '')
// Stands in for the engine's row: it draws the text it is handed.
const engineRow = (on: Parameters<Parameters<typeof test>[1]>[1]) => on('ui.render', ($, e) => ({ type: 'Text', children: [(e.props as { text: string }).text] }) as never)
const drawnRow = async ($: Parameters<Parameters<typeof test>[1]>[0], command: string, text: string) =>
  textOf((await $.ui.render({ component: 'CommandOutput', surface: 'terminal', props: { command, args: '', text, isErrored: false } } as never)) as Drawn)
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

test('drops local MCP tool names and names their server', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = [HEADER, 'Monitor', 'mcp__chrome-devtools__click', 'mcp__openaiDeveloperDocs__search_openai_docs'].join('\n')
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).toContain('Monitor')
  expect(result.text).not.toContain('mcp__')
  expect(result.text).toContain('tools from chrome-devtools, openaiDeveloperDocs.')
})

test('keeps removal notices whole', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = 'The following tools are no longer available. Do not call them:\nmcp__claude_ai_Datadog__search_logs\nAgent'
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).toBe(text)
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

test('drops the server notes when no server is left', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# MCP Server Instructions\n\nIntro.\n\n## claude.ai Notion\nSearch.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toBeNull()
})

test('keeps the MCP disconnect notice when all notes are hidden', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# MCP Server Instructions\nIntro:\n## claude.ai Notion\nSearch.\nThe following MCP servers have disconnected. Their instructions above no longer apply:\nclaude.ai Datadog\nThis is ambient context.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toBe('The following MCP servers have disconnected. Their instructions above no longer apply:\nclaude.ai Datadog\nThis is ambient context.')
})

test('keeps a disconnect-only MCP notice', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = 'The following MCP servers have disconnected. Their instructions above no longer apply:\nclaude.ai Atlassian MCP\nThis is ambient context.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toBe(text)
})

const NOTES_TEXT = '# MCP Server Instructions\nIntro:\n## claude.ai Notion\nSearch first.\n\n## claude.ai Atlassian MCP\nGet the site ID.'
const searchResult = (names: string[]) => ({ result: { content: names.map(tool_name => ({ type: 'tool_reference', tool_name })) } })

test('hides every server note, Atlassian included', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text: NOTES_TEXT })
  expect(result.text).toBeNull()
})

test('hides notes but keeps the disconnect notice after them', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = `${NOTES_TEXT}\nThe following MCP servers have disconnected. Their instructions above no longer apply:\nclaude.ai Datadog`
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toBe('The following MCP servers have disconnected. Their instructions above no longer apply:\nclaude.ai Datadog')
})

test('sends a connector notes with its first ToolSearch result, once per agent', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => searchResult(['mcp__claude_ai_Notion__search', 'mcp__claude_ai_Atlassian_MCP__getJiraIssue']))

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: NOTES_TEXT })
  const first = await $.tool.call({ tool: 'ToolSearch', input: { query: 'notion' }, tool_use_id: 'a' })
  const context = (first.context ?? []).join('\n')
  expect(context).toContain('Search first.')
  expect(context).toContain('Get the site ID.')

  const again = await $.tool.call({ tool: 'ToolSearch', input: { query: 'notion' }, tool_use_id: 'b' })
  expect(again.context ?? []).toEqual([])

  const subagent = await $.tool.call({ tool: 'ToolSearch', input: { query: 'notion' }, tool_use_id: 'c', agentId: 'sub' })
  expect((subagent.context ?? []).join('\n')).toContain('Search first.')
})

test('leaves other tool calls alone', async ($, on) => {
  on('tool.call', () => ({ result: 'mcp__claude_ai_Notion__search' }))

  const result = await $.tool.call({ tool: 'Bash', input: { command: 'ls' }, tool_use_id: 'd' })
  expect(result.context ?? []).toEqual([])
})

test('sends notes with a connector tool call whose result does not name it', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: '# MCP Server Instructions\n\n## claude.ai Datadog\nUse log queries.' })
  const result = await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'e' })
  expect((result.context ?? []).join('\n')).toContain('Use log queries.')
})

test('names a hidden connector as the keyword example', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = [HEADER, 'mcp__claude_ai_Google_Calendar__list_events', 'mcp__claude_ai_Slack__slack_send_message'].join('\n')
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).toContain('(e.g. "google"): tools from Google_Calendar, Slack.')
  expect(result.text).not.toContain('datadog')
})

test('sends notes for a connector whose name has punctuation', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: '# MCP Server Instructions\n\n## claude.ai Google Calendar (Beta)\nUse UTC.' })
  const result = await $.tool.call({ tool: 'mcp__claude_ai_Google_Calendar_Beta__list_events', input: {}, tool_use_id: 'f' })
  expect((result.context ?? []).join('\n')).toContain('Use UTC.')
})

test('keeps headings inside a connector notes with that connector', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))

  const text = '# MCP Server Instructions\nIntro:\n## claude.ai Notion\nSearch first.\n## Usage\nPage IDs are UUIDs.\n## claude.ai Slack\nBe brief.'
  const hiddenText = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(hiddenText.text).toBeNull()

  const result = await $.tool.call({ tool: 'mcp__claude_ai_Notion__search', input: {}, tool_use_id: 'g' })
  const context = (result.context ?? []).join('\n')
  expect(context).toContain('Search first.')
  expect(context).toContain('Page IDs are UUIDs.')
})

test('keeps the last connector whole when a heading follows it, since it may be a local server', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# MCP Server Instructions\nIntro:\n## claude.ai Notion\nSearch first.\n## Search tips\nQuote titles.\n## claude.ai Slack\nBe brief.\n## My Pages\nList first.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toContain('## claude.ai Slack\nBe brief.\n## My Pages\nList first.')
  expect(result.text).not.toContain('Quote titles.')
})

test('keeps a later single-connector update whole when its notes have a heading', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: '# MCP Server Instructions\nIntro:\n## claude.ai Datadog\nUse log queries.' })
  const text = '# MCP Server Instructions\nIntro:\n## claude.ai Atlassian MCP\nGet the site ID.\n## Jira\nUse JQL.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toContain('## claude.ai Atlassian MCP\nGet the site ID.\n## Jira\nUse JQL.')

  const call = await $.tool.call({ tool: 'mcp__claude_ai_Atlassian_MCP__getJiraIssue', input: {}, tool_use_id: 's' })
  expect(call.context ?? []).toEqual([])
})

test('keeps the notice that tools are available again', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = 'The following tools are available again in this session. The earlier instruction to disregard their definitions and not call them no longer applies:\nmcp__claude_ai_Notion__search'
  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text })
  expect(result.text).toBe(text)
})

test('leaves out a deferred list left empty', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const result = await $.prompt.attachment({ type: 'deferred_tools_delta', text: `${HEADER}\nAskUserQuestion` })
  expect(result.text).toBeNull()
})

test('sends notes again after the session is compacted', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))
  on('session.compact', ($, e) => ({ messages: e.messages, tokensBefore: 100, tokensAfter: 10 }))

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: '# MCP Server Instructions\n\n## claude.ai Datadog\nUse log queries.' })
  await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'h' })
  await $.session.compact({ trigger: 'manual', messages: [{ role: 'user', text: 'hi', toolUses: [] }] })
  const result = await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'i' })
  expect((result.context ?? []).join('\n')).toContain('Use log queries.')

  await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'm', agentId: 'sub' })
  await $.session.compact({ trigger: 'manual', agentId: 'other', messages: [{ role: 'user', text: 'hi', toolUses: [] }] })
  const sub = await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'n', agentId: 'sub' })
  expect(sub.context ?? []).toEqual([])
})

test('keeps notes sent after a precomputed compaction that is not applied yet', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))
  on('session.compact', ($, e) => ({ messages: e.messages, tokensBefore: 100, tokensAfter: 10 }))

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: '# MCP Server Instructions\n\n## claude.ai Datadog\nUse log queries.' })
  await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'o' })
  await $.session.compact({ trigger: 'precompute', messages: [{ role: 'user', text: 'hi', toolUses: [] }] })
  const result = await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'p' })
  expect(result.context ?? []).toEqual([])
})

test('sends notes again after a connector reconnects', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))

  const notes = '# MCP Server Instructions\n\n## claude.ai Datadog\nUse log queries.'
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: notes })
  await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'j' })
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: 'The following MCP servers have disconnected. Their instructions above no longer apply:\nclaude.ai Datadog\nThis is ambient context.' })
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: notes })
  const result = await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'k' })
  expect((result.context ?? []).join('\n')).toContain('Use log queries.')
})

test('does not send notes for a connector named inside another connector result', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: 'log line: mcp__claude_ai_Notion__search failed' }))

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: NOTES_TEXT })
  const result = await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'l' })
  expect((result.context ?? []).join('\n')).not.toContain('Search first.')
})

test('shortens built-in agent descriptions and keeps custom ones in a subagent listing', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = [
    'Available agent types for the Agent tool:',
    '- cheap: Mechanical work. (Tools: Bash, Read)',
    '- claude-code-guide: Use this agent when the user asks questions about Claude Code and much more. (Tools: Bash, Read, WebFetch, WebSearch)',
    '- general-purpose: General-purpose agent for researching complex questions. (Tools: *)',
  ].join('\n')
  const result = await $.prompt.attachment({ type: 'agent_listing_delta', text, agentId: 'sub' })
  expect(result.text).toContain('- cheap: Mechanical work. (Tools: Bash, Read)')
  expect(result.text).toContain('- claude-code-guide: Questions about Claude Code, the Agent SDK, the Claude API, or Claude in Slack. Continue a running one with SendMessage. (Tools: Bash, Read, WebFetch, WebSearch)')
  expect(result.text).toContain('- general-purpose: Generic research and multi-step tasks. Use only when no named role fits. (Tools: *)')
  expect(result.text).not.toContain('much more')
})

test('moves the main agent listing into the Agent tool description', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.describe', ($, e) => ({ description: e.description }))

  const text = [
    'Available agent types for the Agent tool:',
    '- cheap: Mechanical work. (Tools: Bash, Read)',
    '- general-purpose: General-purpose agent for researching complex questions. (Tools: *)',
    '',
    'When you launch multiple agents for independent work, send them in a single message with multiple tool uses so they run concurrently.',
  ].join('\n')
  const listing = await $.prompt.attachment({ type: 'agent_listing_delta', text })
  expect(listing.text).toBeNull()
  const agent = await $.tool.describe({ tool: 'Agent', description: 'Launch an agent.\n\nAvailable agent types are listed in <system-reminder> messages in the conversation.', provider: ENGINE })
  expect(agent.isDeferred).toBe(true)
  expect(agent.description).toBe(
    [
      'Launch an agent.',
      '',
      "The main session's agent types are listed below. In a subagent, use only the types in its own agent listing.",
      '',
      'Available agent types for the Agent tool:',
      '- cheap: Mechanical work. (Tools: Bash, Read)',
      '- general-purpose: Generic research and multi-step tasks. Use only when no named role fits. (Tools: *)',
      '',
      'When you launch multiple agents for independent work, send them in a single message with multiple tool uses so they run concurrently.',
    ].join('\n'),
  )
})

test('repeats removal notices after the listings they follow', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.describe', ($, e) => ({ description: e.description }))

  await $.prompt.attachment({ type: 'agent_listing_delta', text: 'Available agent types for the Agent tool:\n- cheap: Mechanical work.\n- tester: Runs checks.' })
  await $.prompt.attachment({ type: 'agent_listing_delta', text: 'The following agent types are no longer available:\n- tester' })
  const agent = await $.tool.describe({ tool: 'Agent', description: 'Launch an agent.', provider: ENGINE })
  expect(agent.description).toContain('- cheap: Mechanical work.\n- tester: Runs checks.\n\nThe following agent types are no longer available:\n- tester')
  expect(agent.description?.match(/no longer available/g)).toHaveLength(1)
})

test('keeps a listing that repeats an earlier one, so the latest change wins', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.describe', ($, e) => ({ description: e.description }))

  const added = 'New agent types are now available for the Agent tool:\n- x-agent: Does x.'
  const removed = 'The following agent types are no longer available:\n- x-agent'
  await $.prompt.attachment({ type: 'agent_listing_delta', text: 'Available agent types for the Agent tool:\n- cheap: Mechanical work.' })
  for (const text of [added, removed, added]) await $.prompt.attachment({ type: 'agent_listing_delta', text })
  const agent = await $.tool.describe({ tool: 'Agent', description: 'Launch an agent.', provider: ENGINE })
  expect(agent.description?.endsWith(added)).toBe(true)
})

test('restores agent listings once on resume, and reads a 0.6.0 session without failing', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.describe', ($, e) => ({ description: e.description }))
  let id = 'first'
  on('session.id', () => ({ value: id }))
  const memory = new Map<string, unknown>([['session:old', { at: 1, hidden: { 'Agent listing (moved to the Agent tool)': { cheap: 'x' } }, kept: {}, agents: { cheap: '- cheap: x' } }]])
  on('store.set', ($, e) => {
    memory.set(e.key, e.value)
    return { value: undefined }
  })
  on('store.get', ($, e) => ({ value: memory.get(e.key) }))
  on('store.keys', () => ({ value: [...memory.keys()] }))
  const listing = 'Available agent types for the Agent tool:\n- cheap: Mechanical work.'
  await $.prompt.attachment({ type: 'agent_listing_delta', text: listing })
  await new Promise(resolve => setTimeout(resolve, 10))
  memory.set('session:resumed', memory.get('session:first'))
  id = 'resumed'
  await $.prompt.attachment({ type: 'agent_listing_delta', text: listing })
  const resumed = await $.tool.describe({ tool: 'Agent', description: 'Launch an agent.', provider: ENGINE })
  expect(resumed.description?.match(/- cheap:/g)).toHaveLength(1)
  id = 'old'
  await $.prompt.attachment({ type: 'agent_listing_delta', text: listing })
  await new Promise(resolve => setTimeout(resolve, 10))
  const old = memory.get('session:old') as { agents: string[]; hidden: Record<string, Record<string, string>> }
  expect(old.agents).toEqual([listing])
  expect(Object.keys(old.hidden['Agent listing (moved to the Agent tool)'])).toHaveLength(1)
})

test('keeps plugin agents and multi-line agent descriptions whole', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.describe', ($, e) => ({ description: e.description }))

  const text = [
    'Available agent types for the Agent tool:',
    '- codex:codex-rescue: Use when stuck. (Tools: Bash)',
    '- reviewer: Reviews code.',
    'Use after edits.',
    '- Input: a diff (Tools: Read)',
  ].join('\n')
  await $.prompt.attachment({ type: 'agent_listing_delta', text })
  const agent = await $.tool.describe({ tool: 'Agent', description: 'Launch an agent.', provider: ENGINE })
  expect(agent.description).toContain(text)
})

test('keeps notes hidden on resume for a session saved with bare note hashes', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))
  let id = 'bare-hashes'
  on('session.id', () => ({ value: id }))
  const text = '# MCP Server Instructions\n\n## claude.ai Datadog\nUse log queries.'
  // Records what the current version saves for these notes, then offers it as an older session's bare hashes.
  const memory = new Map<string, unknown>()
  on('store.set', ($, e) => {
    memory.set(e.key, e.value)
    return { value: undefined }
  })
  on('store.get', ($, e) => ({ value: memory.get(e.key) }))
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 't' })
  await new Promise(resolve => setTimeout(resolve, 10))
  const saved = memory.get('session:bare-hashes') as { seen: string[] }
  expect(saved.seen.length).toBeGreaterThan(0)
  expect(saved.seen.every(entry => entry.startsWith('main:'))).toBe(true)
  memory.set('session:resumed', { ...saved, seen: saved.seen.map(entry => entry.slice('main:'.length)) })
  id = 'resumed'
  const again = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(again.text).toBeNull()
})

test('drops the email context and keeps other context blocks', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const intro = "As you answer the user's questions, you can use the following context:\n"
  const email = '# userEmail\nThe user is someone@example.com.\n'
  const alone = await $.prompt.attachment({ type: 'session_context', text: intro + email })
  expect(alone.text).toBeNull()
  const mixed = await $.prompt.attachment({ type: 'session_context', text: `${intro}${email}# attachedProject\nProject notes.` })
  expect(mixed.text).toBe(`${intro}# attachedProject\nProject notes.`)
})

test('drops the auto mode note', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const note = await $.prompt.attachment({ type: 'auto_mode', text: 'While auto mode is active:\n\nUse Bash freely.' })
  expect(note.text).toBeNull()
  const other = await $.prompt.attachment({ type: 'auto_mode', text: 'Auto mode is now off.' })
  expect(other.text).toBe('Auto mode is now off.')
})

test('drops the platform, shell and OS lines from the environment', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# Environment\n - Primary working directory: /w\n - Platform: darwin\n - Shell: zsh\n - OS Version: Darwin 27.0.0\n - Scratchpad directory: /s'
  const result = await $.prompt.attachment({ type: 'environment', text })
  expect(result.text).toBe('# Environment\n - Primary working directory: /w\n - Scratchpad directory: /s')
})

test('defers the Skill tool and says how to load it in the skill listing', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const skill = await $.tool.describe({ tool: 'Skill', description: 'invoke skills', provider: ENGINE })
  expect(skill.isDeferred).toBe(true)
  const search = await $.tool.describe({ tool: 'ToolSearch', description: 'find tools', provider: ENGINE })
  expect(search.description).toMatch(/\bSkill\b/)
  const listing = await $.prompt.attachment({ type: 'skill_listing', text: '- commit: Create commits.' })
  expect(listing.text).toBe('The Skill tool is deferred: load it with ToolSearch select:Skill before invoking a skill.\n\n- commit: Create commits.')
})

test('reports only notes kept in the prompt on the MCP row, until their server disconnects', async ($, on) => {
  const local = '## chrome-devtools\nUse it.\n## Usage\nTips.'
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('session.usage', () => ({
    value: {
      startedAt: 0,
      rateLimits: [],
      context: { tokens: 5000, window: 1000000, breakdown: { totalTokens: 5000, categories: [{ name: 'MCP server instructions', tokens: 3000, kind: 'used' }, { name: 'Messages', tokens: 2000, kind: 'used' }] } },
    },
  }))
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  // Each character counts as one token, so a row's tokens are its text's length.
  on('model.complete', ($, e) => ({ value: { isAnswered: true, text: '', usage: { input_tokens: e.prompt.length, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 } } }))

  on('command.run', { command: 'context' }, () => ({ text: 'BUILT-IN' }))
  engineRow(on)
  const run = async () => drawnRow($, 'context', (await $.command.run({ command: 'context' })).text ?? '')

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: `# MCP Server Instructions\n\n${local}\n## claude.ai Notion\nSearch.` })
  const shown = await run()
  expect(shown).toContain(`MCP server instructions: ${local.length} tokens`)
  expect(shown).toContain(`└ chrome-devtools · 1 server · ${local.length} tokens`)
  expect(shown).not.toContain('└ Usage')

  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: 'The following MCP servers have disconnected. Their instructions above no longer apply:\nchrome-devtools\nThis is ambient context.' })
  const after = await run()
  expect(after).toContain('MCP server instructions: 0 tokens')
})

// Answers /context's built-in run, usage and token counts the way a session would.
const contextSession = (on: Parameters<Parameters<typeof test>[1]>[1], size: number | (() => number)) => {
  const tokens = () => (typeof size === 'number' ? size : size())
  on('command.run', { command: 'context' }, () => ({ text: 'BUILT-IN' }))
  on('session.usage', () => ({
    value: { startedAt: 0, rateLimits: [], context: { tokens: tokens(), window: 1000000, breakdown: { totalTokens: tokens(), categories: [{ name: 'Messages', tokens: tokens(), kind: 'used' }] } } },
  }))
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('model.complete', ($, e) => ({ value: { isAnswered: true, text: '', usage: { input_tokens: e.prompt.length, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 } } }))
}

test('/context answers with one summary line and draws the corrected report in its row', async ($, on) => {
  contextSession(on, 5000)
  engineRow(on)
  const result = await $.command.run({ command: 'context' })
  expect(result.text).toMatch(/^Context: 5k real tokens; context-lean hid 0\. \[context-lean report [a-z0-9]+\]$/)
  const row = await drawnRow($, 'context', result.text ?? '')
  expect(row).toContain('Context Usage (context-lean)')
  expect(row.replace(/\u001b\[[0-9;]*m/g, '')).toContain('⛁ Messages: 5k tokens (0.5%)')
  // Another command's row that names the report is drawn as it is.
  expect(await drawnRow($, 'echo', result.text ?? '')).toBe(result.text ?? '')
})

test('a row whose report this process does not hold draws as the engine would', async ($, on) => {
  on('ui.render', ($, e) => ({ type: 'Text', children: ['ENGINE'] }) as never)
  expect(await drawnRow($, 'context', 'Context: 5k real tokens; context-lean hid 0. [context-lean report zzz]')).toBe('ENGINE')
})

test('/context all runs the built-in command', async ($, on) => {
  contextSession(on, 5000)
  const result = await $.command.run({ command: 'context', args: 'all' })
  expect(result.text).toBe('BUILT-IN')
})

test('/context before anything was sent shows the last saved report, marked as such', async ($, on) => {
  // The test kit keeps no store of its own, so the saved report needs one.
  const memory = new Map<string, unknown>()
  on('store.set', ($, e) => {
    memory.set(e.key, e.value)
    return { value: undefined }
  })
  on('store.get', ($, e) => ({ value: memory.get(e.key) }))
  let sent = 5000
  contextSession(on, () => sent)
  engineRow(on)
  await $.command.run({ command: 'context' })
  sent = 0
  const result = await $.command.run({ command: 'context' })
  expect(result.text).toMatch(/^Last saved report\. Context: 5k real tokens/)
  expect(await drawnRow($, 'context', result.text ?? '')).toContain('No message sent in this session yet, so these numbers are from your last report')
})

test('/context before anything was sent, with no saved report, runs the built-in command', async ($, on) => {
  contextSession(on, 0)
  const result = await $.command.run({ command: 'context' })
  expect(result.text).toBe('BUILT-IN')
})

test('/context runs the built-in command when the report cannot be built', async ($, on) => {
  on('command.run', { command: 'context' }, () => ({ text: 'BUILT-IN' }))
  on('session.usage', () => ({ value: { startedAt: 0, rateLimits: [], context: { tokens: 5000, window: 1000000 } } }))
  const result = await $.command.run({ command: 'context' })
  expect(result.text).toBe('BUILT-IN')
})

test('keeps notes in the prompt when they arrive after the connector was used', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => searchResult(['mcp__claude_ai_Notion__search']))

  const first = await $.tool.call({ tool: 'ToolSearch', input: { query: 'notion' }, tool_use_id: 'q' })
  expect(first.context ?? []).toEqual([])
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text: '# MCP Server Instructions\n\n## claude.ai Notion\nSearch first.' })
  expect(result.text).toContain('Search first.')

  const again = await $.tool.call({ tool: 'ToolSearch', input: { query: 'notion' }, tool_use_id: 'r' })
  expect(again.context ?? []).toEqual([])
})

test('keeps hiding notes when the engine asks again after the connector was used', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))

  const text = '# MCP Server Instructions\n\n## claude.ai Datadog\nUse log queries.'
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 't' })
  const again = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(again.text).toBeNull()
})

test('keeps a local server shown that sorts between ASCII and non-ASCII connectors', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))

  const text = '# MCP Server Instructions\n\n## claude.ai Atlassian MCP\nGet the site ID.\n\n## playwright\nOpen a page first.\n\n## claude.ai Jira – Prod\nUse JQL.'
  const result = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(result.text).toContain('## playwright\nOpen a page first.')
  expect(result.text).not.toContain('Use JQL.')
})

test('keeps old notes hidden when asked again after a reconnect changed them', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))

  const first = '# MCP Server Instructions\n\n## claude.ai Datadog\nUse log queries.'
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: first })
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: 'The following MCP servers have disconnected. Their instructions above no longer apply:\nclaude.ai Datadog\nThis is ambient context.' })
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text: '# MCP Server Instructions\n\n## claude.ai Datadog\nUse log queries with service filters.' })
  await $.tool.call({ tool: 'mcp__claude_ai_Datadog__search_logs', input: {}, tool_use_id: 'u' })
  const again = await $.prompt.attachment({ type: 'mcp_instructions_delta', text: first })
  expect(again.text).toBeNull()
})

test('keeps notes kept for one agent when a subagent hides the same notes', async ($, on) => {
  on('prompt.attachment', ($, e) => ({ text: e.text }))
  on('tool.call', () => ({ result: undefined }))

  const text = '# MCP Server Instructions\n\n## claude.ai Notion\nSearch first.'
  await $.tool.call({ tool: 'mcp__claude_ai_Notion__search', input: {}, tool_use_id: 'v' })
  const kept = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(kept.text).toContain('Search first.')
  await $.prompt.attachment({ type: 'mcp_instructions_delta', text, agentId: 'sub' })
  const again = await $.prompt.attachment({ type: 'mcp_instructions_delta', text })
  expect(again.text).toContain('Search first.')
})

test('/context sizes the autocompact buffer from the reported compaction point', async ($, on) => {
  on('command.run', { command: 'context' }, () => ({ text: 'BUILT-IN' }))
  on('session.usage', () => ({
    value: {
      startedAt: 0,
      rateLimits: [],
      context: {
        tokens: 5000,
        window: 1000000,
        breakdown: { totalTokens: 5000, autoCompactThreshold: 400000, categories: [{ name: 'Messages', tokens: 5000, kind: 'used' }, { name: 'Autocompact buffer', tokens: 33000, kind: 'buffer' }] },
      },
    },
  }))
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('model.complete', ($, e) => ({ value: { isAnswered: true, text: '', usage: { input_tokens: e.prompt.length, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 } } }))
  engineRow(on)
  const row = await drawnRow($, 'context', (await $.command.run({ command: 'context' })).text ?? '')
  expect(row).toContain('Autocompact buffer: 600k tokens (60.0%)')
  expect(row).toContain('Free space: 395k (39.5%)')
})
