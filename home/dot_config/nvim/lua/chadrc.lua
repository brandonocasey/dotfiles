local M = {
  base46 = {
    theme = 'onedark',
    theme_toggle = { "onedark", "one_light" },
    lsp_semantic_tokens = true,

    hl_override = {
      Comment = {
        italic = true,
      },
    },
  },
  ui = {
    statusline = {
      theme = "vscode_colored",
    }
  },
  mason = {
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
}

return M
