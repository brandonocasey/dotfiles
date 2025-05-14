return {
  -- Make the home key go to ^ or 0 in a smart way similar to most IDEs
  {
    "bwpge/homekey.nvim",
    event = "VeryLazy",
  },
  -- remember the last line that was being edited in a file
  {
    "farmergreg/vim-lastplace",
    lazy = false,
  },

  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        keyword = { rande = "full" },
      },
    },
  },

  -- faster escape key usage
  {
    "max397574/better-escape.nvim",
    config = function()
      require("better_escape").setup()
    end,
  },

  -- cursor animation so that it doesn't get lost
  {
    "sphamba/smear-cursor.nvim",
    opts = {
      -- legacy_computing_symbols_support = true,
      transparent_bg_fallback_color = "#303030",
      stiffness = 0.9, -- 0.6      [0, 1]
      trailing_stiffness = 0.5, -- 0.3      [0, 1]
      distance_stop_animating = 0.5, -- 0.1      > 0
      hide_target_hack = true, -- true     boolean
    },
  },

  -- better undo files
  {
    "kevinhwang91/nvim-fundo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "VeryLazy",
    opts = {},
    build = function()
      require("fundo").install()
    end,
  },

  -- have vim handle line/column numbers and the file:// protocol in file names
  {
    "wsdjeg/vim-fetch",
    lazy = false,
  },

  -- pipe to nvim and open as a buffer
  {
    "willothy/flatten.nvim",
    config = true,
    lazy = false,
    priority = 1001,
  },

  -- guess file indent and set vim's indent to that
  {
    "nmac427/guess-indent.nvim",
    lazy = false,
    config = function()
      require("guess-indent").setup()
    end,
  },

  -- automatically trim bad whitespace
  {
    "cappyzawa/trim.nvim",
    cond = function()
      return not string.match(vim.bo.filetype, "snacks_dashboard")
    end,
    event = "VeryLazy",
    opts = {
      highlight = true,
      trim_last_line = false,
    },
  },

  -- edit the file system in a vim-like manor
  {
    "stevearc/oil.nvim",
    opts = {
      skip_confirm_for_simple_edits = true,
    },
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },

  -- access any of the edits in the undo tree!
  {
    "jiaoshijie/undotree",
    dependencies = "nvim-lua/plenary.nvim",
    config = true,
    keys = { -- load the plugin only when using it's keybinding:
      { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
    },
  },
}
