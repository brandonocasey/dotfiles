local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
  autotag = {
    enable = true
  },
  endwise = {
    enable = true
  }
}

M.mason = {
  ensure_installed = {
    -- spelling
    "typos-lsp",

    -- lua stuff
    "lua-language-server",
    "stylua",

    -- shell
    "shellcheck",

    -- markdown
    "proselint",
    "write-good",
    "grammarly-languageserver",
    "alex",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "eslint-lsp",
    "stylelint-lsp",
    "eslint_d",
    -- somewhat handled by typescript-tools.nvim
    "typescript-language-server",


    -- github actions
    "actionlint",

    -- docker
    "hadolint",

    -- json
    "jsonlint",
    "fixjson",

    -- yaml
    "yaml-language-server",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

return M
