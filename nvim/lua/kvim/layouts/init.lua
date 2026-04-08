-- =============================================================================
-- Layouts: UI Component System
-- =============================================================================
-- Este módulo carga los componentes de UI para el sistema de menús.
-- Usa nvzone/menu para interfaces modernas con soporte de submenús.
--
-- El menú principal se abre con <leader>space o <leader>k

-- Cargar el keymap del menú principal
vim.keymap.set("n", "<leader><space>", function()
    require("kvim.layouts.menu").open_main_menu()
end, { noremap = true, silent = true, desc = "Open KVIM Config Menu" })

vim.keymap.set("n", "<leader>k", function()
    require("kvim.layouts.menu").open_main_menu()
end, { noremap = true, silent = true, desc = "Open KVIM Config Menu" })
