import { expect, test } from 'claude-code/testing'

const ENGINE = { plugin: 'engine', tier: 'core' } as const

test('defers the Artifact tools with a note', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  const artifact = await $.tool.describe({ tool: 'Artifact', description: 'publish', provider: ENGINE })
  expect(artifact.isDeferred).toBe(true)
  expect(artifact.description).toContain('explicitly asks')
  expect(artifact.description).toContain('publish')
})

test('defers rarely used tools without a note', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  for (const tool of ['ScheduleWakeup', 'SendFeedback', 'ReportFindings', 'ListAgents', 'Agent', 'AskUserQuestion']) {
    const result = await $.tool.describe({ tool, description: 'text', provider: ENGINE })
    expect(result.isDeferred).toBe(true)
    expect(result.description).toBe('text')
  }
})

test('leaves other tools alone', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  const bash = await $.tool.describe({ tool: 'Bash', description: 'run', provider: ENGINE })
  expect(bash.isDeferred).toBeUndefined()
  expect(bash.description).toBe('run')
})

test('tells ToolSearch that Agent is loadable', async ($, on) => {
  on('tool.describe', ($, e) => ({ description: e.description }))

  const search = await $.tool.describe({ tool: 'ToolSearch', description: 'find tools', provider: ENGINE })
  expect(search.description).toContain('find tools')
  expect(search.description).toContain('select:<name>')
  expect(search.description).toContain('ScheduleWakeup')
  expect(search.description).toContain('AskUserQuestion')
  expect(search.isDeferred).toBeUndefined()
})
