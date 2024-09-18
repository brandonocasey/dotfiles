-- EXAMPLE
local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"
local servers = {
  "jsonls",
  "html",
  "cssls",
  "typos_lsp",
  "lua_ls",
  "yamlls",
  "bashls",
  "ts_ls"
}

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

lspconfig.vale_ls.setup({
  on_init = on_init,
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    initializationParams = {
      syncOnStartup = true,
      installVale = true,
      configPath = vim.env.VALE_CONFIG_PATH
    }
  }
})

lspconfig.stylelint_lsp.setup({
  filetypes = { "css", "scss", "less" },
  on_attach = on_attach,
  capabilities = capabilities,
  on_init = on_init,
  settings = {
    stylelintplus = {
      autoFixOnFormat = true,
    },
  },
})

lspconfig.eslint.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  on_init = on_init
})

-- show diagnostics in a float window if there isn't already one open
vim.api.nvim_create_autocmd({ "CursorHold" }, {
  pattern = "*",
  callback = function()
    for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(winid).zindex then
        return
      end
    end
    vim.diagnostic.open_float({
      scope = "cursor",
      focusable = false,
      close_events = {
        "CursorMoved",
        "CursorMovedI",
        "BufHidden",
        "InsertCharPre",
        "WinLeave",
      },
    })
  end
})
