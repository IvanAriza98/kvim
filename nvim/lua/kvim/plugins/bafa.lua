return {
    'mistweaverco/bafa.nvim',
    config = function()
	require('lazy').setup({
	    opts = {
		title = '',
		diagnostics = false,
	    }
	})
    end,
}

