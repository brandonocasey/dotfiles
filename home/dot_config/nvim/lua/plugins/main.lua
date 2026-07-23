return {
  -- Make the home key go to ^ or 0 in a smart way similar to most IDEs
  { "bwpge/homekey.nvim", event = "VeryLazy" },
  -- remember the last line that was being edited in a file
  { "farmergreg/vim-lastplace", lazy = false },
  -- onedark theme
  { "olimorris/onedarkpro.nvim", priority = 1000 },

  -- Configure LazyVim to load onedark
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },

  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        keyword = { range = "full" },
      },
    },
  },

  -- -- faster escape key usage
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {},
  },

  -- cursor animation so that it doesn't get lost
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    cond = vim.g.neovide == nil,
    opts = {
      -- legacy_computing_symbols_support = true,
      cursor_color = "none",
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

  -- yank over ssh or in tmux to the clipboard that is expected
  {
    "ibhagwan/smartyank.nvim",
    lazy = false,
    config = function()
      require("smartyank").setup({})
    end,
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
      require("guess-indent").setup({})
    end,
  },

  -- automatically trim bad whitespace
  {
    "cappyzawa/trim.nvim",
    event = "VeryLazy",
    opts = {
      ft_blocklist = { "snacks_dashboard" },
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
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
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

  -- automatically indent to the correct location using tab
  {
    "vidocqh/auto-indent.nvim",
    opts = {
      indentexpr = function(lnum)
        return require("nvim-treesitter.indent").get_indent(lnum)
      end,
    },
  },

  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      disabled_keys = {
        ["<Up>"] = false,
        ["<Down>"] = false,
        ["<Left>"] = false,
        ["<Right>"] = false,
      },
    },
  },

  -- nvim-treesitter's `main` branch builds parsers by shelling out to the
  -- tree-sitter CLI, which uses $CC. Only override it when the default compiler
  -- can't actually build (e.g. Unraid ships no libc headers, so cc fails on
  -- <stdint.h>); a healthy toolchain is left alone. Falls back to the newest
  -- Homebrew gcc-N/g++-N by absolute path (survives version bumps / GUI launches).
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      local src = vim.fn.tempname() .. ".c"
      vim.fn.writefile({ "#include <stdio.h>", "#include <stdint.h>", "int main(void){return 0;}" }, src)
      local ok, probe = pcall(function()
        return vim.system({ vim.env.CC or "cc", "-fsyntax-only", src }):wait()
      end)
      os.remove(src)
      if ok and probe.code == 0 then
        return -- default compiler works; don't touch anything
      end

      local bin = (vim.env.HOMEBREW_PREFIX or "/home/linuxbrew/.linuxbrew") .. "/bin"
      local newest = function(pat)
        local matches = vim.fn.globpath(bin, pat, false, true)
        table.sort(matches, function(a, b)
          return (tonumber(a:match("(%d+)$")) or 0) > (tonumber(b:match("(%d+)$")) or 0)
        end)
        return matches[1]
      end
      vim.env.CC = newest("gcc-[0-9]*") or vim.env.CC
      vim.env.CXX = newest("g++-[0-9]*") or vim.env.CXX
    end,
  },
}
