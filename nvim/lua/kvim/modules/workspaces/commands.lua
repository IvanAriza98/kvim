local M = {}

function M.setup()
    local actions = require("kvim.modules.workspaces.actions")

    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceSave")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceLoad")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceList")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceDelete")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceCurrent")

    vim.api.nvim_create_user_command("KvimWorkspaceSave", function(params)
        actions.save_current.callback(params.args)
    end, {
        nargs = "?",
        desc = "Save current KVIM workspace",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceLoad", function(params)
        actions.load.callback(params.args)
    end, {
        nargs = 1,
        desc = "Load KVIM workspace",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceList", function()
        actions.list.callback()
    end, {
        nargs = 0,
        desc = "List KVIM workspaces",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceDelete", function(params)
        actions.delete.callback(params.args)
    end, {
        nargs = 1,
        desc = "Delete KVIM workspace",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceCurrent", function()
        actions.current.callback()
    end, {
        nargs = 0,
        desc = "Show current KVIM workspace",
    })
end

return M
