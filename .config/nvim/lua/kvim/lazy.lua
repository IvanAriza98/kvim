-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
require("kvim.config.global-vars")
require("kvim.config.custom-keys")

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- import your plugins
		{ import = "kvim.plugins" },
		{ import = "kvim.plugins.lsp" },
		{ import = "kvim.plugins.lualine" },
		{ import = "kvim.plugins.alpha" },
	},
	-- automatically check for plugin updates
	checker = { enabled = true },
})

-- Load all utils before own scripts
require("kvim.utils.ssh")
require("kvim.utils.config-utils")
-- Ponemos todo que necesitemos con plugins fp
require("kvim.layout.main-menu")
require("kvim.layout.cmd-buffer")
-- Development Configs
require("kvim.layout.configs.esp-idf.config")
require("kvim.layout.configs.nrf-sdk.config")
require("kvim.layout.configs.general.python-config")
-- Comunication Configs
require("kvim.layout.configs.communications.ssh-config")
