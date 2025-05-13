require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", "<leader>fr", function()
  require('grug-far').open()
end, { desc = "find and replace in project" })

--map("n", ";", ":", { desc = "CMD enter command mode" })
--map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

