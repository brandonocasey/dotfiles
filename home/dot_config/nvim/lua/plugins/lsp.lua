return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "ltex-ls-plus", "gh-actions-language-server", "markdownlint-cli2" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {

        marksman = {},
        typos_lsp = {},
        docker_compose_language_service = {},
        dockerls = {},
        gh_actions_ls = {},
        vale_ls = {
          settings = {
            initializationParams = {
              syncOnStartup = true,
              installVale = true,
              configPath = vim.env.VALE_CONFIG_PATH,
            },
          },
        },
        stylelint_lsp = {
          filetypes = {
            "astro",
            "css",
            "html",
            "less",
            "scss",
            "sugarss",
            "vue",
            "wxss",
            "css",
            "markdown",
          },
          settings = {
            stylelintplus = {
              autoFixOnFormat = true,
            },
          },
        },
        ltex_plus = {
          settings = {
            ltex = {
              language = "en",
              additionalRules = {
                languageModel = "~/.local/share/ngrams",
              },
              disabledRules = {
                en = { "ARROWS" },
              },
            },
          },
        },
        vtsls = {
          settings = {
            typescript = {
              format = {
                insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = false,
                insertSpaceAfterFunctionKeywordForAnonymousFunctions = false,
              },
              inlayHints = {
                enumMemberValues = { enabled = false },
                functionLikeReturnTypes = { enabled = false },
                parameterNames = { enabled = false },
                parameterTypes = { enabled = false },
                propertyDeclarationTypes = { enabled = false },
                variableTypes = { enabled = false },
              },
            },
          },
        },
        eslint = {
          filetypes = {
            "markdown",
            "html",
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
            "vue",
            "svelte",
            "astro",
          },
          settings = {
            useFlatConfig = true,
          },
        },
      },
    },
  },
}
