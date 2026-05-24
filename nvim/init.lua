-- init.lua

vim.g.mapleader = " "		-- leader 
vim.g.maplocalleader = " "	-- local leader 

-- Bootstrap de lazy.nvim en el runtimepath.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    { import = "kvim.plugins" },
    -- Plugins de módulos que exponen spec propia.
    { import = "kvim.modules.git.plugins" },
    { import = "kvim.modules.workspaces.plugins" },
})

-- Punto de entrada principal del framework KVIM.
require("kvim").setup()
