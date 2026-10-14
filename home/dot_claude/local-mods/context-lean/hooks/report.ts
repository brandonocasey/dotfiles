// Text that context-lean kept out of (or left in) the prompt, grouped into one report row.
export type Row = { label: string; texts: Map<string, string> }
// An estimate stands in for text the next message will send: the ping's turn sends no tool list or server notes.
export type Counted = { label: string; items: number; tokens: number | undefined; isEstimate?: boolean }
// One /context category, as the engine's usage breakdown reports it.
export type Category = { name: string; tokens: number; kind: string; color?: string }
export type Report = {
  real: number
  // The usable window, which a setting such as autoCompactWindow can make smaller than the model's.
  window: number
  modelWindow?: number
  estimate: number | undefined
  model: string
  categories: Category[]
  hidden: Counted[]
  kept: Counted[]
  // The usage breakdown's lists behind the built-in /context's sections.
  inventory?: Inventory
}
export type Inventory = {
  mcpTools?: { name: string; serverName: string; tokens: number; isLoaded?: boolean }[]
  agents?: { agentType: string; source: string; tokens: number }[]
  memoryFiles?: { path: string; type: string; tokens: number }[]
  skills?: { totalSkills: number; includedSkills: number; tokens: number; skillFrontmatter: { name: string; source: string; tokens: number }[] }
  systemTools?: { name: string; tokens: number }[]
  // Built-in tools sent in full, from the mod's own record, since the breakdown may leave systemTools out.
  systemToolNames?: string[]
  systemPromptSections?: { name: string; tokens: number }[]
  messageBreakdown?: {
    toolCallTokens: number
    toolResultTokens: number
    attachmentTokens: number
    assistantMessageTokens: number
    userMessageTokens: number
    attachmentsByType: { name: string; tokens: number }[]
  }
}

// Marks notes that were hidden from the prompt and later sent with a tool result.
export const SENT = ' (sent on first use)'
// The row of built-in agent descriptions replaced with one-line summaries.
export const AGENTS = 'Built-in agent descriptions (shortened)'
// Rows of attachment text kept out of every request: the agent listing, email context, auto mode note, and environment lines.
const AGENT_LISTING = 'Agent listing (moved to the Agent tool)'
export const TRIMMED = new Set([AGENT_LISTING, 'Email context', 'Auto mode note', 'Environment lines'])
const MCP_NOTES = 'MCP server instructions'
const MESSAGES = 'Messages'
// /context's categories shown under another name. Memory files covers CLAUDE.md and other loaded markdown.
export const RENAMED: Record<string, string> = { 'Memory files': 'Memory & Markdown' }
const GAP = 'Difference from real'
const SAVED_SECTION = 'Saved by context-lean'

// /context's number styles: 10, 1.5k, 566.7k, 1m; 0.2%; 1%.
const short = (n: number) => {
  const sign = n < 0 ? '-' : ''
  const size = Math.abs(n)
  const scaled = (value: number, unit: string) => `${sign}${value.toFixed(1).replace(/\.0$/, '')}${unit}`
  if (size >= 1_000_000) return scaled(size / 1_000_000, 'm')
  if (size >= 1000) return scaled(size / 1000, 'k')

  return `${sign}${size}`
}
const percent = (part: number, whole: number) => `${whole === 0 ? '0.0' : ((part / whole) * 100).toFixed(1)}%`
const wholePercent = (part: number, whole: number) => `${whole === 0 ? 0 : Math.round((part / whole) * 100)}%`
const sum = (rows: Counted[]) => rows.reduce((total, row) => total + (row.tokens ?? 0), 0)

const NOTES = ' server notes'
const isNotes = (label: string) => label.endsWith(NOTES)
const isSentNotes = (label: string) => label.endsWith(`${NOTES}${SENT}`)
const isConnectorDescriptions = (label: string) => label.endsWith(' tool descriptions')
const isBuiltInDescription = (label: string) => label.endsWith(' description')

// /context's own estimates, plus the gap to the real total. Interactive and headless sessions estimate
// deferred tools differently, so individual categories are left as /context reports them, except two:
// /context counts every connected server's notes, sent or not, so that row shows the notes kept in the prompt.
// /context computes Messages as max(0, real total minus the other rows) plus messages sent since the last request.
// Since /context's notes row counts notes context-lean holds back, that Messages comes out short by them; the real
// tokens no row accounts for are added back to Messages, which keeps the estimate for messages since the last request.
// Only a negative gap, where the rows' estimates exceed the real total, keeps a difference row.
const categoriesOf = ({ real, window, categories: reported, kept }: Report) => {
  const inPrompt = sum(kept.filter(row => isNotes(row.label)))
  const others = reported.filter(row => row.kind === 'used' && row.name !== MESSAGES).reduce((all, row) => all + row.tokens, 0)
  const messages = reported.find(row => row.name === MESSAGES)
  // The estimated part of /context's Messages since the last request, which the real total does not include yet.
  const pending = (messages?.tokens ?? 0) - Math.min(messages?.tokens ?? 0, Math.max(0, real - others))
  const categories = reported.flatMap(row => {
    if (row.name in RENAMED) return [{ ...row, name: RENAMED[row.name] ?? row.name }]
    if (row.name === MCP_NOTES) return [{ ...row, tokens: inPrompt }]
    if (row.name === MESSAGES && row.tokens === 0) return []

    return [row]
  })
  const total = (kind: string) => categories.filter(row => row.kind === kind).reduce((all, row) => all + row.tokens, 0)
  const gap = real - (total('used') - pending)
  const free: Category = { name: 'Free space', tokens: Math.max(0, window - real - total('buffer')), kind: 'free' }
  const used = categories.filter(row => row.kind === 'used')
  if (gap > 0) {
    const at = used.findIndex(row => row.name === MESSAGES)
    if (at !== -1) used[at] = { ...used[at]!, tokens: used[at]!.tokens + gap }
    else used.push({ name: MESSAGES, tokens: gap, kind: 'used', color: 'purple_FOR_SUBAGENTS_ONLY' })
  }

  // In /context's order: what is used, then free space, then the autocompact buffer.
  return [...used, ...(gap < 0 ? [{ name: GAP, tokens: gap, kind: 'used' }] : []), free, ...categories.filter(row => row.kind === 'buffer')]
}

// /context's colors, as 256-color terminal codes, by the theme names its usage breakdown reports.
// cyan_FOR_SUBAGENTS_ONLY (MCP tools) was not seen in a live /context; 37 is a guess.
const COLORS: Record<string, number> = {
  promptBorder: 244,
  inactive: 246,
  permission: 153,
  claude: 174,
  warning: 220,
  purple_FOR_SUBAGENTS_ONLY: 140,
  green_FOR_SUBAGENTS_ONLY: 35,
  cyan_FOR_SUBAGENTS_ONLY: 37,
}
const GRAY = 246
// Hidden tokens get a color no /context category uses.
const HIDDEN = 208
// /context draws these rows in grays close to free space, so they get colors of their own that no other row uses.
const BY_NAME: Record<string, number> = { 'System prompt': 69, 'System tools': 150, [GAP]: 201 }
const paint = (color: number, text: string) => `\u001b[38;5;${color}m${text}\u001b[39m`
const colorOf = (category: Category) => BY_NAME[category.name] ?? COLORS[category.color ?? ''] ?? GRAY

// /context's grid over the usable window, sized as /context sizes it: 10 rows of 20 squares for a window of 1m or more,
// 10 of 10 below that, and 5 columns in a terminal under 80 columns wide (with 5 rows below 1m). Each used category
// fills its share in its color, a full square ⛁ or a partial one ⛀. Hidden squares follow as open squares ⛶ in their own
// color: space that would be used without context-lean and is still free with it.
const SYMBOL: Record<string, string> = { used: '⛁', partial: '⛀', hidden: '⛶', free: '⛶', buffer: '⛝', removed: '⛝' }
// Squares of the model's window past the usable one, which can never be used: crossed like the buffer, in a dull red.
const REMOVED = 131
type Cell = { symbol: string; color: number }
const sizeOf = (window: number, columns: number | undefined) => {
  const narrow = columns !== undefined && columns < 80
  const large = window >= 1_000_000

  return { rows: narrow && !large ? 5 : 10, cols: narrow ? 5 : large ? 20 : 10 }
}
// `cut` tokens of the covered window can never be used; they take the last squares.
const grid = (categories: Category[], saved: number, window: number, size: { rows: number; cols: number }, cut = 0) => {
  const { rows, cols } = size
  const squares = rows * cols
  const per = window / squares
  const buffer = categories.filter(row => row.kind === 'buffer').reduce((all, row) => all + row.tokens, 0)
  // An unknown window fills the grid instead of failing.
  const removed = window > 0 ? Math.min(squares, Math.round(cut / per)) : 0
  const reserved = window > 0 ? Math.min(squares - removed, Math.round(buffer / per)) : 0
  const used: Cell[] = categories
    .filter(row => row.kind === 'used' && row.tokens > 0)
    .flatMap(row => {
      const share = window > 0 ? row.tokens / per : squares
      return Array(Math.max(1, Math.round(share))).fill({ symbol: share >= 1 ? SYMBOL.used : SYMBOL.partial, color: colorOf(row) })
    })
    .slice(0, squares - removed - reserved)
  const hidden = window > 0 ? Math.max(0, Math.min(squares - removed - reserved - used.length, Math.round(saved / per))) : 0
  const cells: Cell[] = [
    ...used,
    ...Array(hidden).fill({ symbol: SYMBOL.hidden, color: HIDDEN }),
    ...Array(squares - removed - reserved - used.length - hidden).fill({ symbol: SYMBOL.free, color: GRAY }),
    ...Array(reserved).fill({ symbol: SYMBOL.buffer, color: GRAY }),
    ...Array(removed).fill({ symbol: SYMBOL.removed, color: REMOVED }),
  ]

  return Array.from({ length: rows }, (_, row) =>
    cells
      .slice(row * cols, (row + 1) * cols)
      .map(cell => paint(cell.color, cell.symbol))
      .join(' '),
  )
}

// One "└" section per kind of hidden item, largest first, like /context's MCP tools and Skills sections.
// Sections longer than SECTION_ROWS fold the smallest rows into one "more" line.
const SECTION_ROWS = 8
const plural = (count: number, unit: string) => `${count} ${unit}${count === 1 ? '' : 's'}`
const section = (title: string, rows: Counted[], name: (label: string) => string, unit: string) => {
  if (rows.length === 0) return []
  const sorted = [...rows].sort((a, b) => (b.tokens ?? 0) - (a.tokens ?? 0))
  const shown = sorted.length > SECTION_ROWS ? sorted.slice(0, SECTION_ROWS - 1) : sorted
  const rest = sorted.slice(shown.length)
  const lines = shown.map(row => `└ ${name(row.label)} · ${plural(row.items, unit)} · ${row.tokens === undefined ? 'not counted' : `${short(row.tokens)} tokens`}`)
  const more = rest.length === 0 ? [] : [`└ ${rest.length} more · ${plural(rest.reduce((all, row) => all + row.items, 0), unit)} · ${short(sum(rest))} tokens`]

  return ['', heading(title, sum(rows)), ...[...lines, ...more].map(line => paint(GRAY, line))]
}
const bold = (text: string) => `\u001b[1m${text}\u001b[22m`
// A section heading in /context's style: the title in bold, its total muted.
const heading = (title: string, tokens: number) => `${bold(title)}${paint(GRAY, ` · ${short(tokens)} tokens`)}`
const without = (suffix: string) => (label: string) => label.slice(0, label.length - suffix.length)

// One line for the model in place of the report, which only the person sees.
export const summary = ({ real, hidden }: Report) => `Context: ${short(real)} real tokens; context-lean hid ${short(sum(hidden))}.`

// A model ID's family and version, as Claude Code names the model: claude-opus-5-5 is Opus 5.5. IDs of another shape
// have no name.
const MODEL_ID = /^claude-([a-z]+)-(\d+(?:-\d{1,2})?)(?:-\d{8})?(?:\[[^\]]*\])?$/
const nameOf = (id: string) => {
  const [, family, version] = MODEL_ID.exec(id) ?? []

  return family === undefined || version === undefined ? undefined : `${family[0].toUpperCase()}${family.slice(1)} ${version.replace('-', '.')}`
}

// The visible width of a line, without its color codes.
const widthOf = (text: string) => [...text.replace(/\u001b\[[0-9;]*m/g, '')].length

// The built-in /context's sections, built from the usage breakdown, since the mod cannot run the built-in command:
// a heading, then one summary line, or with `detail` one line per server, agent, file or skill.
const HOME = /^\/Users\/[^/]+|^\/home\/[^/]+/
const inventorySections = ({ mcpTools = [], agents = [], memoryFiles = [], skills, systemTools = [], systemToolNames = [], systemPromptSections = [], messageBreakdown }: Inventory, detail: boolean, toolTokens: number) => {
  const block = (title: string, where: string, rows: Counted[], unit: string, total: { items: number; tokens: number }) =>
    rows.length === 0 && total.items === 0
      ? []
      : [
          [
            `${bold(title)}${paint(GRAY, ` · ${where}`)}`,
            ...(detail ? section('', rows, label => label, unit).slice(2) : [paint(GRAY, `└ ${plural(total.items, unit)} · ${short(total.tokens)} tokens`)]),
          ],
        ]
  // MCP tools count only once loaded; deferred ones cost nothing until then.
  const loaded = (tool: { tokens: number; isLoaded?: boolean }) => (tool.isLoaded === true ? tool.tokens : 0)
  const servers = [...new Set(mcpTools.map(tool => tool.serverName))].map(server => {
    const tools = mcpTools.filter(tool => tool.serverName === server)
    return { label: server, items: tools.length, tokens: tools.reduce((all, tool) => all + loaded(tool), 0) }
  })
  const sumOf = (rows: { tokens: number }[]) => rows.reduce((all, row) => all + row.tokens, 0)

  const each = (rows: { name: string; tokens: number }[]) => rows.map(row => ({ label: row.name, items: 1, tokens: row.tokens }))
  // Messages by kind, estimated; with `detail`, attachments by type too.
  const kinds = messageBreakdown
    ? [
        { label: 'Your messages', tokens: messageBreakdown.userMessageTokens },
        { label: "Claude's messages", tokens: messageBreakdown.assistantMessageTokens },
        { label: 'Tool calls', tokens: messageBreakdown.toolCallTokens },
        { label: 'Tool results', tokens: messageBreakdown.toolResultTokens },
        { label: 'Attachments', tokens: messageBreakdown.attachmentTokens },
      ].filter(row => row.tokens > 0)
    : []
  const attachments = detail ? (messageBreakdown?.attachmentsByType ?? []).filter(row => row.tokens > 0).sort((a, b) => b.tokens - a.tokens) : []
  const messages =
    kinds.length === 0
      ? []
      : [
          [
            `${bold('Messages')}${paint(GRAY, ' · estimated')}`,
            ...kinds.map(row => paint(GRAY, `└ ${row.label} · ${short(row.tokens)} tokens`)),
            ...section('', each(attachments), label => label, 'attachment').slice(2).map(line => `  ${line}`),
          ],
        ]

  return [
    ...block('System prompt', 'built in', each(systemPromptSections), 'section', { items: systemPromptSections.length, tokens: sumOf(systemPromptSections) }),
    ...(systemTools.length > 0
      ? block('System tools', 'built in', each(systemTools), 'tool', { items: systemTools.length, tokens: sumOf(systemTools) })
      : systemToolNames.length === 0
        ? []
        : [
            [
              `${bold('System tools')}${paint(GRAY, ' · built in')}`,
              // Without per-tool counts, the total is /context's System tools row.
              ...(detail
                ? [...systemToolNames].sort().map(name => paint(GRAY, `└ ${name}`))
                : [paint(GRAY, `└ ${plural(systemToolNames.length, 'tool')} · ${short(toolTokens)} tokens`)]),
            ],
          ]),
    ...block('MCP tools', '/mcp (loaded on-demand)', servers, 'tool', { items: mcpTools.length, tokens: servers.reduce((all, row) => all + row.tokens, 0) }),
    ...block('Custom agents', '.claude/agents/', agents.map(agent => ({ label: agent.agentType, items: 1, tokens: agent.tokens })), 'agent', { items: agents.length, tokens: sumOf(agents) }),
    ...block(RENAMED['Memory files'] ?? 'Memory files', '/memory', memoryFiles.map(file => ({ label: file.path.replace(HOME, '~'), items: 1, tokens: file.tokens })), 'file', {
      items: memoryFiles.length,
      tokens: sumOf(memoryFiles),
    }),
    ...block('Skills', '/skills', (skills?.skillFrontmatter ?? []).map(skill => ({ label: skill.name, items: 1, tokens: skill.tokens })), 'skill', {
      items: skills?.includedSkills ?? 0,
      tokens: skills?.tokens ?? 0,
    }),
    ...messages,
  ]
}

// The section a saved row belongs to: System tools for built-in tools, MCP tools for connector and local server rows,
// Custom agents for agent rows, and a section of its own for trimmed attachments.
const homeOf = (label: string) => {
  if (label === AGENTS || label === AGENT_LISTING) return 'Custom agents'
  if (label.startsWith('Built-in tool') || isBuiltInDescription(label)) return 'System tools'
  if (TRIMMED.has(label)) return SAVED_SECTION

  return 'MCP tools'
}

// `columns` is the width the report is drawn in. Rows of squares under the grid, at its scale, stand for the part of the
// model's window past the usable one. Percentages are of the space usable before autocompact: the window less its
// buffer. Without `detail`, what context-lean saved is one line per kind, like /context's sections; with it, one
// section per kind lists each item.
export const report = (measured: Report, columns?: number, detail = false) => {
  const { real, window, modelWindow, estimate, model, hidden, kept } = measured
  const saved = sum(hidden)
  const total = real + saved
  const categories = categoriesOf(measured)
  const buffer = categories.filter(row => row.kind === 'buffer').reduce((all, row) => all + row.tokens, 0)
  const usable = buffer > 0 && buffer < window ? window - buffer : window
  const removed = modelWindow === undefined ? 0 : modelWindow - window
  const line = (symbol: string, color: number, name: string, value: string) => `${paint(color, symbol)} ${name}: ${paint(GRAY, value)}`
  const side = [
    // The model's name, then its muted ID.
    nameOf(model) === undefined ? model : `${nameOf(model)} ${paint(GRAY, model)}`,
    paint(GRAY, `${short(real)}/${short(usable)} real (${wholePercent(real, usable)})`),
    `${paint(HIDDEN, bold(`${short(saved)} saved (${wholePercent(saved, total)})`))}${paint(GRAY, ` · ${short(total)} without`)}`,
    '',
    `\u001b[3m${paint(GRAY, 'Estimated usage by category')}\u001b[23m`,
    ...(measured.categories.length === 0
      ? [paint(GRAY, '(no breakdown available)')]
      : categories.flatMap(row => [
          row.kind === 'buffer'
            ? paint(GRAY, `${SYMBOL.buffer} ${row.name}: ${short(row.tokens)} (${percent(row.tokens, window)} of ${short(window)})`)
            : line(SYMBOL[row.kind] ?? SYMBOL.used, colorOf(row), row.name, `${short(row.tokens)} (${percent(row.tokens, usable)})`),
          // Saved tokens are part of the free space, not a slice beside it; the grid draws them as its first free squares.
          ...(row.kind === 'free' ? [`${paint(GRAY, '⎿')} ${line(SYMBOL.hidden, HIDDEN, 'Saved', `${short(saved)} (${percent(saved, usable)})`)}`] : []),
        ])),
    // The part of the model's window past the usable one, drawn under the grid, as a share of the model's window.
    ...(removed > 0 ? [`${paint(REMOVED, SYMBOL.removed)} ${paint(GRAY, `Cut by autocompact window: ${short(removed)} (${percent(removed, modelWindow ?? 0)} of ${short(modelWindow ?? 0)})`)}`] : []),
  ]
  // With part of the model's window cut, the grid covers the whole model window, sized for it, so the cut part takes
  // its true share of the last squares.
  const covered = removed > 0 ? window + removed : window
  const size = sizeOf(covered, columns)
  const squares = grid(categories, saved, covered, size, removed)
  const gridWidth = size.cols * 2 - 1
  const top = Array.from({ length: Math.max(squares.length, side.length) }, (_, i) => {
    const row = squares[i] ?? ''
    return `${row}${' '.repeat(gridWidth - widthOf(row))}   ${side[i] ?? ''}`.trimEnd()
  })
  const kinds = [
    { title: 'Tool names', rows: hidden.filter(row => row.label.endsWith(' tool names')), name: without(' tool names'), unit: 'name' },
    { title: 'Tool descriptions', rows: hidden.filter(row => isBuiltInDescription(row.label) || isConnectorDescriptions(row.label)), name: (label: string) => label.replace(/ tool descriptions$| description$/, ''), unit: 'tool' },
    { title: 'Server notes', rows: hidden.filter(row => isNotes(row.label)), name: without(NOTES), unit: 'server' },
    { title: 'Agent descriptions (shortened)', rows: hidden.filter(row => row.label === AGENTS), name: () => 'Built-in agents', unit: 'agent' },
    { title: 'Trimmed attachments', rows: hidden.filter(row => TRIMMED.has(row.label)), name: (label: string) => label, unit: 'item' },
  ].filter(kind => kind.rows.length > 0)
  const parts = kinds.flatMap(kind =>
    [...new Set(kind.rows.map(row => homeOf(row.label)))].map(home => ({
      ...kind,
      ...(home === 'Custom agents' && kind.title === 'Trimmed attachments' ? { title: 'Agent listing (moved to the Agent tool)', unit: 'listing' } : {}),
      home,
      rows: kind.rows.filter(row => homeOf(row.label) === home),
    })),
  )
  const items = (rows: Counted[]) => rows.reduce((all, row) => all + row.items, 0)
  // A kind's lines: one summary line, or with `detail` its items, folded past SECTION_ROWS.
  // In a built-in section they nest under its orange "Saved by context-lean" line; in their own section they do not.
  const linesOf = (part: (typeof parts)[number]) =>
    (detail
      ? section('', part.rows, part.name, part.unit).slice(2)
      : [paint(GRAY, `└ ${part.title} · ${plural(items(part.rows), part.unit)} · ${short(sum(part.rows))} tokens${part.rows.every(row => row.isEstimate) ? ' (estimated)' : ''}`)]
    ).map(line =>
      part.home === SAVED_SECTION ? line : `  ${line}`,
    )
  const savedIn = (home: string) => {
    const mine = parts.filter(part => part.home === home).sort((a, b) => sum(b.rows) - sum(a.rows))
    return { tokens: mine.reduce((all, part) => all + sum(part.rows), 0), lines: mine.flatMap(linesOf), isEstimate: mine.length > 0 && mine.every(part => part.rows.every(row => row.isEstimate)) }
  }
  // Notes context-lean still sends are not savings; they are listed as plain lines in the MCP section with `detail`.
  const notesKept = detail
    ? [
        ...section('Server notes sent on first use', kept.filter(row => isSentNotes(row.label)), without(`${NOTES}${SENT}`), 'server'),
        ...section('Server notes kept in the prompt', kept.filter(row => isNotes(row.label)), without(NOTES), 'server'),
      ].flatMap(line => (line === '' ? [] : [line.startsWith('\u001b[1m') ? paint(GRAY, `└ ${line.replace(/\u001b\[[0-9;]*m/g, '')}`) : `  ${line}`]))
    : []
  // The built-in /context's sections, each a block of lines after a heading such as "MCP tools · /mcp".
  const plain = (text: string) => text.replace(/\u001b\[[0-9;]*m/g, '').trim()
  const sections = inventorySections(measured.inventory ?? {}, detail, categories.find(row => row.name === 'System tools')?.tokens ?? 0)
  for (const home of ['System tools', 'MCP tools', 'Custom agents']) {
    const { tokens, lines, isEstimate } = savedIn(home)
    const extra = home === 'MCP tools' ? notesKept : []
    // Before the first message (the ping's turn sends no tool list or server notes), MCP has nothing hidden yet.
    const none = home === 'MCP tools' && lines.length === 0 && (measured.inventory?.mcpTools?.length ?? 0) > 0
    if (none) {
      const at = sections.findIndex(block => plain(block[0] ?? '').startsWith(home))
      if (at !== -1) sections[at] = [sections[at]![0]!, paint(HIDDEN, '└ Saved by context-lean · none yet: the tool list is first sent with your next message'), ...extra, ...sections[at]!.slice(1)]
      continue
    }
    if (lines.length === 0 && extra.length === 0) continue
    const total = isEstimate ? `~${short(tokens)} tokens (estimated: first sent with your next message)` : `${short(tokens)} tokens`
    const merged = [...(lines.length === 0 ? [] : [paint(HIDDEN, bold(`└ Saved by context-lean · ${total}`)), ...lines]), ...extra]
    const at = sections.findIndex(block => plain(block[0] ?? '').startsWith(home))
    if (at === -1) sections.push([bold(home), ...merged])
    else sections[at] = [sections[at]![0]!, ...merged, ...sections[at]!.slice(1)]
  }
  const rest = savedIn(SAVED_SECTION)
  if (rest.lines.length > 0) sections.push([`${paint(HIDDEN, bold(SAVED_SECTION))}${paint(GRAY, ` · ${short(rest.tokens)} tokens`)}`, ...rest.lines])
  const footnote = detail
    ? [
        '',
        ...(estimate === undefined ? [] : [paint(GRAY, `/context estimate: ${short(estimate)} tokens`)]),
        paint(GRAY, `Saved items are counted with ${model}'s tokenizer; built-in tools count their descriptions, not their input schemas. Categories are /context's estimates. ${MCP_NOTES} counts only notes still sent in the prompt, and Messages gets back what /context took off it for the rest.`),
      ]
    : ['', paint(GRAY, '/context all to expand')]
  const lines = [bold('Context-lean Usage'), ...top, ...sections.flatMap(block => ['', ...block]), ...footnote]

  return lines.join('\n')
}
