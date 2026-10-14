import { expect, test } from 'claude-code/testing'
import { type Category, type Report, report as colored } from './report'

// The report's text without its terminal color codes.
const report = (measured: Report, columns?: number) => colored(measured, columns).replace(/\u001b\[[0-9;]*m/g, '')
// The /context all form, with each saved item listed.
const full = (measured: Report) => colored(measured, undefined, true).replace(/\u001b\[[0-9;]*m/g, '')

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
  expect(lines[0]).toBe('Context-lean Usage')
  // One square is 5k: System prompt ⛀, System tools ⛁ ⛁, MCP tools ⛀, and Messages ⛁ ⛁: its 296 plus the 8.2k
  // /context took off it for unsent notes. No server notes are kept, so server instructions has no square. The 33k
  // buffer is 7 squares.
  expect(lines[1]).toBe('⛀ ⛁ ⛁ ⛀ ⛁ ⛁ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶   Opus 5.5 claude-opus-5-5')
  expect(lines[2]).toContain('   19.9k/967k real (2%)')
  expect(lines[10]).toMatch(/^(⛶ ){13}⛝ ⛝ ⛝ ⛝ ⛝ ⛝ ⛝/)
  expect(lines.some(line => line.endsWith('⛶ Free space: 947.1k (97.9%)'))).toBe(true)
  expect(lines.some(line => line.includes('MCP tools (deferred)'))).toBe(false)
})

test('names the model before its muted ID, and shows other IDs as given', () => {
  expect(colored({ ...BASE, hidden: [], kept: [] })).toContain('Opus 5.5 \u001b[38;5;246mclaude-opus-5-5\u001b[39m')
  expect(report({ ...BASE, model: 'claude-haiku-5-5-20261001[1m]', hidden: [], kept: [] })).toContain('Haiku 5.5 claude-haiku-5-5-20261001[1m]')
  expect(report({ ...BASE, model: 'claude-fable-5-20261001', hidden: [], kept: [] }).split('\n')[1]).toMatch(/   Fable 5 claude-fable-5-20261001$/)
  expect(report({ ...BASE, model: 'claude-fable-5', hidden: [], kept: [] }).split('\n')[1]).toMatch(/   Fable 5 claude-fable-5$/)
  expect(report({ ...BASE, model: 'custom-model', hidden: [], kept: [] }).split('\n')[1]).toMatch(/   custom-model$/)
})

test('puts savings in the System tools and MCP tools sections, and lists each item with all', () => {
  const measured = {
    ...BASE,
    hidden: [
      { label: 'Datadog tool names', items: 412, tokens: 11203 },
      { label: 'Gmail tool names', items: 30, tokens: 635 },
      { label: 'Workflow description', items: 1, tokens: 1950 },
      { label: 'Notion server notes', items: 1, tokens: 394 },
    ],
    kept: [{ label: 'Atlassian MCP server notes (sent on first use)', items: 1, tokens: 793 }],
  }
  const text = report(measured)
  expect(text).toContain('14.2k saved (42%) · 34.1k without')
  expect(text).toContain(
    '\n\nSystem tools\n└ Saved by context-lean · 1.9k tokens\n  └ Tool descriptions · 1 tool · 1.9k tokens\n\nMCP tools\n└ Saved by context-lean · 12.2k tokens\n  └ Tool names · 442 names · 11.8k tokens\n  └ Server notes · 1 server · 394 tokens\n\n/context all to expand',
  )
  expect(text).not.toContain('Datadog ·')
  expect(text).not.toContain('sent on first use')
  const all = full(measured)
  expect(all).toContain('\nMCP tools\n└ Saved by context-lean · 12.2k tokens\n  └ Datadog · 412 names · 11.2k tokens\n  └ Gmail · 30 names · 635 tokens\n  └ Notion · 1 server · 394 tokens')
  expect(all).toContain('\n└ Server notes sent on first use · 793 tokens\n  └ Atlassian MCP · 1 server · 793 tokens')
  expect(all).toContain('\n\nSystem tools\n└ Saved by context-lean · 1.9k tokens\n  └ Workflow · 1 tool · 1.9k tokens')
  expect(all).toContain('/context estimate: 17.3k tokens')
  expect(all).not.toContain('kept in the prompt')
  expect(all).not.toContain('/context all to expand')
})

test("builds the built-in /context's sections from the breakdown and merges savings into them, orange totals first", () => {
  const inventory = {
    mcpTools: [
      { name: 'mcp__gmail__search', serverName: 'Gmail', tokens: 300, isLoaded: true },
      { name: 'mcp__gmail__send', serverName: 'Gmail', tokens: 200 },
      { name: 'mcp__chrome-devtools__click', serverName: 'chrome-devtools', tokens: 246 },
    ],
    agents: [],
    memoryFiles: [{ path: '/Users/me/.claude/CLAUDE.md', type: 'User', tokens: 1900 }],
    skills: { totalSkills: 5, includedSkills: 4, tokens: 690, skillFrontmatter: [{ name: 'review', source: 'user', tokens: 90 }] },
  }
  const measured = { ...BASE, inventory, hidden: [{ label: 'Gmail tool names', items: 3, tokens: 60 }, { label: 'Email context', items: 1, tokens: 40 }], kept: [] }
  const strip = (text: string) => text.replace(/\u001b\[[0-9;]*m/g, '')
  const brief = colored(measured)
  // Only loaded MCP tools count; no agents means no agents section.
  expect(strip(brief)).toContain(
    '\n\nMCP tools · /mcp (loaded on-demand)\n└ Saved by context-lean · 60 tokens\n  └ Tool names · 3 names · 60 tokens\n└ 3 tools · 300 tokens\n\nMemory & Markdown · /memory\n└ 1 file · 1.9k tokens\n\nSkills · /skills\n└ 4 skills · 690 tokens\n\nSaved by context-lean · 40 tokens\n└ Trimmed attachments · 1 item · 40 tokens\n\n/context all to expand',
  )
  expect(strip(brief)).not.toContain('Custom agents ·')
  expect(brief).toContain('\u001b[38;5;208m\u001b[1m└ Saved by context-lean · 60 tokens\u001b[22m\u001b[39m')
  expect(brief).toContain('\u001b[38;5;208m\u001b[1mSaved by context-lean\u001b[22m\u001b[39m')
  const all = full(measured)
  expect(all).toContain('\n\nMCP tools · /mcp (loaded on-demand)\n└ Saved by context-lean · 60 tokens\n  └ Gmail · 3 names · 60 tokens\n└ Gmail · 2 tools · 300 tokens\n└ chrome-devtools · 1 tool · 0 tokens')
  expect(all).toContain('Memory & Markdown · /memory\n└ ~/.claude/CLAUDE.md · 1 file · 1.9k tokens')
  expect(all).toContain('Skills · /skills\n└ review · 1 skill · 90 tokens')
})

test('breaks down the system prompt, system tools and messages from the breakdown', () => {
  const inventory = {
    systemPromptSections: [{ name: 'Core instructions', tokens: 1200 }, { name: 'Environment', tokens: 300 }],
    systemTools: [{ name: 'Bash', tokens: 900 }, { name: 'Read', tokens: 400 }],
    messageBreakdown: { toolCallTokens: 0, toolResultTokens: 0, attachmentTokens: 1500, assistantMessageTokens: 40, userMessageTokens: 20, attachmentsByType: [{ name: 'skill_listing', tokens: 500 }, { name: 'deferred_tools_delta', tokens: 1000 }] },
  }
  const measured = { ...BASE, inventory, hidden: [{ label: 'Workflow description', items: 1, tokens: 1950 }], kept: [] }
  const text = report(measured)
  expect(text).toContain('\n\nSystem prompt · built in\n└ 2 sections · 1.5k tokens\n\nSystem tools · built in\n└ Saved by context-lean · 1.9k tokens\n  └ Tool descriptions · 1 tool · 1.9k tokens\n└ 2 tools · 1.3k tokens')
  // Kinds with no tokens are left out.
  expect(text).toContain("\n\nMessages · estimated\n└ Your messages · 20 tokens\n└ Claude's messages · 40 tokens\n└ Attachments · 1.5k tokens\n")
  const all = full(measured)
  expect(all).toContain('System prompt · built in\n└ Core instructions · 1 section · 1.2k tokens\n└ Environment · 1 section · 300 tokens')
  expect(all).toContain('└ Attachments · 1.5k tokens\n  └ deferred_tools_delta · 1 attachment · 1k tokens\n  └ skill_listing · 1 attachment · 500 tokens')
})

test('says MCP has nothing hidden yet when no MCP item was saved', () => {
  const inventory = { mcpTools: [{ name: 'mcp__gmail__search', serverName: 'Gmail', tokens: 300 }] }
  const text = report({ ...BASE, inventory, hidden: [{ label: 'Workflow description', items: 1, tokens: 1950 }], kept: [] })
  expect(text).toContain('MCP tools · /mcp (loaded on-demand)\n└ Saved by context-lean · none yet: the tool list is first sent with your next message\n└ 1 tool · 0 tokens')
})

test('shows uncounted rows and skips the estimate line without one', () => {
  const text = full({ ...BASE, estimate: undefined, hidden: [{ label: 'Gmail tool names', items: 3, tokens: undefined }], kept: [] })
  expect(text).toContain('└ Gmail · 3 names · not counted')
  expect(text).not.toContain('/context estimate')
})

test('says when no breakdown is available', () => {
  const text = report({ ...BASE, categories: [], hidden: [], kept: [] })
  expect(text).toContain('(no breakdown available)')
})

test('lists /context categories as estimated, with Messages given back what /context took off it', () => {
  const text = full({ ...BASE, hidden: [{ label: 'Workflow description', items: 1, tokens: 1295 }], kept: [{ label: 'Atlassian MCP server notes', items: 1, tokens: 793 }] })
  expect(text).toContain('Estimated usage by category')
  expect(text).toContain('⛁ System tools: 9.3k (1.0%)')
  // Only the 793 kept tokens of /context's 2,304 stay on the server instructions row.
  expect(text).toContain('⛁ MCP server instructions: 793 (0.1%)')
  // 296, plus 19,943 real minus 12,504 estimated.
  expect(text).toContain('⛁ Messages: 7.7k (0.8%)')
  expect(text).not.toContain('Difference from real')
  expect(text.indexOf('Messages:')).toBeLessThan(text.indexOf('Free space'))
  expect(text.indexOf('Free space')).toBeLessThan(text.indexOf('Autocompact buffer'))
  expect(text).toContain('\n└ Server notes kept in the prompt · 793 tokens\n  └ Atlassian MCP · 1 server · 793 tokens')
})

test('folds the smallest rows of a long section into one line', () => {
  const hidden = Array.from({ length: 10 }, (_, i) => ({ label: `Server${i} tool names`, items: 2, tokens: 100 - i }))
  const text = full({ ...BASE, hidden, kept: [] })
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

test('shades hidden tokens as boxes after the used squares, with a legend line under free space', () => {
  const lines = report({ ...BASE, hidden: [{ label: 'Datadog tool names', items: 415, tokens: 11133 }, { label: 'Workflow description', items: 1, tokens: 7300 }], kept: [] }).split('\n')
  // 6 used squares as above; 18,433 hidden is 4 more.
  expect(lines[1].startsWith('⛀ ⛁ ⛁ ⛀ ⛁ ⛁ ⛶ ⛶ ⛶ ⛶ ⛶')).toBe(true)
  // The hidden squares are open like free ones, told apart by color.
  const row = colored({ ...BASE, hidden: [{ label: 'Datadog tool names', items: 415, tokens: 11133 }, { label: 'Workflow description', items: 1, tokens: 7300 }], kept: [] }).split('\n')[1]
  expect(row.split('\u001b[38;5;208m⛶').length - 1).toBe(4)
  const free = lines.findIndex(line => line.includes('⛶ Free space'))
  expect(free).toBeGreaterThan(0)
  expect(lines[free + 1]?.endsWith('   ⎿ ⛶ Saved: 18.4k (1.9%)')).toBe(true)
})

test("colors squares and legend symbols with /context's colors, and hidden tokens and gray rows in their own", () => {
  const text = colored({ ...BASE, hidden: [{ label: 'Datadog tool names', items: 415, tokens: 11133 }], kept: [] })
  expect(text).toContain('\u001b[38;5;69m⛀\u001b[39m')
  expect(text).toContain('\u001b[38;5;69m⛁\u001b[39m System prompt: ')
  expect(text).toContain('\u001b[38;5;150m⛁\u001b[39m System tools: ')
  expect(text).toContain('\u001b[38;5;35m⛁\u001b[39m MCP server instructions: ')
  expect(text).toContain('\u001b[38;5;140m⛁\u001b[39m Messages: ')
  expect(text).toContain('\u001b[38;5;246m⎿\u001b[39m \u001b[38;5;208m⛶\u001b[39m Saved: ')
  expect(text).toContain('\u001b[38;5;208m⛶\u001b[39m \u001b[38;5;208m⛶\u001b[39m')
})

test('leaves out the difference row when the estimate matches the real total', () => {
  const text = report({ ...BASE, real: 14015, hidden: [], kept: [{ label: 'Atlassian MCP server notes', items: 1, tokens: 2304 }] })
  expect(text).not.toContain('Difference from real')
})

test('shows only notes kept in the prompt on the MCP server instructions row, and gives the rest back to Messages', () => {
  const text = report({ ...BASE, real: 14015, estimate: 14015, hidden: [{ label: 'Notion server notes', items: 1, tokens: 1304 }], kept: [{ label: 'chrome-devtools server notes', items: 1, tokens: 120 }] })
  expect(text).toContain('⛁ MCP server instructions: 120 (0.0%)')
  // The 2,184 of /context's 2,304 not kept go back to Messages: 296 + 2,184.
  expect(text).toContain('⛁ Messages: 2.5k (0.3%)')
  expect(text).not.toContain('Difference from real')
})

test('keeps messages since the last request in Messages, with the real tokens no row holds', () => {
  // The other rows (13,719) exceed the 12,000 real, so /context shows only the 296 since the last request; 12,000 real
  // minus 11,415 other rows without the notes adds 585.
  const text = report({ ...BASE, real: 12000, hidden: [], kept: [] })
  expect(text).toContain('⛁ Messages: 881 (0.1%)')
  expect(text).not.toContain('New messages')
  // /context's Messages is 12,000 real minus 11,700 other rows, plus 400 since the last request: nothing to add.
  const categories = [
    { name: 'System prompt', tokens: 1700, kind: 'used', color: 'promptBorder' },
    { name: 'System tools', tokens: 10000, kind: 'used', color: 'inactive' },
    { name: 'Messages', tokens: 700, kind: 'used', color: 'purple_FOR_SUBAGENTS_ONLY' },
  ]
  const exact = report({ ...BASE, real: 12000, categories, hidden: [], kept: [] })
  expect(exact).toContain('⛁ Messages: 700 (0.1%)')
  expect(exact).not.toContain('Difference from real')
})

test('adds a Messages row for real tokens no row holds when /context left it out, and a difference row only below 0', () => {
  const categories = CATEGORIES.filter(row => row.name !== 'Messages')
  const text = report({ ...BASE, real: 12000, categories, hidden: [], kept: [] })
  expect(text).toContain('⛁ Messages: 585 (0.1%)')
  expect(text).not.toContain('Difference from real')
  // The rows' estimates exceed 5,000 real by 6,415.
  const over = colored({ ...BASE, real: 5000, categories, hidden: [], kept: [] })
  expect(over).toContain('\u001b[38;5;201m⛁\u001b[39m Difference from real: \u001b[38;5;246m-6.4k')
  expect(over).not.toContain('Messages:')
})

test('renames Memory files to Memory & Markdown', () => {
  const categories = [{ name: 'Memory files', tokens: 1800, kind: 'used', color: 'claude' }]
  expect(report({ ...BASE, categories, hidden: [], kept: [] })).toContain('⛁ Memory & Markdown: 1.8k (0.2%)')
})

test('reports shortened agent descriptions in the Custom agents section', () => {
  const text = full({ ...BASE, hidden: [{ label: 'Built-in agent descriptions (shortened)', items: 3, tokens: 420 }], kept: [] })
  expect(text).toContain('\n\nCustom agents\n└ Saved by context-lean · 420 tokens\n  └ Built-in agents · 3 agents · 420 tokens')
  expect(text).not.toContain('\nMCP tools\n')
})

test('sizes the grid as /context does: 20 columns from 1m, 10 below, 5 in a narrow terminal', () => {
  const widthOfRow = (measured: Report, columns?: number) => report(measured, columns).split('\n')[1].split('   ')[0].split(' ').length
  expect(widthOfRow({ ...BASE, hidden: [], kept: [] })).toBe(20)
  expect(widthOfRow({ ...BASE, window: 433000, hidden: [], kept: [] })).toBe(10)
  const narrow = report({ ...BASE, window: 433000, hidden: [], kept: [] }, 70).split('\n')
  expect(narrow[1].split('   ')[0].split(' ').length).toBe(5)
  // Five rows of squares, then the side text alone, indented past the grid.
  expect(narrow[6].startsWith(' '.repeat(9))).toBe(true)
})

test('covers the whole model window when part is cut, with the cut part in its last squares', () => {
  const measured = { ...BASE, window: 433000, modelWindow: 1000000, hidden: [], kept: [] }
  const cut = '\u001b[38;5;131m⛝\u001b[39m'
  // A 1m grid: 20 by 10, 5k a square. 567k cut is 113 squares, the last 13 of row 5 and rows 6 to 10.
  const lines = colored(measured, 200).split('\n')
  const squares = lines.slice(1, 11).map(line => line.split('   ')[0]!)
  expect(squares[0]!.split(' ').length).toBe(20)
  expect(squares.join(' ').split(cut).length - 1).toBe(113)
  expect(squares[4]!.split(cut).length - 1).toBe(13)
  expect(squares.slice(5).every(row => row.split(cut).length - 1 === 20)).toBe(true)
  // Nothing is drawn under the grid.
  expect(lines.slice(11).some(line => line.includes(cut) && !line.includes('Cut by'))).toBe(false)
})

test('draws the usable window, with percentages of the space before the buffer, and names the model window', () => {
  const text = report({ ...BASE, window: 433000, modelWindow: 1000000, hidden: [], kept: [] })
  // 433k less the 33k buffer.
  expect(text).toContain('19.9k/400k real (5%)')
  expect(text).toContain('⛝ Cut by autocompact window: 567k (56.7% of 1m)')
  expect(text.indexOf('Autocompact buffer')).toBeLessThan(text.indexOf('Cut by autocompact window'))
  expect(text).toContain('Autocompact buffer: 33k (7.6% of 433k)')
  // 433,000 minus 19,943 real and the 33,000 buffer, of 400k.
  expect(text).toContain('Free space: 380.1k (95.0%)')
  expect(report({ ...BASE, modelWindow: 1000000, hidden: [], kept: [] })).not.toContain('Cut by autocompact window')
})
