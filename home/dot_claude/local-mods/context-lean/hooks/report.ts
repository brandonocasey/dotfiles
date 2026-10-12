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

// /context's number style: 10, 1.5k, 566.7k, 1m.
const short = (n: number) => {
  const sign = n < 0 ? '-' : ''
  const size = Math.abs(n)
  const scaled = (value: number, unit: string) => `${sign}${value.toFixed(1).replace(/\.0$/, '')}${unit}`
  if (size >= 1_000_000) return scaled(size / 1_000_000, 'm')
  if (size >= 1000) return scaled(size / 1000, 'k')

  return `${sign}${size}`
}
const percent = (part: number, whole: number) => (whole === 0 ? '0%' : `${((part / whole) * 100).toFixed(1).replace(/\.0$/, '')}%`)
const sum = (rows: Counted[]) => rows.reduce((total, row) => total + (row.tokens ?? 0), 0)
const sumWhere = (rows: Counted[], match: (label: string) => boolean) => sum(rows.filter(row => match(row.label)))

// Marks notes that were hidden from the prompt and later sent with a tool result.
export const SENT = ' (sent on first use)'
const isNotes = (label: string) => label.endsWith(' server notes')
const isSentNotes = (label: string) => label.endsWith(` server notes${SENT}`)
const isConnectorDescriptions = (label: string) => label.endsWith(' tool descriptions')
const isBuiltInDescription = (label: string) => label.endsWith(' description')

// /context's estimates count what this mod hides as loaded. Moves those counts out and lines the table up with the real total.
const corrected = ({ real, window, categories, hidden, kept }: Report) => {
  const rows = categories.map(category => {
    if (category.kind !== 'used') return category
    if (category.name === 'System tools') return { ...category, tokens: Math.max(0, category.tokens - sumWhere(hidden, isBuiltInDescription)) }
    if (category.name === 'MCP tools') return { ...category, tokens: Math.max(0, category.tokens - sumWhere(hidden, isConnectorDescriptions)) }
    // Sent notes now sit in Messages, so they leave this category as well.
    if (category.name === 'MCP server instructions') return { ...category, tokens: Math.max(0, category.tokens - sumWhere(hidden, isNotes) - sumWhere(kept, isSentNotes)) }

    return category
  })
  const total = (kind: string) => rows.filter(row => row.kind === kind).reduce((all, row) => all + row.tokens, 0)
  const gap: Category = { name: 'Unattributed (real minus estimates)', tokens: real - total('used'), kind: 'used' }
  const free: Category = { name: 'Free space', tokens: Math.max(0, window - real - total('buffer')), kind: 'free' }
  const placed = rows.flatMap(row => (row.kind === 'free' ? [gap, free] : [row]))

  return placed.includes(gap) ? placed : [...placed, gap, free]
}

export const report = (measured: Report) => {
  const { real, window, estimate, model, categories, hidden, kept, note } = measured
  const saved = sum(hidden)
  const without = real + saved
  const items = (rows: Counted[]) => [
    '| Item | Count | Tokens |',
    '|------|-------|--------|',
    ...[...rows]
      .sort((a, b) => (b.tokens ?? 0) - (a.tokens ?? 0))
      .map(row => `| ${row.label} | ${row.items} | ${row.tokens === undefined ? 'not counted' : short(row.tokens)} |`),
  ]
  const lines = [
    ...(note === undefined ? [] : [note, '']),
    '## Context Usage (context-lean)',
    `**Model:** ${model}  `,
    `**Tokens:** ${short(real)} / ${short(window)} (${percent(real, window)}), real, from the API  `,
    `**Without context-lean:** ${short(without)} (${short(saved)} saved, ${percent(saved, without)})  `,
    ...(estimate === undefined ? [] : [`**/context estimate:** ${short(estimate)}, which ignores this mod`]),
  ]
  if (categories.length > 0) {
    lines.push('', '### Usage by category, corrected for context-lean', '', '| Category | Tokens | Percentage |', '|----------|--------|------------|')
    lines.push(...corrected(measured).map(row => `| ${row.name} | ${short(row.tokens)} | ${percent(row.tokens, window)} |`))
  }
  if (hidden.length > 0) lines.push('', '### Hidden by context-lean', '', ...items(hidden))
  if (kept.length > 0) lines.push('', '### Kept in the prompt', '', ...items(kept))
  lines.push(
    '',
    `Hidden and kept counts come from ${model}'s tokenizer. Hidden built-in tools count their descriptions only, not their input schemas. Other categories are /context's estimates.`,
  )

  return lines.join('\n')
}
