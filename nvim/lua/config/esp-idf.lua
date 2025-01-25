require("config.script-vars")

vim.api.nvim_set_keymap('n', '<C-p>', ':lua vim.g.esp_port = vim.fn.input("New Target Port: ")<CR>', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-ñ>', ':lua vin.g.build_path = vim.fn.input("Add build directory: ")<CR>', {noremap = true})


local function BuildProject()
    local file_path = vim.fn.expand('%:p')
    if not vim.g.build_path == "" then
	print("Error: 'build_path' not defined.")
	return
    end
    local cmd = 'term python ' .. vim.g.esp_script .. ' --path \"' .. vim.g.build_path .. '\"'
    vim.api.nvim_command('tabnew')
    vim.api.nvim_command(cmd)
end
