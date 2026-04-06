-- toggleterm.nvim: Terminal embebido en Neovim
-- Permite abrir/cerrar terminales como ventanas flotantes o paneles
return {
    "akinsho/toggleterm.nvim",
    lazy = true,                               -- Carga perezosa
    cmd = { "ToggleTerm", "TermExec" },        -- Se carga con estos comandos
    config = function()
	    require("toggleterm").setup()           -- Configuración por defecto
    end
}
