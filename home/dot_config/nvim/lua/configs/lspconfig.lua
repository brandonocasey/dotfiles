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
  "tsserver"
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
  root_dir = lspconfig.util.root_pattern(".git", "package.json"),
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
  root_dir = require("lspconfig").util.root_pattern(".git", "package.json"),
  on_attach = on_attach,
  capabilities = capabilities,
  on_init = on_init
})

--- show diagnostics in a hover window instead of virtual text
vim.diagnostic.config({ virtual_text = false })
vim.o.updatetime = 250
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("float_diagnostic_cursor", { clear = true }),
  callback = function ()
    vim.diagnostic.open_float(nil, {focus=false, scope="cursor"})
  end
})
