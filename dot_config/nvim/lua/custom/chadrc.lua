---@type ChadrcConfig
local M = {}

M.ui = {
  theme = "onedark",
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
      -- print path before file name
      table.insert(
        modules,
        2,
        (function()
          local path = vim.api.nvim_buf_get_name(0):match "^.*/"
          path = path:gsub(vim.lsp.buf.list_workspace_folders()[1], '<root>')
          return "%#St_LspStatus#" .. path
        end)()
      )
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
