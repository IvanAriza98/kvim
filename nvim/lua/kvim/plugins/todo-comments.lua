-- todo-comments.nvim: Resalta y busca comentarios TODO, FIXME, etc.
return {
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = { "BufReadPost", "InsertEnter" },
		config = function()
			require("todo-comments").setup()
		end,
	},
}
