-- Comment.nvim: Comentarios inteligentes
-- Atajos para comentar/descomentar código en múltiples lenguajes
return {
	{
		"numToStr/Comment.nvim",
		opts = {}, -- Configuración por defecto (soporta Treesitter)
		event = { "BufReadPost", "InsertEnter" }, -- Carga cuando se lee un buffer o entra en Insert
		config = function()
			require("Comment").setup() -- Inicializa el plugin
		end,
	},
}
