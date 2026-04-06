return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
    lazy = false,
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			modules = {},
			auto_install = false,
			ignore_install = {},
			ensure_installed = {
				"c",
				"lua",
				"vim",
				"vimdoc",
				"query",
				"python",
			},
			sync_install = false,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
