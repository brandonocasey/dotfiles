local null_ls = require("null-ls")

local eslint_d = {
  extra_args = {
    '--no-eslintrc',
    '--no-error-on-unmatched-pattern',
    '--report-unused-disable-directives',
    '--config',
    vim.fn.expand('$HOME/Projects/js-metarepo/tooling/js-lint/src/js/config.cjs'),
    '--ext',
    '.js,.ts,.jsx,.mjs,.cjs,.tsx',
    '--cache'
  }
}

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local M = {
  -- you can reuse a shared lspconfig on_attach callback here
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ async = false })
        end,
      })
    end
  end,

  sources = {
    -- javascript
    null_ls.builtins.code_actions.eslint_d.with(eslint_d),
    null_ls.builtins.diagnostics.eslint_d.with(eslint_d),
    null_ls.builtins.formatting.eslint_d.with(eslint_d),

    -- markdown
    -- null_ls.builtins.formatting.remark

    -- shell
    null_ls.builtins.code_actions.shellcheck,
    null_ls.builtins.diagnostics.shellcheck,

    -- github actions
    null_ls.builtins.diagnostics.actionlint,

    -- docker
    null_ls.builtins.diagnostics.hadolint,

    -- json
    null_ls.builtins.diagnostics.jsonlint,
    null_ls.builtins.formatting.fixjson,

    -- remove trailing whitespace automatically
    null_ls.builtins.formatting.trim_whitespace

  }
}


null_ls.setup({
  on_attach = M.on_attach,
  sources = M.sources
})

return M;
