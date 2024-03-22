if #vim.api.nvim_list_uis() == 0 then
  require('custom.settings.headless')
else
  require('custom.settings.interactive')
end
