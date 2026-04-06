return {
	"folke/tokyonight.nvim",
	lazy = false,
	config = function()
		require("tokyonight").setup({
			style = "storm", -- Cambia el estilo aquí (storm, moon, night, day)
			transparent = false, -- Desactiva el color de fondo
			terminal_colors = true, -- Colores personalizados para el terminal
			styles = {
				comments = { italic = true }, -- Comentarios en cursiva
				keywords = { italic = false }, -- Palabras clave en cursiva
				functions = { italic = false }, -- Funciones en negrita y cursiva
				variables = { italic = false }, -- Variables en negrita
			},
			sidebars = "dark", -- Estilo de los sidebars
			floats = "dark", -- Estilo de las ventanas flotantes
			on_colors = function(colors)
				-- Modifica colores específicos si es necesario
				colors.hint = colors.orange
				colors.error = "#ff0000"
			end,
			on_highlights = function(highlights, colors)
				-- Modifica grupos de resaltado
				highlights.Function = { fg = colors.blue, bold = false, italic = true }
				highlights.Identifier = { fg = colors.magenta, bold = true, italic = false }
			end,
		})
		vim.cmd([[colorscheme tokyonight]])
	end,
}
