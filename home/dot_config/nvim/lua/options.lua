require "nvchad.options"

if #vim.api.nvim_list_uis() == 0 then
  require('options.headless')
else
  require('options.interactive')
end
