return {
	"akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
        local bufferline = require('bufferline')
		bufferline.setup({
            options = {
                indicator = { icon = '|', style = 'icon' },
                separator_style = "slope",
                numbers = function(opts)
                    -- return string.format('%s·%s', opts.raise(opts.id), opts.lower(opts.ordinal))
                    -- return string.format('%s.)%s.)', opts.ordinal, opts.id)
                    -- return string.format('%s.%s', opts.lower(opts.id), opts.lower(opts.ordinal))
                    return string.format('%s|%s', opts.id, opts.raise(opts.ordinal))
                end,
                style_preset = {
                    -- bufferline.style_preset.no_italic,
                    -- bufferline.style_preset.no_bold,
                    -- bufferline.style_preset.minimal

                }
            }
        })
	end,
}
