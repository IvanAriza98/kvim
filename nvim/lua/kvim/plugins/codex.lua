-- Codex.nvim: Plugin de OpenAI Codex para Neovim
-- Integración con la CLI de Codex para asistencia de código IA
return {
	{
		"kkrampis/codex.nvim",
		lazy = true,
		cmd = { "Codex", "CodexToggle" },
		keys = {
			{
				"<leader>cc",
				"<cmd>CodexToggle<CR>",
				desc = "Toggle Codex popup or side-panel",
				mode = { "n", "t" },
			},
			{
				"<leader>ct",
				"<cmd>CodexToggle<CR>",
				desc = "Toggle Codex popup or side-panel",
				mode = { "n", "t" },
			},
		},
		opts = {},
	},
}
