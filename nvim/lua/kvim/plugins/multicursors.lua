-- multiple-cursors.nvim: Edición con múltiples cursores
-- Permite editar en múltiples posiciones simultáneamente (como VSCode)
return {
	{
		"brenton-leighton/multiple-cursors.nvim",
		version = "*",
		lazy = true, -- Carga perezosa para inicio rápido
		opts = {
			match_visible_only = true, -- Solo coinciden cursores en texto visible
		},
		keys = {
			-- Ctrl+j = Añadir cursor debajo y moverse
			{ "<C-j>",      "<Cmd>MultipleCursorsAddDown<CR>",  mode = { "n", "x" },        desc = "Add cursor and move down" },
			-- Ctrl+Up = Añadir cursor arriba
			{ "<C-Up>",     "<Cmd>MultipleCursorsAddUp<CR>",    mode = { "n", "i", "x" },   desc = "Add cursor and move up" },
			-- Ctrl+k = Añadir cursor arriba (alternativa)
			{ "<C-k>",      "<Cmd>MultipleCursorsAddUp<CR>",    mode = { "n", "x" },        desc = "Add cursor and move up" },
			-- Ctrl+Down = Añadir cursor debajo
			{ "<C-Down>",   "<Cmd>MultipleCursorsAddDown<CR>",  mode = { "n", "i", "x" },   desc = "Add cursor and move down" },
			-- Ctrl+Click = Añadir/eliminar cursor con mouse
			{ "<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = { "n", "i" }, desc = "Add or remove cursor" },
		},
	},
}
