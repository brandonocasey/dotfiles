-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
--

-- vim.opt.spelllang = { 'en_us' }
-- vim.opt.spell = true

-- turn off swap file
vim.opt.swapfile = false

-- Don't save code folds
vim.opt.ssop:remove({ "folds" })

-- Don't save empty/blank windows
vim.opt.ssop:remove({ "blank" })

-- Drop unused spaces at the end of lines
vim.opt.shiftround = true

vim.opt.undofile = true
vim.opt.undolevels = 1000000

-- Use Unix as the standard file format
vim.opt.fileformats = { "unix", "dos", "mac" }

-- start scrolling when we're 15 lines away from the edge of the top/bottom
vim.opt.scrolloff = 15

-- ignore (lower/upper) case when searching
vim.opt.ignorecase = true

-- only use spaces, and only 2 for indent
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

-- set clipboard to 1000kb and 10000 line limit
vim.opt.shada = "!,'100,<10000,s1000,h"

-- linematch diff
vim.opt.diffopt:append({ linematch = 60 })

-- faster completion
vim.opt.updatetime = 100
-- wait for mapped sequenences to complete
vim.opt.timeoutlen = 1000

-- Set completeopt to have a better completion experience
vim.opt.completeopt = "menuone,noselect"

-- pop up menu height
vim.opt.pumheight = 10

-- do not write backups
vim.opt.writebackup = false

vim.opt.shell = "/usr/bin/env bash"
-- handled by nvchad
vim.opt.showcmd = false
-- handled by nvchad
vim.opt.ruler = false

-- don't show redundant messages from insert completion menu
vim.opt.shortmess:append("c")

-- Lines below replaced by NvChad --
--
-- show line/column number
-- vim.opt.ruler = true

-- use system clipboard
-- vim.opt.clipboard = 'unnamedplus'
-- Relative line numbers
-- vim.opt.relativenumber = false
--
vim.filetype.add({
  pattern = {
    ["openapi.*%.ya?ml"] = "yaml.openapi",
    ["swagger.*%.ya?ml"] = "yaml.openapi",
    ["openapi.*%.json"] = "json.openapi",
    ["swagger.*%.json"] = "json.openapi",
  },
})
