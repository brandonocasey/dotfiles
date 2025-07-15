-- The configuration assumes that you've installed and
-- enabled the Biome LSP.

-- Whenever an LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if not client then
      return
    end

    -- When the client is Biome, add an automatic event on
    -- save that runs Biome's "source.fixAll.biome" code action.
    -- This takes care of things like JSX props sorting and
    -- removing unused imports.
    if client.name == "biome" then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("BiomeFixAll", { clear = true }),
        callback = function()
          vim.lsp.buf.code_action({
            context = {
              only = { "source.fixAll.biome" },
              diagnostics = {},
            },
            apply = true,
          })
        end,
      })
    end
  end,
})
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "ltex-ls-plus", "gh-actions-language-server", "markdownlint-cli2", "vacuum", "biome" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {

        marksman = {},
        typos_lsp = {},
        biome = {},
        docker_compose_language_service = {},
        dockerls = {},
        gh_actions_ls = {},
        vacuum = {},
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
