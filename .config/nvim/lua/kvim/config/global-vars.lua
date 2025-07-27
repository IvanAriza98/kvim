vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.cursorline = true
vim.opt.syntax = "on"
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smarttab = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.compatible = false
-- vim.opt.encoding = "UTF-8"
--vim.opt.guifont = "FiraCode Nerd Font:h11"
-- vim.opt.termguicolors = true
-- vim.o.guifont = "Monaspace Radon"

--- lines customization
vim.opt.number = true
vim.wo.relativenumber = true

--- Paths
local kvim_home = vim.env.KVIM_HOME
if not kvim_home or kvim_home == "" then
	vim.notify(
		"Env variable KVIM_HOME is not set. Please set it to the path of your KVIM installation.",
		vim.log.levels.ERROR
	)
	return
end

vim.g.kvim_home = kvim_home
vim.g.configs_path = vim.g.kvim_home .. ".config/nvim/configs.json"
