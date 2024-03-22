-- EXAMPLE 
local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "typos_lsp", "yamlls" }

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

lspconfig.vale_ls.setup({
  settings = {
    initializationParams = {
      syncOnStartup = true,
      installVale = true,
      configPath = vim.env.VALE_CONFIG_PATH
    }
  }
})

lspconfig.tsserver.setup({
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  capabilities = capabilities
})

lspconfig.stylelint_lsp.setup({
  root_dir = lspconfig.util.root_pattern(".git", "package.json"),
  filetypes = { "css", "scss" },
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  capabilities,
  settings = {
    stylelintplus = {
      autoFixOnFormat = true,
      configFile = vim.fn.expand('$HOME/Projects/brandonocasey/js-metarepo/tooling/stylelint/src/js/config.cjs')
    },
  },
})

lspconfig.eslint.setup({
 root_dir = require("lspconfig").util.root_pattern(".git", "package.json"),
 on_attach = function(client)
   client.server_capabilities.document_formatting = true
 end,
 capabilities,
 settings = {
   codeActionOnSave = {
     enable = true
   },
   configFile = vim.fn.expand('$HOME/Projects/brandonocasey/js-metarepo/tooling/eslint-tsc/src/js/eslint-config.cjs')
 },
})
