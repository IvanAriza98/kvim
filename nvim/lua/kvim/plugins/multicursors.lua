return {
	{
		"brenton-leighton/multiple-cursors.nvim",
		version = "*", -- Use the latest tagged version
		opts = {
			match_visible_only = true,
		}, -- This causes the plugin setup function to be called
		keys = {
            -- Most used shortcuts
			{ "<C-j>",      "<Cmd>MultipleCursorsAddDown<CR>",  mode = { "n", "x" },        desc = "Add cursor and move down" },
			{ "<C-Up>",     "<Cmd>MultipleCursorsAddUp<CR>",    mode = { "n", "i", "x" },   desc = "Add cursor and move up" },
			{ "<C-k>",      "<Cmd>MultipleCursorsAddUp<CR>",    mode = { "n", "x" },        desc = "Add cursor and move up" },
			{ "<C-Down>",   "<Cmd>MultipleCursorsAddDown<CR>",  mode = { "n", "i", "x" },   desc = "Add cursor and move down" },
            -- Unused shorcuts
			{ "<C-LeftMouse>", "<Cmd>MultipleCursorsMouseAddDelete<CR>", mode = { "n", "i" }, desc = "Add or remove cursor" },
		},
	},
}
