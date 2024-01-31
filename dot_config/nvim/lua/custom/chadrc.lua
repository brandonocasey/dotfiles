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
          -- replace git root in path with nothing
          path = path:gsub(vim.fn.finddir(".git", ".;"):gsub('.git', ''), '')
          -- if there is no git root replace $HOME with ~/
          path = path:gsub(vim.fn.expand('$HOME/'), '~/')
          --path = path:gsub(vim.lsp.buf.list_workspace_folders()[1], '<root>')
          return "%#St_LspStatus# " .. path .. " "
        end)()
      )

      -- remove branch
      table.remove(modules, 4)
      -- remove utf8
      table.remove(modules, 10)
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
