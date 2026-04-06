-- Bufferline: Barra de buffers con estilo
-- Muestra los buffers abiertos como pestañas en la parte superior
return {
	"akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons", -- Iconos para tipos de archivo
    lazy = true,                                  -- Carga perezosa
    event = "VeryLazy",                           -- Se carga después de iniciar (no bloquea startup)
	config = function()
        local bufferline = require('bufferline')
		bufferline.setup({
            options = {
                -- Indicador visual para el buffer activo
                indicator = { icon = '|', style = 'icon' },
                -- Estilo de los separadores entre buffers
                separator_style = "slope",
                -- Formato de números: muestra ID y número ordinal (ej: 1|3)
                numbers = function(opts)
                    return string.format('%s|%s', opts.id, opts.raise(opts.ordinal))
                end,
                -- Presets de estilo (descomentar para modificar)
                style_preset = {
                    -- bufferline.style_preset.no_italic,   -- Sin cursiva
                    -- bufferline.style_preset.no_bold,     -- Sin negrita
                    -- bufferline.style_preset.minimal      -- Estilo minimalista
                }
            }
        })
	end,
}
