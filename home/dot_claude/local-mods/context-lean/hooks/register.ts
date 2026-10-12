import type { Register } from 'claude-code'
import { type Category, type Counted, type Report, type Row, report, SENT } from './report'

// Built-in tools kept out of the prompt until ToolSearch loads them by name.
const ARTIFACT_TOOLS = new Set(['Artifact', 'ArtifactComments', 'ArtifactData', 'DesignSync'])
const RARE_TOOLS = new Set(['ScheduleWakeup', 'SendFeedback', 'ReportFindings', 'ListAgents', 'AskUserQuestion', 'Workflow', 'ShareOnboardingGuide', 'Agent'])
// claude.ai connectors whose server notes stay in the prompt. Every other connector's notes are sent with the
// first ToolSearch or tool call that uses it. Every connector's tool names are hidden but findable through ToolSearch.
const NOTES = new Set<string>()
const RULE = 'Use only when the user explicitly asks for an artifact.'
const NOTE = `${RULE}\n\n`
const ARTIFACT_ENTRY = /^Artifact: .*$/m
const HINT = `\n\nNot in the deferred tools list but loadable with select:<name>: ${[...RARE_TOOLS].join(', ')}. Load one before calling it.`
const CONNECTOR = /^mcp__claude_ai_(.+?)__/
const CONNECTOR_ANYWHERE = /mcp__claude_ai_([A-Za-z0-9_-]+?)__/g
const LISTED_NAME = /^([\w-]+)(?::|$)/
const HEADING = /^## claude\.ai (.+)$/
const REMOVED = /no longer available/
const DISCONNECTED = 'The following MCP servers have disconnected.'
const DESCRIPTION = ' description'
const NAMES = ' names'
const COUNT_SYSTEM = 'Reply with only: ok'
const BASE = '(base)'
const COUNTS = 'counts'
const LAST_REPORT = 'last-report'

const connectorOf = (tool: string) => CONNECTOR.exec(tool)?.[1]
// A tool result as text, to find the connectors it names. Results with no JSON form name none.
const mentions = (result: unknown) => {
  try {
    return JSON.stringify(result) ?? ''
  } catch {
    return ''
  }
}

// A short, stable hash (cyrb53) to tell whether a row's text changed since it was counted.
const hashOf = (text: string) => {
  let a = 0xdeadbeef ^ text.length
  let b = 0x41c6ce57 ^ text.length
  for (let i = 0; i < text.length; i++) {
    const code = text.charCodeAt(i)
    a = Math.imul(a ^ code, 2654435761)
    b = Math.imul(b ^ code, 1597334677)
  }
  a = Math.imul(a ^ (a >>> 16), 2246822507) ^ Math.imul(b ^ (b >>> 13), 3266489909)
  b = Math.imul(b ^ (b >>> 16), 2246822507) ^ Math.imul(a ^ (a >>> 13), 3266489909)

  return (4294967296 * (2097151 & b) + (a >>> 0)).toString(36)
}
const shown = (server: string) => server.replace(/_/g, ' ')

// The parts of the mod API these helpers use.
type Host = {
  session: { id(): Promise<string> }
  store: { get(key: string): Promise<unknown>; set(key: string, value: unknown): Promise<void>; delete(key: string): Promise<void>; keys(): Promise<string[]> }
}
type Saved = { at: number; hidden: Record<string, Record<string, string>>; kept: Record<string, Record<string, string>>; sent?: string[] }
// Token counts by row, reused across sessions while the row's text and the model stay the same.
type Counts = { model: string; rows: Record<string, { hash: string; tokens: number }> }
type LastReport = Report & { at: number }

// What the current session hid or kept, for /context-lean. Saved per session so a resumed session still reports it.
const SESSIONS_KEPT = 10
const hidden = new Map<string, Row>()
const kept = new Map<string, Row>()
let session: { key: string; ready: Promise<void> } | undefined
// Connectors whose notes were already sent, by agent ("main" for the main session).
const sent = new Set<string>()

const record = (rows: Map<string, Row>, label: string, key: string, text: string) => {
  const row = rows.get(label) ?? { label, texts: new Map<string, string>() }
  row.texts.set(key, text)
  rows.set(label, row)
}

const toObject = (rows: Map<string, Row>) => Object.fromEntries([...rows].map(([label, row]) => [label, Object.fromEntries(row.texts)]))
const fromObject = (rows: Map<string, Row>, saved: Record<string, Record<string, string>> = {}) => {
  for (const [label, texts] of Object.entries(saved)) for (const [key, text] of Object.entries(texts)) record(rows, label, key, text)
}

const restore = async ($: Host, key: string) => {
  const saved = (await $.store.get(key)) as Saved | undefined
  fromObject(hidden, saved?.hidden)
  fromObject(kept, saved?.kept)
  for (const entry of saved?.sent ?? []) sent.add(entry)
  const others = (await $.store.keys()).filter(other => other.startsWith('session:') && other !== key)
  if (others.length < SESSIONS_KEPT) return
  const dated = await Promise.all(others.map(async other => ({ other, at: ((await $.store.get(other)) as Saved | undefined)?.at ?? 0 })))
  await Promise.all(dated.sort((a, b) => a.at - b.at).slice(0, others.length - SESSIONS_KEPT + 1).map(({ other }) => $.store.delete(other)))
}

// Loads the current session's saved rows once per session and drops the oldest saved sessions.
// A new session in the same process, such as after /clear, starts from its own rows.
// Bookkeeping never blocks hiding: when the store fails, the report only covers this process.
const load = async ($: Host) => {
  try {
    const key = `session:${await $.session.id()}`
    if (session?.key !== key) {
      hidden.clear()
      kept.clear()
      sent.clear()
      session = { key, ready: restore($, key).catch(() => undefined) }
    }
    await session.ready

    return key
  } catch {
    return undefined
  }
}

const save = async ($: Host) => {
  const key = await load($)
  if (key === undefined) return
  const saved: Saved = { at: Date.now(), hidden: toObject(hidden), kept: toObject(kept), sent: [...sent] }
  await $.store.set(key, saved).catch(() => undefined)
}

const hideNames = (text: string) => {
  const servers = new Set<string>()
  const paragraphs = text.split('\n\n').flatMap(paragraph => {
    const lines = paragraph.split('\n')
    // Removal notices stay whole, so Claude still learns which tools went away.
    if (REMOVED.test(lines[0])) return [paragraph]
    const left = lines.filter(line => {
      const name = LISTED_NAME.exec(line.trim())?.[1]
      const server = name === undefined ? undefined : connectorOf(name)
      if (name !== undefined && server !== undefined) {
        servers.add(server)
        record(hidden, `${shown(server)} tool${NAMES}`, name, line)
      } else if (name !== undefined && RARE_TOOLS.has(name)) record(hidden, `Built-in tool${NAMES}`, name, line)
      else return true
      return false
    })

    return left.length === lines.length || left.length > 1 ? [left.join('\n')] : []
  })
  if (servers.size === 0) return paragraphs.join('\n\n')
  const note = `Not listed but findable with ToolSearch keywords (e.g. "datadog logs"): tools from ${[...servers].sort().join(', ')}.`

  return [...paragraphs, note].join('\n\n')
}

// The engine appends its disconnect notice right after the last server's notes, so it is split off and always kept.
const hideInstructions = (text: string) => {
  const cut = text.indexOf(DISCONNECTED)
  const notes = cut === -1 ? text : text.slice(0, cut).trimEnd()
  const notice = cut === -1 ? '' : text.slice(cut)
  const sections = notes.split(/\n+(?=## )/).filter(section => {
    const server = HEADING.exec(section.split('\n', 1)[0])?.[1].replace(/[^A-Za-z0-9_-]/g, '_')
    if (server === undefined) return true
    record(NOTES.has(server) ? kept : hidden, `${shown(server)} server notes`, server, section)

    return NOTES.has(server)
  })
  const parts = [sections.some(section => section.startsWith('## ')) ? sections.join('\n\n') : '', notice].filter(part => part !== '')

  return parts.length === 0 ? null : parts.join('\n')
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'context-lean', description: 'Show the real context size and what context-lean hides' })

    return next(e)
  })

  on('command.run', { command: 'context-lean' }, async $ => {
    try {
      await load($)
      const usage = await $.session.usage({ breakdown: 'full' })
      if (!usage.context.tokens) {
        // Nothing was sent yet, so there is no real size. Show the last report instead.
        const last = (await $.store.get(LAST_REPORT).catch(() => undefined)) as LastReport | undefined
        if (typeof last?.real !== 'number') return { text: 'Nothing measured yet. Send a message, then run /context-lean again.' }
        const when = new Date(last.at).toLocaleString()

        return { text: report({ ...last, categories: last.categories ?? [], note: `No request sent in this session yet, so these numbers are from your last report (${when}). Send a message for this session's numbers.` }) }
      }
      const model = await $.session.model()
      const stored = (await $.store.get(COUNTS).catch(() => undefined)) as Counts | undefined
      const known = stored?.model === model ? stored.rows : {}
      const fresh: Counts['rows'] = {}
      // Failed counts are not saved, so the next run tries again.
      const count = async (label: string, text: string) => {
        const hash = hashOf(text)
        const cached = known[label]
        if (cached?.hash === hash) return (fresh[label] = cached).tokens
        const answer = await $.model.complete({ model, system: COUNT_SYSTEM, prompt: `.\n${text}`, maxTokens: 1, effort: 'low' }).catch(() => undefined)
        // An empty reply still reports the input tokens it was billed for.
        const tokens = answer?.usage.input_tokens ?? 0
        if (tokens === 0) return undefined
        fresh[label] = { hash, tokens }

        return tokens
      }
      const base = await count(BASE, '')
      // A tool whose whole description is counted is not counted again for its listed name.
      const described = new Set([...hidden.values()].filter(row => row.label.includes(DESCRIPTION)).flatMap(row => [...row.texts.keys()]))
      const rows = (from: Map<string, Row>) =>
        Promise.all(
          [...from.values()].flatMap(row => {
            const texts = [...row.texts].filter(([key]) => !row.label.endsWith(NAMES) || !described.has(key))
            if (texts.length === 0) return []
            const counting = count(row.label, texts.map(([, text]) => text).join('\n'))

            return [counting.then((total): Counted => ({ label: row.label, items: texts.length, tokens: total === undefined || base === undefined ? undefined : total - base }))]
          }),
        )
      // Notes already sent on first use are back in the context, so they count as kept, not saved.
      const isSent = (row: Row) => row.label.endsWith(' server notes') && [...row.texts.keys()].every(server => sent.has(`main:${server}`))
      const sentRows = new Map([...hidden].filter(([, row]) => isSent(row)).map(([label, row]) => [label, { ...row, label: `${row.label}${SENT}` }]))
      const stillHidden = new Map([...hidden].filter(([label]) => !sentRows.has(label)))
      const [hiddenRows, keptRows] = await Promise.all([rows(stillHidden), rows(new Map([...kept, ...sentRows]))])
      const categories: Category[] = (usage.context.breakdown?.categories ?? []).map(({ name, tokens, kind, color }: Category) => ({ name, tokens, kind, color }))
      const measured: Report = { real: usage.context.tokens, window: usage.context.window, estimate: usage.context.breakdown?.totalTokens, model, categories, hidden: hiddenRows, kept: keptRows }
      const last: LastReport = { ...measured, at: Date.now() }
      await Promise.all([$.store.set(COUNTS, { model, rows: { ...known, ...fresh } }), $.store.set(LAST_REPORT, last)]).catch(() => undefined)

      return { text: report(measured) }
    } catch (error) {
      return { text: `context-lean could not build the report: ${String(error)}` }
    }
  })

  // Sends a hidden connector's server notes with the first ToolSearch result or tool call that uses it.
  on('tool.call', async ($, e, next) => {
    if (e.tool !== 'ToolSearch' && connectorOf(e.tool) === undefined) return next(e)
    const ran = await next(e)
    if (!('result' in ran)) return ran
    await load($)
    const agent = e.agentId ?? 'main'
    const servers = new Set([...mentions(ran.result).matchAll(CONNECTOR_ANYWHERE)].map(match => match[1]))
    if (e.tool !== 'ToolSearch') servers.add(connectorOf(e.tool)!)
    const notes = [...servers].flatMap(server => {
      const text = hidden.get(`${shown(server)} server notes`)?.texts.get(server)
      if (text === undefined || sent.has(`${agent}:${server}`)) return []
      sent.add(`${agent}:${server}`)

      return [`Server notes for this connector, sent now that its tools are in use:\n${text}`]
    })
    if (notes.length === 0) return ran
    await save($)

    return { ...ran, context: [...(ran.context ?? []), ...notes] }
  })

  on('tool.describe', { tool: 'ToolSearch' }, async ($, e, next) => {
    const described = await next(e)

    return { ...described, description: described.description + HINT }
  })

  on('tool.describe', async ($, e, next) => {
    const server = connectorOf(e.tool)
    if (!ARTIFACT_TOOLS.has(e.tool) && !RARE_TOOLS.has(e.tool) && server === undefined) return next(e)
    const described = await next(e)
    if (e.isDeferred !== true) {
      await load($)
      record(hidden, server === undefined ? `${e.tool}${DESCRIPTION}` : `${shown(server)} tool${DESCRIPTION}s`, e.tool, described.description)
      await save($)
    }
    const description = ARTIFACT_TOOLS.has(e.tool) ? NOTE + described.description : described.description

    return { description, isDeferred: true }
  })

  on('prompt.attachment', { type: 'deferred_tools_delta' }, async ($, e, next) => {
    const { text } = await next(e)
    if (text === null) return { text }
    await load($)
    const left = hideNames(text.replace(ARTIFACT_ENTRY, `Artifact: reads claude.ai artifact links; publishes pages on claude.ai. ${RULE}`))
    await save($)

    return { text: left }
  })

  on('prompt.attachment', { type: 'mcp_instructions_delta' }, async ($, e, next) => {
    const { text } = await next(e)
    if (text === null) return { text }
    await load($)
    const left = hideInstructions(text)
    await save($)

    return { text: left }
  })
}
