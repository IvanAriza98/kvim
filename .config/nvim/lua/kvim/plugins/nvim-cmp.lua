return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer", --source for text in buffer
		"hrsh7th/cmp-path", --source for file system paths
		"L3MON4D3/LuaSnip", --snippet engine
		"saadparwaiz1/cmp_luasnip", --for autocompletion
		"rafamadriz/friendly-snippets", -- usefull snippets
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
				expand = function(args)
					luasnip.lps_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<C-k>"] = cmp.mapping.select_prev_item(),
				["<C-j>"] = cmp.mapping.select_next_item(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = false }),
			}),
			sources = cmp.config.sources({
				{ name = "luasnip" },
				{ name = "buffer" },
				{ name = "path" },
			}),
		})
	end,
}
