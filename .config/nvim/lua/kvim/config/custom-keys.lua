local noremap = { noremap = true }
local noremap_silent = { noremap = true, silent = true }
-- General
vim.api.nvim_set_keymap("n", "<C-s>", ":w!<CR>", noremap)
vim.api.nvim_set_keymap("n", "<C-q>", ":q!<CR>", noremap)

vim.api.nvim_set_keymap("n", "<ESC>", ":noh<CR>", noremap)
vim.api.nvim_set_keymap("t", "<ESC>", "<C-\\><C-n>", noremap_silent)

-- Open Terminal
vim.api.nvim_set_keymap("n", "<C-t>l", ":rightbelow vsplit | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>h", ":leftabove vsplit | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>k", ":leftabove split | term<CR>", noremap_silent)
vim.api.nvim_set_keymap("n", "<C-t>j", ":botright split | term<CR>", noremap_silent)
