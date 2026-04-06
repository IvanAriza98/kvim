-- Alpha: Pantalla de bienvenida/dashboard para Neovim
-- Muestra un dashboard inicial al abrir Neovim
return {
    "goolord/alpha-nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- Iconos para el dashboard
    lazy = true,                                        -- Carga perezosa para inicio rápido
    event = "VimEnter",                                 -- Se carga al iniciar Neovim
    config = function()
	    require("kvim.plugins.alpha.alpha-config")       -- Configuración personalizada del dashboard
    end,
}
