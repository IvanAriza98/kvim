vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.cursorline = true
vim.opt.syntax = "on"
vim.opt.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.tabstop = 8
vim.opt.softtabstop = 0
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.compatible = false
-- vim.opt.encoding = "UTF-8"
--vim.opt.guifont = "FiraCode Nerd Font:h11"
-- vim.opt.termguicolors = true
-- vim.o.guifont = "Monaspace Radon"

--- lines customization
vim.opt.number = true
-- vim.wo.relativenumber = true

--- Paths
-- TODO I must be think how to treat individual paths
-- vim.g.git_path = "/home/iariza/Documents/GitHub/kvim/.config/nvim/"
-- find dynamically location of .config/nvim/configs.json
-- vim.g.git_path = "/home/iariza/Documents/Github/kvim/.config/nvim/"

-- local nvim_repo_root = vim.fn.fnamemodify(current_file, ":p:h:h:h:h")
-- vim.g.configs_path = nvim_repo_root .. "/configs.json"
-- vim.g.configs_path = "/home/iariza/Documents/Github/kvim/.config/nvim/configs.json"
vim.g.configs_path = "/home/kodvmv/Documentos/GitHub/kvim/.config/nvim/configs.json"
