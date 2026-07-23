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

-- Round indents to multiples of shiftwidth
vim.opt.shiftround = true

vim.opt.undolevels = 1000000

-- start scrolling when we're 15 lines away from the edge of the top/bottom
vim.opt.scrolloff = 15

-- set clipboard to 1000kb and 10000 line limit
vim.opt.shada = "!,'100,<10000,s1000,h"

-- linematch diff
vim.opt.diffopt:append({ linematch = 60 })

-- faster completion
vim.opt.updatetime = 100
-- wait for mapped sequenences to complete
vim.opt.timeoutlen = 1000

-- pop up menu height
vim.opt.pumheight = 10

-- do not write backups
vim.opt.writebackup = false

vim.opt.shell = "/usr/bin/env bash"
-- shown in the statusline instead
vim.opt.showcmd = false
vim.opt.ruler = false

-- don't show redundant messages from insert completion menu
vim.opt.shortmess:append("c")

vim.filetype.add({
  pattern = {
    ["openapi.*%.ya?ml"] = "yaml.openapi",
    ["swagger.*%.ya?ml"] = "yaml.openapi",
    ["openapi.*%.json"] = "json.openapi",
    ["swagger.*%.json"] = "json.openapi",
  },
})
