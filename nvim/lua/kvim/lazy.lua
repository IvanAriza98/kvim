--[[
    lazy.nvim: Gestor de plugins para Neovim
    https://github.com/folke/lazy.nvim

    Este archivo configura lazy.nvim y carga todos los plugins del proyecto.
    IMPORTANTE: mapleader debe configurarse ANTES de cargar lazy.nvim
--]]

-- Ruta al directorio de datos de Neovim donde se instalará lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Si lazy.nvim no está instalado, clonar desde GitHub
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

-- Añadir lazy.nvim al runtimepath ANTES de cualquier require
vim.opt.rtp:prepend(lazypath)

-- Cargar configuración core primero (opciones, keymaps base)
require("kvim.core")

-- Configurar lazy.nvim con la especificación de plugins
require("lazy").setup({
	spec = {
		-- Importar todos los módulos de plugins
		-- Cada módulo contiene la definición de uno o más plugins
		{ import = "kvim.plugins" },      -- Plugins principales
		{ import = "kvim.plugins.ai" },    -- Plugins de IA (opencode)
		{ import = "kvim.plugins.lsp" },   -- LSP y herramientas de lenguaje
		{ import = "kvim.plugins.lualine" }, -- Barra de estado
		{ import = "kvim.plugins.alpha" }, -- Dashboard
	},
    -- Por defecto, todos los plugins se cargan de forma perezosa (lazy loading)
    -- Esto mejora significativamente el tiempo de inicio de Neovim
    defaults = { lazy = true },
	
	-- Desactivado checker de actualizaciones para inicio más rápido
	-- Para verificar actualizaciones manualmente: Lazy sync
	checker = { enabled = false },
	
    -- No notificar cambios en archivos de configuración durante startup
    change_detection = { notify = false },
    
    -- Archivo de lock para garantizar versiones consistentes de plugins
    lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
})

-- Cargar utilidades y layouts al final del startup
-- Estos se cargan eagerly porque contienen funciones usadas frecuentemente
require("kvim.utils")
require("kvim.layouts")
