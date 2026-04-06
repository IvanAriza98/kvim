-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end

-- Añade al runtimepath antes de require
vim.opt.rtp:prepend(lazypath)

require("kvim.core")

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- import your plugins
		{ import = "kvim.plugins" },
		{ import = "kvim.plugins.ai" },
		{ import = "kvim.plugins.lsp" },
		{ import = "kvim.plugins.lualine" },
		{ import = "kvim.plugins.alpha" },
	},
    defaults = { lazy = true },
	-- automatically check for plugin updates
	checker = { enabled = true },
    change_detection = { notify = false },
    lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
})

-- Load all utils before own scripts
require("kvim.utils")
require("kvim.layouts")
