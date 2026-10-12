import { expect, test } from 'claude-code/testing'
import { type Category, report } from './report'

const CATEGORIES: Category[] = [
  { name: 'System prompt', tokens: 1505, kind: 'used' },
  { name: 'System tools', tokens: 9295, kind: 'used' },
  { name: 'MCP tools', tokens: 615, kind: 'used' },
  { name: 'MCP server instructions', tokens: 2304, kind: 'used' },
  { name: 'MCP tools (deferred)', tokens: 566678, kind: 'deferred' },
  { name: 'Messages', tokens: 296, kind: 'used' },
  { name: 'Autocompact buffer', tokens: 33000, kind: 'buffer' },
  { name: 'Free space', tokens: 949735, kind: 'free' },
]
const BASE = { real: 19943, window: 1000000, estimate: 17265, model: 'claude-opus-5-5', categories: CATEGORIES }

test('shows real, saved and without totals in /context style', () => {
  const text = report({ ...BASE, hidden: [{ label: 'Datadog tool names', items: 412, tokens: 11203 }, { label: 'Workflow description', items: 1, tokens: 1950 }], kept: [] })
  expect(text).toContain('## Context Usage (context-lean)')
  expect(text).toContain('**Tokens:** 19.9k / 1m (2%), real, from the API')
  expect(text).toContain('**Without context-lean:** 33.1k (13.2k saved, 39.7%)')
  expect(text).toContain('**/context estimate:** 17.3k, which ignores this mod')
  expect(text.indexOf('Datadog tool names')).toBeLessThan(text.indexOf('Workflow description'))
  expect(text).toContain('| Datadog tool names | 412 | 11.2k |')
  expect(text).not.toContain('Kept in the prompt')
})

test('moves hidden items out of the estimated categories and lines up with the real total', () => {
  const text = report({
    ...BASE,
    hidden: [
      { label: 'Workflow description', items: 1, tokens: 1295 },
      { label: 'Claude Docs tool descriptions', items: 3, tokens: 115 },
      { label: 'Notion server notes', items: 1, tokens: 394 },
    ],
    kept: [{ label: 'Atlassian MCP server notes', items: 1, tokens: 793 }],
  })
  expect(text).toContain('| System tools | 8k | 0.8% |')
  expect(text).toContain('| MCP tools | 500 | 0.1% |')
  // Only the hidden notes leave the estimate; kept and local servers' notes stay.
  expect(text).toContain('| MCP server instructions | 1.9k | 0.2% |')
  // 19,943 real minus (1,505 + 8,000 + 500 + 1,910 + 296) estimated.
  expect(text).toContain('| Unattributed (real minus estimates) | 7.7k | 0.8% |')
  expect(text).toContain('| Free space | 947.1k | 94.7% |')
  expect(text.indexOf('Unattributed')).toBeLessThan(text.indexOf('Free space'))
})

test('lists kept notes and uncounted rows', () => {
  const text = report({ ...BASE, estimate: undefined, hidden: [{ label: 'Gmail tool names', items: 3, tokens: undefined }], kept: [{ label: 'Atlassian MCP server notes', items: 1, tokens: 640 }] })
  expect(text).toContain('| Gmail tool names | 3 | not counted |')
  expect(text).toContain('### Kept in the prompt')
  expect(text).toContain('| Atlassian MCP server notes | 1 | 640 |')
  expect(text).not.toContain('/context estimate')
})

test('skips the category table without categories', () => {
  const text = report({ ...BASE, categories: [], hidden: [], kept: [] })
  expect(text).not.toContain('Usage by category')
})

test('puts a note above the report', () => {
  const text = report({ ...BASE, hidden: [], kept: [], note: 'From your last report.' })
  expect(text.startsWith('From your last report.\n\n## Context Usage')).toBe(true)
})

test('takes notes sent on first use out of the server instructions estimate', () => {
  const text = report({ ...BASE, hidden: [{ label: 'Notion server notes', items: 1, tokens: 394 }], kept: [{ label: 'Atlassian MCP server notes (sent on first use)', items: 1, tokens: 793 }] })
  // 2,304 estimated minus 394 hidden minus 793 sent.
  expect(text).toContain('| MCP server instructions | 1.1k | 0.1% |')
})
