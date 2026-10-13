import type { EngineInterface, Register, RenderElement } from 'claude-code'
import { AGENTS, type Category, type Counted, type Report, type Row, report, SENT, summary } from './report'

// Built-in tools kept out of the prompt until ToolSearch loads them by name.
const ARTIFACT_TOOLS = new Set(['Artifact', 'ArtifactComments', 'ArtifactData', 'DesignSync'])
const RARE_TOOLS = new Set(['ScheduleWakeup', 'SendFeedback', 'ReportFindings', 'ListAgents', 'AskUserQuestion', 'Workflow', 'ShareOnboardingGuide', 'Agent', 'Skill'])
// The skill listing still names every skill, so it says how to load the deferred Skill tool.
const SKILL_NOTE = 'The Skill tool is deferred: load it with ToolSearch select:Skill before invoking a skill.\n\n'
// Built-in agents whose long descriptions are replaced with one line in the agent listing. Matched by name, so a
// custom agent that reuses one of these names gets the built-in summary too.
const AGENT_SUMMARIES: Record<string, string> = {
  'claude-code-guide': 'Questions about Claude Code, the Agent SDK, the Claude API, or Claude in Slack. Continue a running one with SendMessage.',
  'general-purpose': 'Generic research and multi-step tasks. Use only when no named role fits.',
  claude: 'Generic catch-all. Use only when no named role fits.',
  Explore: 'Read-only broad search that returns conclusions, not file dumps.',
  Plan: 'Read-only implementation planning.',
  'statusline-setup': 'Configures the status line.',
}
const AGENT_LINE = /^- ([\w-]+): (.*?)( \(Tools: [^)]*\))?$/
// claude.ai connectors whose server notes stay in the prompt. Every other connector's notes are sent with the
// first ToolSearch or tool call that uses it. Every MCP tool name, local or connector, is hidden but findable through ToolSearch.
const NOTES = new Set<string>()
const RULE = 'Use only when the user explicitly asks for an artifact.'
const NOTE = `${RULE}\n\n`
const ARTIFACT_ENTRY = /^Artifact: .*$/m
const HINT = `\n\nNot in the deferred tools list but loadable with select:<name>: ${[...RARE_TOOLS].join(', ')}. Load one before calling it.`
const CONNECTOR = /^mcp__claude_ai_(.+?)__/
const CONNECTOR_ANYWHERE = /mcp__claude_ai_([A-Za-z0-9_-]+?)__/g
// Any MCP server's tool, local or connector, for hiding names in the deferred-tools list.
const MCP_SERVER = /^mcp__(?:claude_ai_)?(.+?)__/
const LOCAL_SERVER = /^mcp__(.+?)__/
const LISTED_NAME = /^([\w-]+)(?::|$)/
const HEADING = /^## claude\.ai (.+)$/
const SUBHEADING = /^## (.+)$/
const CLAUDE_AI = 'claude.ai '
const DISCONNECTED_CONNECTOR = /^claude\.ai (.+)$/
const NOTICE = /no longer available|available again/
const DISCONNECTED = 'The following MCP servers have disconnected.'
const DESCRIPTION = ' description'
const SERVER_NOTES = ' server notes'
const NAMES = ' names'
const COUNT_SYSTEM = 'Reply with only: ok'
const BASE = '(base)'
const COUNTS = 'counts'
const LAST_REPORT = 'last-report'
const LOCAL_SERVERS = 'local-servers'
// MCP config keys are usually one lowercase word, unlike the subheadings inside a connector's notes.
const SERVER_NAME = /^[a-z0-9][a-z0-9_.-]*$/

const connectorOf = (tool: string) => CONNECTOR.exec(tool)?.[1]
// The engine's sort puts names of only ASCII characters before all others.
const isAscii = (name: string) => [...name].every(char => char.charCodeAt(0) < 128)
// Matches how Claude Code turns a server name into the server part of its tool names.
const serverKey = (name: string) => name.replace(/[^A-Za-z0-9_-]/g, '_')
const connectorKey = (name: string) =>
  serverKey(`${CLAUDE_AI}${name}`)
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
    .slice(serverKey(CLAUDE_AI).length)
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
type Saved = { at: number; hidden: Record<string, Record<string, string>>; kept: Record<string, Record<string, string>>; sent?: string[]; used?: string[]; seen?: string[] }
// Token counts by row, reused across sessions while the row's text and the model stay the same.
type Counts = { model: string; rows: Record<string, { hash: string; tokens: number }> }

// What the current session hid or kept, for the /context report. Saved per session so a resumed session still reports it.
const SESSIONS_KEPT = 10
const hidden = new Map<string, Row>()
const kept = new Map<string, Row>()
let session: { key: string; ready: Promise<void>; loaded: boolean } | undefined
// Connectors whose notes were already sent, by agent ("main" for the main session).
const sent = new Set<string>()
// Connectors whose tools an agent already loaded or called. Notes that arrive after that stay in the prompt.
const used = new Set<string>()
// Notes texts hidden this session, by agent. The engine can ask again about an old attachment, and the answer must not
// change.
const seen = new Set<string>()
// Local MCP servers seen in tool names, to group a local server's "## " sub-headings with it in the report.
// Kept across sessions, since notes can arrive before this process has seen the server's tools.
const localServers = new Set<string>()
let saving: Promise<void> | undefined
let dirty = false

const record = (rows: Map<string, Row>, label: string, key: string, text: string) => {
  const row = rows.get(label) ?? { label, texts: new Map<string, string>() }
  const changed = row.texts.get(key) !== text
  row.texts.set(key, text)
  rows.set(label, row)

  return changed
}

const noteLocalServer = (tool: string) => {
  const server = LOCAL_SERVER.exec(tool)?.[1]
  if (server !== undefined && connectorOf(tool) === undefined) localServers.add(server)
}

// Drops the record that a connector's notes were sent, for every agent, so its next use sends them again.
const forget = (server: string) => {
  for (const set of [sent, used]) for (const entry of set) if (entry.endsWith(`:${server}`)) set.delete(entry)
}

const toObject = (rows: Map<string, Row>) => Object.fromEntries([...rows].map(([label, row]) => [label, Object.fromEntries(row.texts)]))
const fromObject = (rows: Map<string, Row>, saved: Record<string, Record<string, string>> = {}) => {
  for (const [label, texts] of Object.entries(saved)) for (const [key, text] of Object.entries(texts)) record(rows, label, key, text)
}

const restore = async ($: Host, key: string) => {
  const servers = (await $.store.get(LOCAL_SERVERS)) as string[] | undefined
  for (const server of servers ?? []) localServers.add(server)
  const saved = (await $.store.get(key)) as Saved | undefined
  // Another session loaded while this one was reading, so its rows must not mix into that session's.
  if (session?.key !== key) return
  fromObject(hidden, saved?.hidden)
  fromObject(kept, saved?.kept)
  for (const entry of saved?.sent ?? []) sent.add(entry)
  for (const entry of saved?.used ?? []) used.add(entry)
  for (const entry of saved?.seen ?? []) seen.add(entry)
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
      // A queued or running save can skip the old session, so its latest rows are written after that save, which also
      // keeps the two writes in order. Rows still loading are not written.
      if (session?.loaded === true && saving !== undefined) {
        const old = { key: session.key, rows: snapshot() }
        saving.then(() => $.store.set(old.key, old.rows)).catch(() => undefined)
      }
      hidden.clear()
      kept.clear()
      sent.clear()
      used.clear()
      seen.clear()
      const next = { key, ready: Promise.resolve(), loaded: false }
      next.ready = restore($, key)
        .catch(() => undefined)
        .finally(() => {
          next.loaded = true
        })
      session = next
    }
    await session.ready

    return key
  } catch {
    return undefined
  }
}

const snapshot = (): Saved => ({ at: Date.now(), hidden: toObject(hidden), kept: toObject(kept), sent: [...sent], used: [...used], seen: [...seen] })

const write = async ($: Host) => {
  const key = await load($)
  // Another session loaded meanwhile and cleared the rows; the switch already wrote the old session's rows.
  if (key === undefined || session?.key !== key) return
  await Promise.all([$.store.set(key, snapshot()), $.store.set(LOCAL_SERVERS, [...localServers])]).catch(() => undefined)
}

// One write at a time, without blocking the caller. A save asked for during a write runs once after it, so the
// last write always holds the latest rows.
const save = ($: Host) => {
  dirty = true
  saving ??= (async () => {
    while (dirty) {
      dirty = false
      await write($)
    }
    saving = undefined
  })()
}

const shortenAgents = (text: string) =>
  text
    .split('\n')
    .map(line => {
      const [, name, description, tools = ''] = AGENT_LINE.exec(line) ?? []
      const summary = name === undefined ? undefined : AGENT_SUMMARIES[name]
      if (name === undefined || summary === undefined || description === undefined || description === summary) return line
      record(hidden, AGENTS, name, description)

      return `- ${name}: ${summary}${tools}`
    })
    .join('\n')

const hideNames = (text: string) => {
  const servers = new Set<string>()
  const paragraphs = text.split('\n\n').flatMap(paragraph => {
    const lines = paragraph.split('\n')
    // Removal notices stay whole, so Claude still learns which tools went away.
    if (NOTICE.test(lines[0])) return [paragraph]
    const left = lines.filter(line => {
      const name = LISTED_NAME.exec(line.trim())?.[1]
      if (name !== undefined) noteLocalServer(name)
      const server = name === undefined ? undefined : MCP_SERVER.exec(name)?.[1]
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
  const sorted = [...servers].sort()
  const example = shown(sorted[0]).trim().split(' ')[0].toLowerCase() || sorted[0].toLowerCase()
  const note = `Not listed but findable with ToolSearch keywords, such as a service name (e.g. "${example}"): tools from ${sorted.join(', ')}.`

  return [...paragraphs, note].join('\n\n')
}

// Groups a local server's "## " sub-headings with it in the report. Local notes always stay in the prompt, so a wrong
// guess only mislabels a report row.
const isLocalHeading = (heading: string) => localServers.has(serverKey(heading)) || SERVER_NAME.test(heading)

// Server notes are free-form markdown. The engine sorts each update's sections by server name, ASCII names first, so
// connector sections of the same group sit together. A "## " line inside a connector's notes belongs to it, unless no
// connector of the same group follows: then it may start a local server's notes instead. That connector's section is
// then kept shown whole, so it reads correctly either way and a wrong guess costs tokens, never instructions.
const splitSections = (notes: string) => {
  const sections: string[] = []
  const subheaded = new Set<number>()
  let inConnector = false
  for (const line of notes.split('\n')) {
    const isConnector = HEADING.test(line)
    if (sections.length === 0 || isConnector || (SUBHEADING.test(line) && !inConnector)) {
      sections.push(line)
      inConnector = isConnector
    } else {
      sections[sections.length - 1] += `\n${line}`
      if (inConnector && SUBHEADING.test(line)) subheaded.add(sections.length - 1)
    }
  }
  const connectors = sections.flatMap((section, index) => {
    const name = HEADING.exec(section.split('\n', 1)[0])?.[1]

    return name === undefined ? [] : [{ index, ascii: isAscii(name) }]
  })
  const shown = new Set(connectors.filter((connector, at) => subheaded.has(connector.index) && connectors[at + 1]?.ascii !== connector.ascii).map(connector => connector.index))

  return { sections: sections.map(section => section.trimEnd()), shown }
}

// The engine appends its disconnect notice right after the last server's notes, so it is split off and always kept.
// A connector can connect after its tools are loaded, so notes first seen after that stay in the prompt.
const hideInstructions = (text: string, agent: string) => {
  const cut = text.indexOf(DISCONNECTED)
  const notes = cut === -1 ? text : text.slice(0, cut).trimEnd()
  const notice = cut === -1 ? '' : text.slice(cut)
  // A disconnected connector's notes no longer apply, so they are sent again if it comes back.
  for (const line of notice.split('\n')) {
    const name = DISCONNECTED_CONNECTOR.exec(line.trim())?.[1]
    // A disconnected server's notes left the prompt with it, so they no longer count as kept.
    const key = name === undefined ? serverKey(line.trim()) : connectorKey(name)
    if (name !== undefined) forget(key)
    for (const [label, row] of kept) if (label.endsWith(SERVER_NOTES) && row.texts.has(key)) kept.delete(label)
  }
  // A "## " line inside a local server's notes that does not look like a server continues that server's notes.
  let local: string | undefined
  const split = splitSections(notes)
  const sections = split.sections.filter((section, index) => {
    const first = section.split('\n', 1)[0] ?? ''
    const name = HEADING.exec(first)?.[1]
    if (name === undefined) {
      // A local server's notes stay in the prompt, so the report counts them as sent.
      const heading = SUBHEADING.exec(first)?.[1]
      if (heading === undefined) return true
      if (local === undefined || isLocalHeading(heading)) {
        local = heading
        record(kept, `${local}${SERVER_NOTES}`, serverKey(local), section)
      } else {
        const label = `${local}${SERVER_NOTES}`
        const text = kept.get(label)?.texts.get(serverKey(local))
        record(kept, label, serverKey(local), text === undefined ? section : `${text}\n${section}`)
      }

      return true
    }
    local = undefined
    const server = connectorKey(name)
    // The engine asks again about old attachments after a resume or mod reload, so notes hidden before stay hidden.
    const hash = `${agent}:${hashOf(`${server}\n${section}`)}`
    const keep = NOTES.has(server) || (used.has(`${agent}:${server}`) && !seen.has(hash)) || split.shown.has(index)
    const label = `${shown(server)} server notes`
    record(keep ? kept : hidden, label, server, section)
    if (keep) sent.add(`${agent}:${server}`)
    else {
      seen.add(hash)
      // Notes kept earlier and hidden now, such as after compaction, are no longer in the prompt.
      kept.get(label)?.texts.delete(server)
      if (kept.get(label)?.texts.size === 0) kept.delete(label)
    }

    return keep
  })
  const parts = [sections.some(section => section.startsWith('## ')) ? sections.join('\n\n') : '', notice].filter(part => part !== '')

  return parts.length === 0 ? null : parts.join('\n')
}

// The report with /context's categories, the MCP row corrected and what context-lean hides. Throws when it cannot be built.
const reportText = async ($: EngineInterface): Promise<{ text: string; line: string }> => {
  await load($)
  const usage = await $.session.usage({ breakdown: 'full' })
  if (!usage.context.tokens) {
    // Nothing was sent yet, so there is no real size, and the tools the mod defers are still counted. The last
    // report stands in, with when it was measured; without one, /context runs the built-in command.
    const last = (await $.store.get(LAST_REPORT).catch(() => undefined)) as (Report & { at: number }) | undefined
    if (typeof last?.real !== 'number') throw new Error('nothing sent yet')
    const saved: Report = { ...last, categories: last.categories ?? [], note: `No message sent in this session yet, so these numbers are from your last report (${new Date(last.at).toLocaleString()}).` }

    return { text: report(saved), line: summary(saved) }
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
  const described = new Set([...hidden.values()].filter(row => row.label !== AGENTS && row.label.includes(DESCRIPTION)).flatMap(row => [...row.texts.keys()]))
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
  const [counted, keptRows] = await Promise.all([rows(stillHidden), rows(new Map([...kept, ...sentRows]))])
  // Shortened agent descriptions still send their one-line summaries, so only the difference is saved.
  const agents = stillHidden.get(AGENTS)
  const summaries = agents === undefined ? undefined : await count(`${AGENTS} summaries`, [...agents.texts.keys()].map(name => AGENT_SUMMARIES[name] ?? '').join('\n'))
  const hiddenRows = counted.map(row =>
    row.label !== AGENTS || row.tokens === undefined ? row : { ...row, tokens: summaries === undefined || base === undefined ? undefined : Math.max(0, row.tokens - (summaries - base)) },
  )
  const categories: Category[] = (usage.context.breakdown?.categories ?? []).map(({ name, tokens, kind, color }: Category) => ({ name, tokens, kind, color }))
  const measured: Report = { real: usage.context.tokens, window: usage.context.window, estimate: usage.context.breakdown?.totalTokens, model, categories, hidden: hiddenRows, kept: keptRows }
  // The last report is stored as plain JSON, without fields left undefined.
  await Promise.all([$.store.set(COUNTS, { model, rows: { ...known, ...fresh } }), $.store.set(LAST_REPORT, JSON.parse(JSON.stringify({ ...measured, at: Date.now() })))]).catch(() => undefined)

  return { text: report(measured), line: summary(measured) }
}

// Reports are drawn in the row of the command that made them. The row's text, all the model reads, is one summary
// line naming the report, so a report costs about 25 tokens of context instead of about 2k.
const REPORT_ID = /\[context-lean report ([a-z0-9]+)\]/
const REPORTS_KEPT = 20
const reports = new Map<string, string>()
let reportCount = 0
const keep = ({ text, line }: { text: string; line: string }) => {
  const id = `${Date.now().toString(36)}${(reportCount++).toString(36)}`
  reports.set(id, text)
  for (const old of reports.keys()) if (reports.size > REPORTS_KEPT) reports.delete(old)

  return `${line} [context-lean report ${id}]`
}


// The report's 256-color codes as hex, for the row's text elements.
const BASE_COLORS = ['#000000', '#800000', '#008000', '#808000', '#000080', '#800080', '#008080', '#c0c0c0', '#808080', '#ff0000', '#00ff00', '#ffff00', '#0000ff', '#ff00ff', '#00ffff', '#ffffff']
const CUBE = [0, 95, 135, 175, 215, 255]
const hex = (value: number) => value.toString(16).padStart(2, '0')
const hexOf = (code: number) => {
  if (code < 16) return BASE_COLORS[code] ?? '#ffffff'
  if (code >= 232) return `#${hex(8 + 10 * (code - 232)).repeat(3)}`
  const cube = code - 16

  return `#${[Math.floor(cube / 36), Math.floor(cube / 6) % 6, cube % 6].map(level => hex(CUBE[level] ?? 0)).join('')}`
}
type Segment = { text: string; color?: string; italic?: true }
const ANSI = /\u001b\[([0-9;]*)m/
// Splits one line of the report at its color codes into styled runs.
const segmentsOf = (line: string) => {
  const segments: Segment[] = []
  let color: string | undefined
  let italic = false
  const parts = line.split(ANSI)
  parts.forEach((part, i) => {
    if (i % 2 === 0) {
      if (part !== '') segments.push({ text: part, ...(color === undefined ? {} : { color }), ...(italic ? { italic: true as const } : {}) })
      return
    }
    const code = part.split(';')
    if (code[0] === '38' && code[1] === '5') color = hexOf(Number(code[2]))
    else if (part === '39') color = undefined
    else if (part === '3') italic = true
    else if (part === '23') italic = false
  })

  return segments
}

export const register: Register = on => {
  // /context shows the corrected report; before the first request, the last saved one. With arguments (such as "all"),
  // or when no report can be built, the built-in /context runs.
  on('command.run', { command: 'context' }, async ($, given, next) => {
    // A plugin's $.command.run can leave args out; the engine's runs always carry them.
    const e = { ...given, args: given.args ?? '' }
    if (e.args.trim() !== '') return next(e)
    const built = await reportText($).catch(() => undefined)

    return built === undefined ? next(e) : { text: keep(built) }
  })

  // Draws a kept report in its /context row in place of the summary line the model read, behind the same "⎿" bracket
  // and indent as the engine's command rows. The engine refuses color codes in a row's text, so the report's colors
  // become styled runs. A report this process no longer holds (after a restart or a reload) leaves the summary line.
  on('ui.render', { component: 'CommandOutput', props: { command: 'context' } }, async ($, e, next) => {
    const id = REPORT_ID.exec(e.props.text)?.[1]
    const text = id === undefined ? undefined : reports.get(id)
    if (text === undefined) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    const lines = text.split('\n').map(line => h(Text, null, ...(line === '' ? [' '] : segmentsOf(line).map(({ text: run, ...style }) => h(Text, style, run)))))
    const tree = h(Box, { flexDirection: 'row' }, h(Text, { dimColor: true }, '  ⎿  '), h(Box, { flexDirection: 'column' }, ...lines)) as RenderElement | null | undefined

    return tree ?? next(e)
  })

  // Sends a hidden connector's server notes with the first ToolSearch result or tool call that uses it.
  on('tool.call', async ($, e, next) => {
    if (e.tool !== 'ToolSearch' && connectorOf(e.tool) === undefined) return next(e)
    const ran = await next(e)
    if (!('result' in ran)) return ran
    await load($)
    const agent = e.agentId ?? 'main'
    // Only ToolSearch results load tools. Other results can be large and can name tools in untrusted text.
    const servers = new Set(e.tool === 'ToolSearch' ? [...mentions(ran.result).matchAll(CONNECTOR_ANYWHERE)].map(match => match[1]) : [connectorOf(e.tool)!])
    const fresh = [...servers].filter(server => !used.has(`${agent}:${server}`))
    for (const server of fresh) used.add(`${agent}:${server}`)
    const notes = [...servers].flatMap(server => {
      const text = hidden.get(`${shown(server)} server notes`)?.texts.get(server)
      if (text === undefined || sent.has(`${agent}:${server}`)) return []
      sent.add(`${agent}:${server}`)

      return [`Server notes for this connector, sent now that its tools are in use:\n${text}`]
    })
    if (fresh.length > 0 || notes.length > 0) save($)
    if (notes.length === 0) return ran

    return { ...ran, context: [...(ran.context ?? []), ...notes] }
  })

  on('tool.describe', { tool: 'ToolSearch' }, async ($, e, next) => {
    const described = await next(e)

    return { ...described, description: described.description + HINT }
  })

  on('tool.describe', async ($, e, next) => {
    noteLocalServer(e.tool)
    const server = connectorOf(e.tool)
    if (!ARTIFACT_TOOLS.has(e.tool) && !RARE_TOOLS.has(e.tool) && server === undefined) return next(e)
    const described = await next(e)
    if (e.isDeferred !== true) {
      await load($)
      if (record(hidden, server === undefined ? `${e.tool}${DESCRIPTION}` : `${shown(server)} tool${DESCRIPTION}s`, e.tool, described.description)) save($)
    }
    const description = ARTIFACT_TOOLS.has(e.tool) ? NOTE + described.description : described.description

    return { description, isDeferred: true }
  })

  on('prompt.attachment', { type: 'deferred_tools_delta' }, async ($, e, next) => {
    const { text } = await next(e)
    if (text === null) return { text }
    await load($)
    const left = hideNames(text.replace(ARTIFACT_ENTRY, `Artifact: reads claude.ai artifact links; publishes pages on claude.ai. ${RULE}`))
    save($)

    // An empty string would still send an empty attachment; null leaves it out.
    return { text: left === '' ? null : left }
  })

  on('prompt.attachment', { type: 'agent_listing_delta' }, async ($, e, next) => {
    const { text } = await next(e)
    if (text === null) return { text }
    await load($)
    const left = shortenAgents(text)
    save($)

    return { text: left }
  })

  on('prompt.attachment', { type: 'skill_listing' }, async ($, e, next) => {
    const { text } = await next(e)

    return { text: text === null || text.startsWith(SKILL_NOTE) ? text : SKILL_NOTE + text }
  })

  on('prompt.attachment', { type: 'mcp_instructions_delta' }, async ($, e, next) => {
    const { text } = await next(e)
    if (text === null) return { text }
    await load($)
    const left = hideInstructions(text, e.agentId ?? 'main')
    save($)

    return { text: left }
  })

  // Compaction summarizes away the results that carried sent notes, so that agent's connector notes are sent again.
  on('session.compact', async ($, e, next) => {
    const compacted = await next(e)
    // A precomputed compaction is only stored; it fires again with another trigger when applied.
    if (e.trigger === 'precompute' || compacted.messages === undefined) return compacted
    await load($)
    const agent = `${e.agentId ?? 'main'}:`
    for (const set of [sent, used, seen]) for (const entry of set) if (entry.startsWith(agent)) set.delete(entry)
    save($)

    return compacted
  })
}
