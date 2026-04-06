vim.cmd([[
augroup kvim_lazy_layouts
  autocmd!
  autocmd FileType * ++once lua require("kvim.layouts.main-menu")
  autocmd FileType * ++once lua require("kvim.layouts.cmd-buffer")
augroup END
]])

local lazy_load = function(module)
  vim.defer_fn(function()
    require(module)
  end, 100)
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      lazy_load("kvim.layouts.configs.esp-idf.config")
      lazy_load("kvim.layouts.configs.nrf-sdk.config")
      lazy_load("kvim.layouts.configs.general.python-config")
    end, 500)
  end,
})

