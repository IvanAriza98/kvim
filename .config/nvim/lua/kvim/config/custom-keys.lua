-- General
vim.api.nvim_set_keymap("n", "<C-s>", ":w!<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-q>", ":q!<CR>", { noremap = true })

vim.api.nvim_set_keymap("n", "<ESC>", ":noh<CR>", { noremap = true })
vim.api.nvim_set_keymap("t", "<ESC>", "<C-\\><C-n>", { noremap = true, silent = true })

-- Open Terminal
vim.api.nvim_set_keymap("n", "<C-t>r", ":rightbelow vsplit | term<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-t>l", ":leftabove vsplit | term<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-t>u", ":leftabove split | term<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-t>d", ":botright split | term<CR>", { noremap = true, silent = true })
