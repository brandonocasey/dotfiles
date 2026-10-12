import type { Register } from 'claude-code'

// claude.ai connectors used often enough to stay listed. The rest stay callable through ToolSearch.
const KEEP = new Set(['Atlassian', 'Atlassian_MCP', 'Slack'])
const TOOL = /^mcp__claude_ai_(.+?)__/
const HEADING = /^## claude\.ai (.+)$/

const hiddenServer = (tool: string) => {
  const server = TOOL.exec(tool)?.[1]

  return server !== undefined && !KEEP.has(server) ? server : undefined
}

const hideTools = (text: string) => {
  const servers = new Set<string>()
  const paragraphs = text.split('\n\n').flatMap(paragraph => {
    const lines = paragraph.split('\n')
    const kept = lines.filter(line => {
      const server = hiddenServer(line.trim())
      if (server !== undefined) servers.add(server)
      return server === undefined
    })

    return kept.length === lines.length || kept.length > 1 ? [kept.join('\n')] : []
  })
  if (servers.size === 0) return text
  const note = `Not listed but findable with ToolSearch keywords (e.g. "datadog logs"): tools from ${[...servers].sort().join(', ')}.`

  return [...paragraphs, note].join('\n\n')
}

const hideInstructions = (text: string) => {
  const sections = text.split(/\n\n(?=## )/).filter(section => {
    const server = HEADING.exec(section.split('\n', 1)[0])?.[1].replace(/[^A-Za-z0-9_-]/g, '_')

    return server === undefined || KEEP.has(server)
  })

  return sections.some(section => section.startsWith('## ')) ? sections.join('\n\n') : null
}

export const register: Register = on => {
  on('tool.describe', async ($, e, next) => {
    if (hiddenServer(e.tool) === undefined) return next(e)
    const described = await next(e)

    return { description: described.description, isDeferred: true }
  })

  on('prompt.attachment', { type: 'deferred_tools_delta' }, async ($, e, next) => {
    const { text } = await next(e)

    return { text: text === null ? null : hideTools(text) }
  })

  on('prompt.attachment', { type: 'mcp_instructions_delta' }, async ($, e, next) => {
    const { text } = await next(e)

    return { text: text === null ? null : hideInstructions(text) }
  })
}
