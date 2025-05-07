-- General
vim.api.nvim_set_keymap('n', '<C-s>', ':w!<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-q>', ':q!<CR>', { noremap = true })

vim.api.nvim_set_keymap('n', '<ESC>', ':noh<CR>', { noremap = true })
vim.api.nvim_set_keymap('t', '<ESC>', '<C-\\><C-n>', { noremap = true, silent = true })
