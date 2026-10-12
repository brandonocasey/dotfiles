// Text that context-lean kept out of (or left in) the prompt, grouped into one report row.
export type Row = { label: string; texts: Map<string, string> }
export type Counted = { label: string; items: number; tokens: number | undefined }
export type Report = { real: number; window: number; estimate: number | undefined; model: string; hidden: Counted[]; kept: Counted[]; note?: string }

const number = (n: number) => n.toLocaleString('en-US')
const tokens = (n: number | undefined) => (n === undefined ? 'not counted' : number(n))
const sum = (rows: Counted[]) => rows.reduce((total, row) => total + (row.tokens ?? 0), 0)
const table = (rows: Counted[]) => [
  '| What | Items | Tokens |',
  '|---|--:|--:|',
  ...[...rows].sort((a, b) => (b.tokens ?? 0) - (a.tokens ?? 0)).map(row => `| ${row.label} | ${number(row.items)} | ${tokens(row.tokens)} |`),
]

export const report = ({ real, window, estimate, model, hidden, kept, note }: Report) => {
  const saved = sum(hidden)
  const without = real + saved
  const percent = (part: number, whole: number) => (whole === 0 ? '0%' : `${((part / whole) * 100).toFixed(1)}%`)
  const lines = [
    ...(note === undefined ? [] : [note, '']),
    `## Real context: ${number(real)} / ${number(window)} tokens (${percent(real, window)})`,
    '',
    '| | Tokens |',
    '|---|--:|',
    `| Real context, last request (from the API) | ${number(real)} |`,
    `| Hidden by context-lean | ${number(saved)} |`,
    `| Without context-lean (about) | ${number(without)} |`,
    `| Saved | ${percent(saved, without)} |`,
    ...(estimate === undefined ? [] : [`| /context estimate (ignores this mod) | ${number(estimate)} |`]),
  ]
  if (hidden.length > 0) lines.push('', '### Hidden now', '', ...table(hidden))
  if (kept.length > 0) lines.push('', '### Kept in the prompt', '', ...table(kept))
  lines.push('', `Token counts come from ${model}'s tokenizer. Hidden built-in tools count their descriptions only, not their input schemas.`)

  return lines.join('\n')
}
