// Text that context-lean kept out of (or left in) the prompt, grouped into one report row.
export type Row = { label: string; texts: Map<string, string> }
export type Counted = { label: string; items: number; tokens: number | undefined }
// One /context category, as the engine's usage breakdown reports it.
export type Category = { name: string; tokens: number; kind: string; color?: string }
export type Report = {
  real: number
  window: number
  estimate: number | undefined
  model: string
  categories: Category[]
  hidden: Counted[]
  kept: Counted[]
  note?: string
}

// The usage breakdown sizes the autocompact buffer within the autoCompactWindow setting's window (433k gives 33k),
// but the report draws the model's whole window (1m). The buffer is resized to everything past the point where
// compaction starts, which the breakdown reports as autoCompactThreshold.
const AUTOCOMPACT_BUFFER = 'Autocompact buffer'
export const withCompactThreshold = (categories: Category[], window: number, threshold: number | undefined) => {
  if (threshold === undefined || window <= 0) return categories
  const buffer = Math.max(0, window - threshold)

  return categories.map(row => (row.kind === 'buffer' && row.name === AUTOCOMPACT_BUFFER ? { ...row, tokens: buffer } : row))
}

// Marks notes that were hidden from the prompt and later sent with a tool result.
export const SENT = ' (sent on first use)'
// The row of built-in agent descriptions replaced with one-line summaries.
export const AGENTS = 'Built-in agent descriptions (shortened)'
// Rows of attachment text kept out of every request: the agent listing, email context, auto mode note, and environment lines.
export const TRIMMED = new Set(['Agent listing (moved to the Agent tool)', 'Email context', 'Auto mode note', 'Environment lines'])
const MCP_NOTES = 'MCP server instructions'
const MESSAGES = 'Messages'
const PENDING = 'Messages since the last request (estimated)'

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
// /context computes Messages as max(0, real total minus the other rows) plus messages sent since the last request,
// and leaves the row out at 0, so Messages is recomputed without the unsent notes. The estimated part since the last
// request gets its own row and stays out of the gap, since the real total does not include it yet.
const categoriesOf = ({ real, window, categories: reported, kept }: Report) => {
  const inPrompt = sum(kept.filter(row => isNotes(row.label)))
  const unsent = (reported.find(row => row.name === MCP_NOTES)?.tokens ?? inPrompt) - inPrompt
  const others = reported.filter(row => row.kind === 'used' && row.name !== MESSAGES).reduce((all, row) => all + row.tokens, 0)
  const messages = reported.find(row => row.name === MESSAGES)
  const pending = Math.max(0, (messages?.tokens ?? 0) - Math.max(0, real - others))
  const sent = Math.max(0, (messages?.tokens ?? 0) - pending - Math.max(0, real - others) + Math.max(0, real - others + unsent))
  const pendingRow: Category = { name: PENDING, tokens: pending, kind: 'used', color: 'purple_FOR_SUBAGENTS_ONLY' }
  const added: Category[] = messages === undefined && sent > 0 ? [{ name: MESSAGES, tokens: sent, kind: 'used', color: 'purple_FOR_SUBAGENTS_ONLY' }] : []
  const categories = [
    ...reported.flatMap(row => {
      if (row.name === MCP_NOTES) return [{ ...row, tokens: inPrompt }]
      if (row.name === MESSAGES) return [{ ...row, tokens: sent }, ...(pending > 0 ? [pendingRow] : [])]

      return [row]
    }),
    ...added,
  ]
  const total = (kind: string) => categories.filter(row => row.kind === kind).reduce((all, row) => all + row.tokens, 0)
  const gap: Category = { name: 'Difference from the real total', tokens: real - (total('used') - pending), kind: 'used' }
  const free: Category = { name: 'Free space', tokens: Math.max(0, window - real - total('buffer')), kind: 'free' }

  // In /context's order: what is used, then free space, then the autocompact buffer.
  return [...categories.filter(row => row.kind === 'used'), ...(gap.tokens === 0 ? [] : [gap]), free, ...categories.filter(row => row.kind === 'buffer')]
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
const paint = (color: number, text: string) => `\u001b[38;5;${color}m${text}\u001b[39m`
const colorOf = (category: Category) => COLORS[category.color ?? ''] ?? GRAY

// /context's grid: 10 rows of 20 squares over the whole window. Each used category fills its share in its color,
// a full square ⛁ or a partial one ⛀. Hidden squares ⛋ follow, showing where the hidden tokens would sit without context-lean.
const GRID_ROWS = 10
const GRID_COLUMNS = 20
const SYMBOL: Record<string, string> = { used: '⛁', partial: '⛀', hidden: '⛋', free: '⛶', buffer: '⛝' }
type Cell = { symbol: string; color: number }
const grid = (categories: Category[], saved: number, window: number) => {
  const squares = GRID_ROWS * GRID_COLUMNS
  const per = window / squares
  const buffer = categories.filter(row => row.kind === 'buffer').reduce((all, row) => all + row.tokens, 0)
  // An unknown window fills the grid instead of failing.
  const reserved = window > 0 ? Math.min(squares, Math.round(buffer / per)) : 0
  const used: Cell[] = categories
    .filter(row => row.kind === 'used' && row.tokens > 0)
    .flatMap(row => {
      const share = window > 0 ? row.tokens / per : squares
      return Array(Math.max(1, Math.round(share))).fill({ symbol: share >= 1 ? SYMBOL.used : SYMBOL.partial, color: colorOf(row) })
    })
    .slice(0, squares - reserved)
  const hidden = window > 0 ? Math.max(0, Math.min(squares - reserved - used.length, Math.round(saved / per))) : 0
  const cells: Cell[] = [
    ...used,
    ...Array(hidden).fill({ symbol: SYMBOL.hidden, color: HIDDEN }),
    ...Array(squares - reserved - used.length - hidden).fill({ symbol: SYMBOL.free, color: GRAY }),
    ...Array(reserved).fill({ symbol: SYMBOL.buffer, color: GRAY }),
  ]

  return Array.from({ length: GRID_ROWS }, (_, row) =>
    cells
      .slice(row * GRID_COLUMNS, (row + 1) * GRID_COLUMNS)
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

  return ['', `${title} · ${short(sum(rows))} tokens`, ...[...lines, ...more].map(line => paint(GRAY, line))]
}
const without = (suffix: string) => (label: string) => label.slice(0, label.length - suffix.length)

// One line for the model in place of the report, which only the person sees.
export const summary = ({ real, hidden, note }: Report) =>
  `${note === undefined ? '' : 'Last saved report. '}Context: ${short(real)} real tokens; context-lean hid ${short(sum(hidden))}.`

export const report = (measured: Report) => {
  const { real, window, estimate, model, hidden, kept, note } = measured
  const saved = sum(hidden)
  const total = real + saved
  const categories = categoriesOf(measured)
  const line = (symbol: string, color: number, name: string, value: string) => `${paint(color, symbol)} ${name}: ${paint(GRAY, value)}`
  const side = [
    model,
    paint(GRAY, `${short(real)}/${short(window)} tokens (${wholePercent(real, window)}), real`),
    paint(HIDDEN, `${short(saved)} saved by context-lean (${wholePercent(saved, total)})`),
    '',
    `\u001b[3m${paint(GRAY, 'Estimated usage by category')}\u001b[23m`,
    ...(measured.categories.length === 0
      ? [paint(GRAY, '(no breakdown available)')]
      : categories.flatMap(row => [
          ...(row.kind === 'free' ? [line(SYMBOL.hidden, HIDDEN, 'Hidden by context-lean', `${short(saved)} tokens (${percent(saved, window)})`)] : []),
          row.kind === 'buffer'
            ? paint(GRAY, `${SYMBOL.buffer} ${row.name}: ${short(row.tokens)} tokens (${percent(row.tokens, window)})`)
            : line(SYMBOL[row.kind] ?? SYMBOL.used, colorOf(row), row.name, `${short(row.tokens)}${row.kind === 'free' ? '' : ' tokens'} (${percent(row.tokens, window)})`),
        ])),
  ]
  const squares = grid(categories, saved, window)
  const indent = ' '.repeat(GRID_COLUMNS * 2 - 1)
  const top = Array.from({ length: Math.max(squares.length, side.length) }, (_, i) => `${squares[i] ?? indent}   ${side[i] ?? ''}`.trimEnd())
  const lines = [
    ...(note === undefined ? [] : [note, '']),
    'Context Usage (context-lean)',
    ...top,
    '',
    `${paint(HIDDEN, SYMBOL.hidden)} Saved by context-lean · ${short(saved)} tokens (${percent(saved, total)})`,
    paint(GRAY, `└ Without context-lean: ${short(total)} tokens`),
    ...(estimate === undefined ? [] : [paint(GRAY, `└ /context estimate: ${short(estimate)} tokens`)]),
    ...section('Hidden tool names', hidden.filter(row => row.label.endsWith(' tool names')), without(' tool names'), 'name'),
    ...section('Hidden tool descriptions', hidden.filter(row => isBuiltInDescription(row.label) || isConnectorDescriptions(row.label)), label => label.replace(/ tool descriptions$| description$/, ''), 'tool'),
    ...section('Hidden server notes', hidden.filter(row => isNotes(row.label)), without(NOTES), 'server'),
    ...section('Shortened agent descriptions', hidden.filter(row => row.label === AGENTS), () => 'Built-in agents', 'agent'),
    ...section('Trimmed attachments', hidden.filter(row => TRIMMED.has(row.label)), label => label, 'item'),
    ...section('Server notes sent on first use', kept.filter(row => isSentNotes(row.label)), without(`${NOTES}${SENT}`), 'server'),
    ...section('Server notes kept in the prompt', kept.filter(row => isNotes(row.label)), without(NOTES), 'server'),
    '',
    paint(GRAY, `Hidden items are counted with ${model}'s tokenizer; built-in tools count their descriptions, not their input schemas. Categories are /context's estimates. ${MCP_NOTES} counts only notes still sent in the prompt; the rest of /context's count moves to ${MESSAGES}.`),
  ]

  return lines.join('\n')
}
