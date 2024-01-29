local capabilities = require("plugins.configs.lspconfig").capabilities

local M = {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  capabilities = capabilities
}


require("typescript-tools").setup(M);

return M;
