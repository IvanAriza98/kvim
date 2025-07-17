return {
	"github/copilot.vim",
	lazy = false, -- para que se cargue en el arranque
	config = function()
		vim.g.copilot_no_tab_map = true -- evita que <Tab> se use por defecto
		vim.api.nvim_set_keymap("i", "<C-l>", 'copilot#Accept("<CR>")', { silent = true, expr = true, noremap = true })
	end,
}
