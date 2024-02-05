---@type ChadrcConfig
local M = {}

M.ui = {
  theme = 'onedark',
  lsp_semantic_tokens = true,
  transparency = true,

  hl_override = {
    Comment = {
      italic = true,
    },
  },
  statusline = {
    theme = "vscode_colored",
    overriden_modules = function(modules)
      -- remove branch
      table.remove(modules, 3)
      -- remove utf8
      table.remove(modules, 9)

    end,
  }
  --hl_add = {
  --  NvimTreeOpenedFolderName = { fg = "green", bold = true },
  --}
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M
