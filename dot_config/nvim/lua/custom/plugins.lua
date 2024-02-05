local overrides = require("custom.configs.overrides")

---@type NvPluginSpec[]
local plugins = {

  -- Override plugin definition options

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },


  {
    "nvim-tree/nvim-tree.lua",
    opts = overrides.nvimtree,
    lazy = true,
  },

  -- Install a plugin
  {
    'nvimtools/none-ls.nvim',
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('null-ls').setup(require('custom.configs.null-ls'))
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
    -- { import = "nvcommunity.tools.conjure" },
    --{ import = "nvcommunity.lsp.lsplines" },
    --{ import = "nvcommunity.lsp.lspui" },
    --{ import = "nvcommunity.lsp.lspsaga" },
    { import = "nvcommunity.lsp.barbecue" },
  },
  {
    "wsdjeg/vim-fetch",
    lazy = false
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
    'stevearc/oil.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup()
    end,

  },
  {
    'nmac427/guess-indent.nvim',
    event = "VeryLazy",
    config = function()
      require('guess-indent').setup()
    end,

  }

  -- lua version of typescript-language-server
  -- {
  --   "pmizio/typescript-tools.nvim",
  --   event = "VeryLazy",
  --   dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  --   opts = {},
  --   config = function()
  --     require "custom.configs.typescript-tools"
  --   end,
  -- },

}


-- automatically open oil.nvim on directory
local autocmd = vim.api.nvim_create_autocmd

local function open_oil(data)

  -- buffer is a directory
  local directory = vim.fn.isdirectory(data.file) == 1

  -- buffer is a [No Name]
  local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

  if directory and not no_name then
    -- change to the directory
    vim.cmd.cd(data.file)
    -- open oil
    require("oil").open(data.file)
  end

end

autocmd({ "VimEnter" }, { callback = open_oil })



return plugins
