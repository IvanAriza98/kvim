return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" }, -- cargar solo antes de guardar
	config = function()
		require("conform").setup({
			-- Formatear al guardar automáticamente
			format_on_save = {
				lsp_fallback = true,
				timeout_ms = 1000,
			},

			-- Formateadores por tipo de archivo
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "black" },
				sh = { "shfmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				json = { "jq" },
				yaml = { "yamlfmt" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
			},
		})
	end,
}
