return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        typos_lsp = {},
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
          filetypes = { "css", "scss", "less" },
          settings = {
            stylelintplus = {
              autoFixOnFormat = true,
            },
          },
        },
        ltex = {
          settings = {
            ltex = {
              language = "en",
              additionalRules = {
                languageModel = "~/.local/share/ngrams",
              },
            },
          },
        },
        eslint = {},
      },
    },
  },
}
