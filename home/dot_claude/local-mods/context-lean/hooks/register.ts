import type { Register } from 'claude-code'
import { type Counted, type Row, report } from './report'

// Built-in tools kept out of the prompt until ToolSearch loads them by name.
const ARTIFACT_TOOLS = new Set(['Artifact', 'ArtifactComments', 'ArtifactData', 'DesignSync'])
const RARE_TOOLS = new Set(['ScheduleWakeup', 'SendFeedback', 'ReportFindings', 'ListAgents', 'AskUserQuestion', 'Workflow', 'ShareOnboardingGuide', 'Agent'])
// claude.ai connectors whose server notes stay in the prompt. Every connector's tool names are hidden but findable through ToolSearch.
const NOTES = new Set(['Atlassian', 'Atlassian_MCP'])
const RULE = 'Use only when the user explicitly asks for an artifact.'
const NOTE = `${RULE}\n\n`
const ARTIFACT_ENTRY = /^Artifact: .*$/m
const HINT = `\n\nNot in the deferred tools list but loadable with select:<name>: ${[...RARE_TOOLS].join(', ')}. Load one before calling it.`
const CONNECTOR = /^mcp__claude_ai_(.+?)__/
const LISTED_NAME = /^([\w-]+)(?::|$)/
const HEADING = /^## claude\.ai (.+)$/
const COUNT_SYSTEM = 'Reply with only: ok'

const connectorOf = (tool: string) => CONNECTOR.exec(tool)?.[1]
const shown = (server: string) => server.replace(/_/g, ' ')

// The parts of the mod API these helpers use.
type Host = {
  session: { id(): Promise<string> }
  store: { get(key: string): Promise<unknown>; set(key: string, value: unknown): Promise<void>; delete(key: string): Promise<void>; keys(): Promise<string[]> }
}
type Saved = { at: number; hidden: Record<string, Record<string, string>>; kept: Record<string, Record<string, string>> }

// What this session hid or kept, for /context-lean. Saved per session so a resumed session still reports it.
const SESSIONS_KEPT = 30
const hidden = new Map<string, Row>()
const kept = new Map<string, Row>()
const counts = new Map<string, Promise<number | undefined>>()
// Tools only this mod defers. Their whole description is counted, so their listed names are not counted again.
const deferredHere = new Set<string>()
let loaded: Promise<string | undefined> | undefined

const toObject = (rows: Map<string, Row>) => Object.fromEntries([...rows].map(([label, row]) => [label, Object.fromEntries(row.texts)]))
const fromObject = (rows: Map<string, Row>, saved: Record<string, Record<string, string>> = {}) => {
  for (const [label, texts] of Object.entries(saved)) for (const [key, text] of Object.entries(texts)) record(rows, label, key, text)
}

// Loads this session's saved rows once per process and drops the oldest saved sessions.
// Bookkeeping never blocks hiding: when the store fails, the report only covers this process.
const load = ($: Host) =>
  (loaded ??= (async (): Promise<string | undefined> => {
    const key = `session:${await $.session.id()}`
    const saved = (await $.store.get(key)) as Saved | undefined
    fromObject(hidden, saved?.hidden)
    fromObject(kept, saved?.kept)
    const others = (await $.store.keys()).filter(other => other.startsWith('session:') && other !== key)
    if (others.length >= SESSIONS_KEPT) {
      const dated = await Promise.all(others.map(async other => ({ other, at: ((await $.store.get(other)) as Saved | undefined)?.at ?? 0 })))
      await Promise.all(dated.sort((a, b) => a.at - b.at).slice(0, others.length - SESSIONS_KEPT + 1).map(({ other }) => $.store.delete(other)))
    }

    return key
  })().catch(() => undefined))

const save = async ($: Host) => {
  const key = await load($)
  if (key === undefined) return
  const saved: Saved = { at: Date.now(), hidden: toObject(hidden), kept: toObject(kept) }
  await $.store.set(key, saved).catch(() => undefined)
}

const record = (rows: Map<string, Row>, label: string, key: string, text: string) => {
  const row = rows.get(label) ?? { label, texts: new Map<string, string>() }
  row.texts.set(key, text)
  rows.set(label, row)
}

const hideNames = (text: string) => {
  const servers = new Set<string>()
  const paragraphs = text.split('\n\n').flatMap(paragraph => {
    const lines = paragraph.split('\n')
    const left = lines.filter(line => {
      const name = LISTED_NAME.exec(line.trim())?.[1]
      const server = name === undefined ? undefined : connectorOf(name)
      const isCounted = name !== undefined && deferredHere.has(name)
      if (server !== undefined) {
        servers.add(server)
        if (!isCounted) record(hidden, `${shown(server)} tool names`, line, line)
      } else if (name !== undefined && RARE_TOOLS.has(name)) {
        if (!isCounted) record(hidden, 'Built-in tool names', name, line)
      } else return true
      return false
    })

    return left.length === lines.length || left.length > 1 ? [left.join('\n')] : []
  })
  if (servers.size === 0) return paragraphs.join('\n\n')
  const note = `Not listed but findable with ToolSearch keywords (e.g. "datadog logs"): tools from ${[...servers].sort().join(', ')}.`

  return [...paragraphs, note].join('\n\n')
}

const hideInstructions = (text: string) => {
  const sections = text.split(/\n\n(?=## )/).filter(section => {
    const server = HEADING.exec(section.split('\n', 1)[0])?.[1].replace(/[^A-Za-z0-9_-]/g, '_')
    if (server === undefined) return true
    record(NOTES.has(server) ? kept : hidden, `${shown(server)} server notes`, server, section)

    return NOTES.has(server)
  })

  return sections.some(section => section.startsWith('## ')) ? sections.join('\n\n') : null
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'context-lean', description: 'Show the real context size and what context-lean hides' })

    return next(e)
  })

  on('command.run', { command: 'context-lean' }, async $ => {
    await load($)
    const usage = await $.session.usage({ breakdown: 'summary' })
    if (usage.context.tokens === 0) return { text: 'Send a message first. The real size comes from the last API request.' }
    const model = await $.session.model()
    const count = (text: string) => {
      const cached = counts.get(text)
      if (cached !== undefined) return cached
      const counting = $.model
        .complete({ model, system: COUNT_SYSTEM, prompt: `.\n${text}`, maxTokens: 1, effort: 'low' })
        .then(answer => (answer.isAnswered ? answer.usage.input_tokens : undefined))
        .catch(() => undefined)
      counts.set(text, counting)
      return counting
    }
    const base = await count('')
    const rows = (from: Map<string, Row>) =>
      Promise.all(
        [...from.values()].map(async (row): Promise<Counted> => {
          const total = await count([...row.texts.values()].join('\n'))
          return { label: row.label, items: row.texts.size, tokens: total === undefined || base === undefined ? undefined : total - base }
        }),
      )
    const [hiddenRows, keptRows] = await Promise.all([rows(hidden), rows(kept)])

    return {
      text: report({
        real: usage.context.tokens,
        window: usage.context.window,
        estimate: usage.context.breakdown?.totalTokens,
        model,
        hidden: hiddenRows,
        kept: keptRows,
      }),
    }
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
      deferredHere.add(e.tool)
      await load($)
      record(hidden, server === undefined ? `${e.tool} description` : `${shown(server)} tool descriptions`, e.tool, described.description)
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
