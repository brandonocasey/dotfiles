import type { Register } from 'claude-code'

const ARTIFACT_TOOLS = new Set(['Artifact', 'ArtifactComments', 'ArtifactData', 'DesignSync'])
const RARE_TOOLS = new Set(['ScheduleWakeup', 'SendFeedback', 'ReportFindings', 'ListAgents', 'Agent', 'AskUserQuestion'])
const NOTE = 'Use only when the user explicitly asks for an artifact.\n\n'
const HINT = `\n\nNot listed but loadable with select:<name>: ${[...RARE_TOOLS].join(', ')}. Load one before calling it.`

export const register: Register = on => {
  on('tool.describe', { tool: 'ToolSearch' }, async ($, e, next) => {
    const described = await next(e)

    return { ...described, description: described.description + HINT }
  })

  on('tool.describe', async ($, e, next) => {
    if (!ARTIFACT_TOOLS.has(e.tool) && !RARE_TOOLS.has(e.tool)) return next(e)
    const described = await next(e)
    const description = ARTIFACT_TOOLS.has(e.tool) ? NOTE + described.description : described.description

    return { description, isDeferred: true }
  })
}
