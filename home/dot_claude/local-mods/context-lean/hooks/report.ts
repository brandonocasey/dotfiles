// Text that context-lean kept out of (or left in) the prompt, grouped into one report row.
export type Row = { label: string; texts: Map<string, string> }
export type Counted = { label: string; items: number; tokens: number | undefined }
// One /context category, as the engine's usage breakdown reports it.
export type Category = { name: string; tokens: number; kind: string }
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

// Marks notes that were hidden from the prompt and later sent with a tool result.
export const SENT = ' (sent on first use)'

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
// deferred tools differently, so individual categories are left as /context reports them.
const categoriesOf = ({ real, window, categories }: Report) => {
  const total = (kind: string) => categories.filter(row => row.kind === kind).reduce((all, row) => all + row.tokens, 0)
  const gap: Category = { name: 'Difference from the real total', tokens: real - total('used'), kind: 'used' }
  const free: Category = { name: 'Free space', tokens: Math.max(0, window - real - total('buffer')), kind: 'free' }

  // In /context's order: what is used, then free space, then the autocompact buffer.
  return [...categories.filter(row => row.kind === 'used'), gap, free, ...categories.filter(row => row.kind === 'buffer')]
}

// /context's grid: 10 rows of 20 squares over the whole window. Used squares come from the real total.
const GRID_ROWS = 10
const GRID_COLUMNS = 20
const SYMBOL: Record<string, string> = { used: '⛁', free: '⛶', buffer: '⛝' }
const grid = (real: number, window: number, buffer: number) => {
  const squares = GRID_ROWS * GRID_COLUMNS
  const per = window / squares
  // A real total over the window, or an unknown window, fills the grid instead of failing.
  const used = real <= 0 ? 0 : window > 0 ? Math.min(squares, Math.max(1, Math.round(real / per))) : squares
  const reserved = window > 0 ? Math.max(0, Math.min(squares - used, Math.round(buffer / per))) : 0
  const cells = [...Array(used).fill(SYMBOL.used), ...Array(squares - used - reserved).fill(SYMBOL.free), ...Array(reserved).fill(SYMBOL.buffer)]

  return Array.from({ length: GRID_ROWS }, (_, row) => cells.slice(row * GRID_COLUMNS, (row + 1) * GRID_COLUMNS).join(' '))
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

  return ['', `${title} · ${short(sum(rows))} tokens`, ...lines, ...more]
}
const without = (suffix: string) => (label: string) => label.slice(0, label.length - suffix.length)

export const report = (measured: Report) => {
  const { real, window, estimate, model, hidden, kept, note } = measured
  const saved = sum(hidden)
  const total = real + saved
  const categories = categoriesOf(measured)
  const buffer = categories.filter(row => row.kind === 'buffer').reduce((all, row) => all + row.tokens, 0)
  const side = [
    model,
    `${short(real)}/${short(window)} tokens (${wholePercent(real, window)}), real`,
    `${short(saved)} saved by context-lean (${wholePercent(saved, total)})`,
    '',
    'Estimated usage by category',
    ...(measured.categories.length === 0
      ? ['(no breakdown available)']
      : categories.map(row => `${SYMBOL[row.kind] ?? SYMBOL.used} ${row.name}: ${short(row.tokens)}${row.kind === 'free' ? '' : ' tokens'} (${percent(row.tokens, window)})`)),
  ]
  const squares = grid(real, window, buffer)
  const indent = ' '.repeat(squares[0].length)
  const top = Array.from({ length: Math.max(squares.length, side.length) }, (_, i) => `${squares[i] ?? indent}   ${side[i] ?? ''}`.trimEnd())
  const lines = [
    ...(note === undefined ? [] : [note, '']),
    'Context Usage (context-lean)',
    ...top,
    '',
    `Saved by context-lean · ${short(saved)} tokens (${percent(saved, total)})`,
    `└ Without context-lean: ${short(total)} tokens`,
    ...(estimate === undefined ? [] : [`└ /context estimate: ${short(estimate)} tokens`]),
    ...section('Hidden tool names', hidden.filter(row => row.label.endsWith(' tool names')), without(' tool names'), 'name'),
    ...section('Hidden tool descriptions', hidden.filter(row => isBuiltInDescription(row.label) || isConnectorDescriptions(row.label)), label => label.replace(/ tool descriptions$| description$/, ''), 'tool'),
    ...section('Hidden server notes', hidden.filter(row => isNotes(row.label)), without(NOTES), 'server'),
    ...section('Server notes sent on first use', kept.filter(row => isSentNotes(row.label)), without(`${NOTES}${SENT}`), 'server'),
    ...section('Server notes kept in the prompt', kept.filter(row => isNotes(row.label)), without(NOTES), 'server'),
    '',
    `Hidden items are counted with ${model}'s tokenizer; built-in tools count their descriptions, not their input schemas. Categories are /context's estimates.`,
  ]

  return lines.join('\n')
}
