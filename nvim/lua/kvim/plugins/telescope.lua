-- Telescope.nvim: Buscador/buscador difuso para Neovim
-- Proporciona búsqueda de archivos, grep, buffers, LSP, etc.
return {
	{
		"nvim-telescope/telescope.nvim",
		lazy = true,  -- Carga perezosa para no ralentizar inicio
		cmd = "Telescope", -- Se carga cuando se ejecuta el comando Telescope
		dependencies = {
			"nvim-lua/plenary.nvim",                            -- Utils Lua comunes
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- Extensión FZF (requiere compilación)
			"nvim-tree/nvim-web-devicons",                       -- Iconos para resultados
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					mappings = {
						i = {
							-- Ctrl+k/j = Navegar hacia arriba/abajo en resultados
							["<C-k>"] = actions.move_selection_previous,
							["<C-j>"] = actions.move_selection_next,
							-- Ctrl+q = Enviar selección a quickfix list y abrirla
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						},
					},
				},
			})
		end,
	},
}
