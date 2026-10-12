import { expect, test } from 'claude-code/testing'
import { report } from './report'

const BASE = { real: 19943, window: 1000000, estimate: 17265, model: 'claude-opus-5-5' }

test('shows real, hidden and without totals', () => {
  const text = report({ ...BASE, hidden: [{ label: 'Datadog tool names', items: 412, tokens: 11203 }, { label: 'Workflow description', items: 1, tokens: 1950 }], kept: [] })
  expect(text).toContain('## Real context: 19,943 / 1,000,000 tokens (2.0%)')
  expect(text).toContain('| Hidden by context-lean | 13,153 |')
  expect(text).toContain('| Without context-lean (about) | 33,096 |')
  expect(text).toContain('| Saved | 39.7% |')
  expect(text).toContain('| /context estimate (ignores this mod) | 17,265 |')
  expect(text.indexOf('Datadog tool names')).toBeLessThan(text.indexOf('Workflow description'))
  expect(text).toContain('| Datadog tool names | 412 | 11,203 |')
  expect(text).not.toContain('Kept in the prompt')
})

test('lists kept notes and uncounted rows', () => {
  const text = report({ ...BASE, estimate: undefined, hidden: [{ label: 'Gmail tool names', items: 3, tokens: undefined }], kept: [{ label: 'Atlassian MCP server notes', items: 1, tokens: 640 }] })
  expect(text).toContain('| Gmail tool names | 3 | not counted |')
  expect(text).toContain('### Kept in the prompt')
  expect(text).toContain('| Atlassian MCP server notes | 1 | 640 |')
  expect(text).not.toContain('/context estimate')
})
