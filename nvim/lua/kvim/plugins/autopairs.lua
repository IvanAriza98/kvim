-- Autopairs: Cierre automático de парackets, corchetes, etc.
-- Automáticamente cierra y balancea pares de caracteres
return {
	"windwp/nvim-autopairs",
	event = "InsertEnter", -- Solo se carga al entrar en modo Insert
	config = function()
		require("nvim-autopairs").setup({
			-- Desactiva autopairs en estos filetypes (TelescopePrompt = conflictos con fuzzy finder)
			disable_filetype = { "TelescopePrompt", "vim" },
		})
	end,
}
