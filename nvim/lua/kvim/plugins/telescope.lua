return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-tree/nvim-web-devicons",
			-- "nvim-telescope/telescope-file-browser.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					mappings = {
						i = {
							["<C-k>"] = actions.move_selection_previous,
							["<C-j>"] = actions.move_selection_next,
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						},
					},
				},
			})
			-- telescope.load_extension("file_browser");

			-- local keymap = vim.keymap -- for concienses
			-- vim.keymap.set('n', '<leader>ff','<cmd>Telescope find_files<CR>', { desc = 'Telescope find files' })
			-- vim.keymap.set('n', '<leader>fr','<cmd>Telescope oldfiles<CR>', { desc = 'Telescope live grep' })
			-- vim.keymap.set('n', '<leader>fs','<cmd>Telescope live_grep<CR>', { desc = 'Telescope buffers' })
			-- vim.keymap.set('n', '<leader>fc','<cmd>Telescope grep_string<CR>', { desc = 'Telescope help tags' })
			-- vim.keymap.set("n", "<space>fp", "<cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>")
		end,
	},
}
