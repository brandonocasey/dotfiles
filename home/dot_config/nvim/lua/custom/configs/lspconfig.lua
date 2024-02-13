local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

-- if you just want default config for the servers then put them in a table
-- tsserver is handled by typescript-tools.nvim, see plugins.lua
local servers = { "html", "cssls", "typos_lsp", "yamlls" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

lspconfig.tsserver.setup({
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  capabilities = capabilities
})

lspconfig.stylelint_lsp.setup({
  root_dir = require("lspconfig").util.root_pattern(".git", "package.json"),
  filetypes = { "css", "scss" },
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  capabilities,
  settings = {
    stylelintplus = {
      autoFixOnFormat = true,
      configFile = vim.fn.expand('$HOME/BrandonProjects/js-metarepo/tooling/css-lint/src/js/config.cjs')
    },
  },
})

--lspconfig.eslint.setup({
--  root_dir = require("lspconfig").util.root_pattern(".git", "package.json"),
--  on_attach = function(client)
--    client.server_capabilities.document_formatting = true
--  end,
--  capabilities,
--  settings = {
--    codeActionOnSave = {
--      enable = true
--    },
--    configFile = vim.fn.expand('$HOME/BrandonProjects/js-metarepo/tooling/js-lint/src/js/config.cjs')
--  },
--})
