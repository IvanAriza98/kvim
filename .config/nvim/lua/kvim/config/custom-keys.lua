local noremap = { noremap = true }
local noremap_silent = { noremap = true, silent = true }
-- General
vim.api.nvim_set_keymap("n", "<C-s>", ":w!<CR>", noremap)
vim.api.nvim_set_keymap("n", "<C-q>", ":q!<CR>", noremap)

vim.api.nvim_set_keymap("n", "<ESC>", ":noh<CR>", noremap)
vim.api.nvim_set_keymap("t", "<ESC>", "<C-\\><C-n>", noremap_silent)

-- Open Terminal
vim.api.nvim_set_keymap("n", "<C-t>r", ":rightbelow vsplit | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>l", ":leftabove vsplit | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>u", ":leftabove split | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>d", ":botright split | term<CR>", noremap_silent)
