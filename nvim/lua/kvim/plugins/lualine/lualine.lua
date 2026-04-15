-- Lualine: Barra de estado personalizada
-- Muestra información del buffer actual (modo, git, lsp, etc.)
return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- Iconos para la barra de estado
    lazy = true,                                       -- Carga perezosa
    event = { "VimEnter", "TabEnter" },               -- Se carga al entrar en Vim o cambiar de tab
    config = function()
        require('lualine').setup({
            options = { theme = 'tokyonight'},         -- Tema que coincide con el colorscheme
            sections = {
                lualine_x = {
                    'encoding',
                    'fileformat',
                    'filetype',
                },
            },
        })
    end,
}
