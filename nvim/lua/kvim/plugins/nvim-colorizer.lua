-- nvim-highlight-colors: Resalta colores en el código
-- Muestra preview visual de colores hex/rgb/hsl en el código fuente
return {
	"brenoprata10/nvim-highlight-colors",
    lazy = true,                               -- Carga perezosa
    event = { "BufReadPost", "FileType" },     -- Se carga al abrir archivo o detectar filetype
	config = function()
		require("nvim-highlight-colors").setup({}) -- Configuración por defecto
	end,
}
