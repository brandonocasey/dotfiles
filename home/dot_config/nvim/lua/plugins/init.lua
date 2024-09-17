local highlight = {
  "RainbowRed",
  "RainbowYellow",
  "RainbowBlue",
  "RainbowOrange",
  "RainbowGreen",
  "RainbowViolet",
  "RainbowCyan",
}

local hooks = require "ibl.hooks"
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
  vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
  vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
  vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
  vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
  vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
  vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
  vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

return {

  { "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        highlight = highlight
      }
    }
  },

  { "folke/neodev.nvim", opts = {}, lazy = false },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("neodev").setup()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      user_default_options = {
        css = true;
      }
    }
  },


  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
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

        -- yaml
        "yaml-language-server",
      },
    }
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "bash",
        "css",
        "csv",
        "fish",
        "gitcommit",
        "gitignore",
        'gitattributes',
        "git_config",
        "git_rebase",
        "html",
        "javascript",
        "json",
        "json5",
        "lua",
        "markdown",
        "markdown_inline",
        "perl",
        "php",
        "python",
        "scss",
        "ssh_config",
        "sql",
        "tmux",
        "typescript",
        "tsx",
        "toml",
        "xml",
        "yaml",

      },
      indent = {
        enable = true,
      },
      autotag = {
        enable = true
      },
      endwise = {
        enable = true
      }
    }
  },

  {
    "windwp/nvim-autopairs",
    opts = {
      check_ts = true
    }
  },

  -- Install a plugin
  {
    'nvimtools/none-ls.nvim',
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local null_ls = require('null-ls')

      null_ls.setup({
        sources = {
          -- github actions
          null_ls.builtins.diagnostics.actionlint,

          -- docker
          null_ls.builtins.diagnostics.hadolint,
        }
      })
    end
  },

  {
    "NvChad/nvcommunity",
    { import = "nvcommunity.editor.rainbowdelimiters" },
    { import = "nvcommunity.editor.treesittercontext" },
    { import = "nvcommunity.editor.telescope-undo" },
    { import = "nvcommunity.diagnostics.trouble" },
    { import = "nvcommunity.motion.neoscroll" },
    { import = "nvcommunity.tools.telescope-fzf-native" },
    { import = "nvcommunity.file-explorer.oil-nvim"},
    { import = "nvcommunity.lsp.barbecue"},
  },
  {
    "hrsh7th/nvim-cmp",
    config = function(_, opts)
      table.insert(opts.sources, { name = "copilot" })
      require("cmp").setup(opts)
    end,
    dependencies = { "zbirenbaum/copilot-cmp" }
  },
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
    }
  },

  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" }
  },

  {
    "kevinhwang91/nvim-fundo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "VeryLazy",
    opts = {},
    build = function()
      require("fundo").install()
    end,
  },

  {
    "wsdjeg/vim-fetch",
    lazy = false
  },

  {
    "nvim-pack/nvim-spectre",
    build = false,
    cmd = "Spectre",
    opts = { open_cmd = "noswapfile vnew" },
    -- stylua: ignore
    keys = {
      { "<leader>sr", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
    },
  },

  {
    "RRethy/nvim-treesitter-endwise",
    event = { "BufReadPost", "BufNewFile" },
  },
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- configuration here
      })
    end,
  },

  {
    'nmac427/guess-indent.nvim',
    lazy = false,
    config = function()
      require('guess-indent').setup()
    end,
  },
  {
    "cappyzawa/trim.nvim",
    lazy = false,
    opts = {
      highlight = true,
      trim_last_line = false
    }
  },
}
