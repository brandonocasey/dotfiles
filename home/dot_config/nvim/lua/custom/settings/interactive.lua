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
vim.opt.ssop:remove { 'folds' }

-- Don't save empty/blank windows
vim.opt.ssop:remove { 'blank' }

-- Drop unused spaces at the end of lines
vim.opt.shiftround = true

-- Use Unix as the standard file format
vim.opt.fileformats = { 'unix', 'dos', 'mac' }

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
vim.opt.completeopt = 'menuone,noselect'

-- pop up menu height
vim.opt.pumheight = 10

-- do not write backups
vim.opt.writebackup = false

-- handled by nvchad
vim.opt.showcmd = false
-- handled by nvchad
vim.opt.ruler = false

-- don't show redundant messages from insert completion menu
vim.opt.shortmess:append "c"

-- Lines below replaced by NvChad --
--
-- show line/column number
-- vim.opt.ruler = true

-- use system clipboard
-- vim.opt.clipboard = 'unnamedplus'

-- return to the line that you were previously on the last time you opened this file
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  pattern = { "*" },
  callback = function()
    if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
      vim.api.nvim_exec("normal! g'\"", false)
    end
  end
})

-- TODO: change to lua lol
vim.cmd([[
  " Map the home key to go to the beginning of a line, and
  " if pressed again it will go to the start of the line
  function! SmartHome()
    let first_nonblank = match(getline('.'), '\S') + 1
    if first_nonblank == 0
      return col('.') + 1 >= col('$') ? '0' : '^'
    endif
    if col('.') == first_nonblank
      return '0'  " if at first nonblank, go to start line
    endif
    return &wrap && wincol() > 1 ? 'g^' : '^'
  endfunction
  noremap <expr> <silent> <Home> SmartHome()
  imap <silent> <Home> <C-O><Home>
]])



--" shift tab to unindent
--imap <S-Tab> <C-d>
--nmap <S-Tab> <<_<esc>
--vmap <S-Tab> <<<esc>

--" tab to indent in
--nmap <Tab> >>_<esc>
--vmap <Tab> >><esc>
