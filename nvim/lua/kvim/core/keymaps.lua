local noremap = { noremap = true }
local noremap_silent = { noremap = true, silent = true }

-- General
vim.api.nvim_set_keymap("n", "s", ":w!<CR>", noremap)
vim.api.nvim_set_keymap("n", "qq", ":q!<CR>", noremap) -- Cerrar un buffer/ventana
vim.api.nvim_set_keymap("n", "qe", ":qa!<CR>", noremap) -- Salir del programa (se cierra todo)

vim.api.nvim_set_keymap("n", "<ESC>", ":noh<CR>", noremap)
vim.api.nvim_set_keymap("t", "<C-x>", "<C-\\><C-n>", noremap_silent)    -- Usar ctrl+x para salir cuando estamos dentro de una terminal en una nueva ventana
-- vim.api.nvim_set_keymap("t", "<ESC>", "<C-\\><C-n>", noremap_silent)

-- Open Terminal
vim.api.nvim_set_keymap("n", "<C-t>l", ":rightbelow vsplit | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>h", ":leftabove vsplit | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>k", ":leftabove split | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>j", ":botright split | term<CR>", noremap_silent)
