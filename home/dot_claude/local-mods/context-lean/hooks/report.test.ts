import { expect, test } from 'claude-code/testing'
import { type Category, type Report, report as colored } from './report'

// The report's text without its terminal color codes.
const report = (measured: Report) => colored(measured).replace(/\u001b\[[0-9;]*m/g, '')

const CATEGORIES: Category[] = [
  { name: 'System prompt', tokens: 1505, kind: 'used', color: 'promptBorder' },
  { name: 'System tools', tokens: 9295, kind: 'used', color: 'inactive' },
  { name: 'MCP tools', tokens: 615, kind: 'used', color: 'cyan_FOR_SUBAGENTS_ONLY' },
  { name: 'MCP server instructions', tokens: 2304, kind: 'used', color: 'green_FOR_SUBAGENTS_ONLY' },
  { name: 'MCP tools (deferred)', tokens: 566678, kind: 'deferred', color: 'inactive' },
  { name: 'Messages', tokens: 296, kind: 'used', color: 'purple_FOR_SUBAGENTS_ONLY' },
  { name: 'Autocompact buffer', tokens: 33000, kind: 'buffer', color: 'inactive' },
  { name: 'Free space', tokens: 949735, kind: 'free', color: 'promptBorder' },
]
const BASE = { real: 19943, window: 1000000, estimate: 17265, model: 'claude-opus-5-5', categories: CATEGORIES }

test('draws the /context grid beside the header and categories', () => {
  const lines = report({ ...BASE, hidden: [], kept: [] }).split('\n')
  expect(lines[0]).toBe('Context Usage (context-lean)')
  // One square is 5k: System prompt ⛀, System tools ⛁ ⛁, MCP tools ⛀, server instructions ⛀, Messages ⛀,
  // and the 5.9k difference ⛁. The 33k buffer is 7 squares.
  expect(lines[1]).toBe('⛀ ⛁ ⛁ ⛀ ⛀ ⛀ ⛁ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶   claude-opus-5-5')
  expect(lines[2]).toContain('   19.9k/1m tokens (2%), real')
  expect(lines[10]).toMatch(/^(⛶ ){13}⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝/)
  expect(lines.some(line => line.endsWith('⛶ Free space: 947.1k (94.7%)'))).toBe(true)
  expect(lines.some(line => line.includes('MCP tools (deferred)'))).toBe(false)
})

test('ends with a savings section and one section per kind of hidden item', () => {
  const text = report({
    ...BASE,
    hidden: [
      { label: 'Datadog tool names', items: 412, tokens: 11203 },
      { label: 'Gmail tool names', items: 30, tokens: 635 },
      { label: 'Workflow description', items: 1, tokens: 1950 },
      { label: 'Notion server notes', items: 1, tokens: 394 },
    ],
    kept: [{ label: 'Atlassian MCP server notes (sent on first use)', items: 1, tokens: 793 }],
  })
  expect(text).toContain('Saved by context-lean · 14.2k tokens (41.6%)\n└ Without context-lean: 34.1k tokens\n└ /context estimate: 17.3k tokens')
  expect(text).toContain('Hidden tool names · 11.8k tokens\n└ Datadog · 412 names · 11.2k tokens\n└ Gmail · 30 names · 635 tokens')
  expect(text).toContain('Hidden tool descriptions · 1.9k tokens\n└ Workflow · 1 tool · 1.9k tokens')
  expect(text).toContain('Hidden server notes · 394 tokens\n└ Notion · 1 server · 394 tokens')
  expect(text).toContain('Server notes sent on first use · 793 tokens\n└ Atlassian MCP · 1 server · 793 tokens')
  expect(text).not.toContain('kept in the prompt')
})

test('shows uncounted rows and skips the estimate line without one', () => {
  const text = report({ ...BASE, estimate: undefined, hidden: [{ label: 'Gmail tool names', items: 3, tokens: undefined }], kept: [] })
  expect(text).toContain('└ Gmail · 3 names · not counted')
  expect(text).not.toContain('/context estimate')
})

test('says when no breakdown is available', () => {
  const text = report({ ...BASE, categories: [], hidden: [], kept: [] })
  expect(text).toContain('(no breakdown available)')
})

test('puts a note above the report', () => {
  const text = report({ ...BASE, hidden: [], kept: [], note: 'From your last report.' })
  expect(text.startsWith('From your last report.\n\nContext Usage (context-lean)')).toBe(true)
})

test('lists /context categories as estimated, plus the difference from the real total', () => {
  const text = report({ ...BASE, hidden: [{ label: 'Workflow description', items: 1, tokens: 1295 }], kept: [{ label: 'Atlassian MCP server notes', items: 1, tokens: 793 }] })
  expect(text).toContain('Estimated usage by category')
  expect(text).toContain('⛁ System tools: 9.3k tokens (0.9%)')
  expect(text).toContain('⛁ MCP server instructions: 2.3k tokens (0.2%)')
  // 19,943 real minus 14,015 estimated.
  expect(text).toContain('⛁ Difference from the real total: 5.9k tokens (0.6%)')
  expect(text.indexOf('Difference')).toBeLessThan(text.indexOf('Free space'))
  expect(text.indexOf('Free space')).toBeLessThan(text.indexOf('Autocompact buffer'))
  expect(text).toContain('Server notes kept in the prompt · 793 tokens\n└ Atlassian MCP · 1 server · 793 tokens')
})

test('folds the smallest rows of a long section into one line', () => {
  const hidden = Array.from({ length: 10 }, (_, i) => ({ label: `Server${i} tool names`, items: 2, tokens: 100 - i }))
  const text = report({ ...BASE, hidden, kept: [] })
  expect(text).toContain('└ Server0 · 2 names · 100 tokens')
  expect(text).toContain('└ Server6 · 2 names · 94 tokens')
  expect(text).not.toContain('Server7 ·')
  // Servers 7 to 9: 93 + 92 + 91 tokens.
  expect(text).toContain('└ 3 more · 6 names · 276 tokens')
})

test('fills the grid when the real total is over the window or the window is unknown', () => {
  for (const window of [1000000, 0]) {
    const lines = report({ ...BASE, real: 1003000, window, hidden: [], kept: [] }).split('\n')
    expect(lines[1]).not.toContain('⛶')
    expect(lines[10].startsWith('⛁ ⛁ ⛁')).toBe(true)
  }
})

test('shades hidden tokens as boxes after the used squares, with a legend line', () => {
  const lines = report({ ...BASE, hidden: [{ label: 'Datadog tool names', items: 415, tokens: 11133 }, { label: 'Workflow description', items: 1, tokens: 7300 }], kept: [] }).split('\n')
  // 7 used squares as above; 18,433 hidden is 4 more.
  expect(lines[1].startsWith('⛀ ⛁ ⛁ ⛀ ⛀ ⛀ ⛁ ⛋ ⛋ ⛋ ⛋ ⛶')).toBe(true)
  const legend = lines.findIndex(line => line.endsWith('⛋ Hidden by context-lean: 18.4k tokens (1.8%)'))
  const free = lines.findIndex(line => line.includes('⛶ Free space'))
  expect(legend).toBeGreaterThan(0)
  expect(legend + 1).toBe(free)
})

test("colors squares and legend symbols with /context's colors, and hidden tokens in their own", () => {
  const text = colored({ ...BASE, hidden: [{ label: 'Datadog tool names', items: 415, tokens: 11133 }], kept: [] })
  expect(text).toContain('\u001b[38;5;244m⛀\u001b[39m')
  expect(text).toContain('\u001b[38;5;35m⛁\u001b[39m MCP server instructions: ')
  expect(text).toContain('\u001b[38;5;140m⛁\u001b[39m Messages: ')
  expect(text).toContain('\u001b[38;5;208m⛋\u001b[39m Hidden by context-lean: ')
  expect(text).toContain('\u001b[38;5;208m⛋\u001b[39m \u001b[38;5;208m⛋\u001b[39m')
})

test('leaves out the difference row when the estimate matches the real total', () => {
  const text = report({ ...BASE, real: 14015, hidden: [], kept: [] })
  expect(text).not.toContain('Difference from the real total')
})
