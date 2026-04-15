-- Autocmds core
-- Nota: La gestión de tabs Code/SSH vive en `kvim.workspace`.

-- Comando personalizado para crear nuevos tabs con nombre "Tab"
vim.api.nvim_create_user_command("TabNew", function()
    vim.cmd("tabnew")
    local tab = vim.api.nvim_get_current_tabpage()
    vim.api.nvim_tabpage_set_var(tab, "title", "Tab")
end, { desc = "Create a new named tab" })
