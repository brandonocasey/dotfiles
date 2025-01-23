local M = {}

M.base46 = {
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
  }
}

M.mason = {
  pkgs = {
    -- spelling
    "typos-lsp",

    -- lua stuff
    "lua-language-server",
    -- "stylua",

    -- shell
    "shellcheck",
    "bash-language-server",

    -- markdown
    "vale",
    "vale-ls",
    "markdownlint-cli2",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "eslint-lsp",
    "stylelint-lsp",
    -- "eslint_d",
    "typescript-language-server",

    -- github actions
    "actionlint",

    -- docker
    "hadolint",

    -- json
    "json-lsp",

    "ltex-ls",

    -- yaml
    "yaml-language-server",
  }
}

return M
