-- Autocompletado para Neovim (nvim-cmp)
-- Se carga al entrar en modo Insert para no ralentizar el inicio
return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer",           -- Fuente de autocompletado del buffer actual
		"hrsh7th/cmp-path",             -- Fuente de autocompletado de rutas de archivo
		"L3MON4D3/LuaSnip",             -- Motor de snippets
		"saadparwaiz1/cmp_luasnip",     -- Integración de LuaSnip con nvim-cmp
		"rafamadriz/friendly-snippets",  -- Colección de snippets predefinidos
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		-- require("luasnip.loaders.fron_vscode").lazy_load()
		cmp.setup({
			completion = {
				completeopt = "menu,menuone,preview,noselect",
			},
			snippet = {
				-- Expande snippets usando LuaSnip
				expand = function(args)
					luasnip.lps_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				-- Navegación por el menú de autocompletado
				["<C-k>"] = cmp.mapping.select_prev_item(), -- Item anterior
				["<C-j>"] = cmp.mapping.select_next_item(), -- Siguiente item
				["<C-b>"] = cmp.mapping.scroll_docs(-4),     -- Scroll hacia arriba en docs
				["<C-f>"] = cmp.mapping.scroll_docs(4),     -- Scroll hacia abajo en docs
				["<C-space>"] = cmp.mapping.complete(),     -- Forzar autocompletado
				["<C-e>"] = cmp.mapping.abort(),            -- Cancelar autocompletado
				["<CR>"] = cmp.mapping.confirm({ select = false }), -- Confirmar selección
			}),
			sources = cmp.config.sources({
				{ name = "luasnip" }, -- Snippets
				{ name = "buffer" },  -- Texto del buffer
				{ name = "path" },    -- Rutas de archivo
			}),
		})
	end,
}
