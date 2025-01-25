return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()

      require("telescope").setup {
	      extensions = {
		      file_browser = {
			      theme = 'ivy',
			      hijack_netrw=true,
		      },
	      },
      }
      require("telescope").load_extension "file_browser"
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<space>ff', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<space>fg', builtin.live_grep, { desc = 'Telescope live grep' })
      vim.keymap.set('n', '<space>fb', builtin.buffers, { desc = 'Telescope buffers' })
      vim.keymap.set('n', '<space>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    end,
  },
  {
    'nvim-telescope/telescope-file-browser.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    config = function()
        vim.keymap.set("n", "<space>f", ":Telescope file_browser<CR>")
	-- open file_browser with the path of the current buffer
	vim.keymap.set("n", "<space>fp", ":Telescope file_browser path=%:p:h select_buffer=true<CR>")
    end,
  },
}
