local M = {}

function M.setup()
    local actions = require("kvim.modules.workspaces.actions")

    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceSave")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceCreate")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceLoad")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceList")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceDelete")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceCurrent")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceNext")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspacePrev")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceTerminalAdd")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceTerminalList")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceTerminalRemove")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceTerminalRestore")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceTermHome")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceTabCode")
    pcall(vim.api.nvim_del_user_command, "KvimWorkspaceTabTerm")

    vim.api.nvim_create_user_command("KvimWorkspaceCreate", function(params)
        actions.create.callback(params.args)
    end, {
        nargs = 1,
        desc = "Create KVIM workspace with default tabs",
    })

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

    vim.api.nvim_create_user_command("KvimWorkspaceNext", function()
        actions.next.callback()
    end, {
        nargs = 0,
        desc = "Load next KVIM workspace",
    })

    vim.api.nvim_create_user_command("KvimWorkspacePrev", function()
        actions.prev.callback()
    end, {
        nargs = 0,
        desc = "Load previous KVIM workspace",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceTerminalAdd", function()
        local name = vim.fn.input("Terminal name: ")
        local recipe_type = vim.fn.input("Type (shell/ssh): ")
        local position = vim.fn.input("Position (bottom/right/left/top): ", "bottom")
        local auto_restore_input = vim.fn.input("Auto restore? (y/n): ", "y")

        local recipe = {
            name = name,
            type = recipe_type,
            position = position,
            auto_restore = auto_restore_input ~= "n",
        }

        if recipe_type == "ssh" then
            recipe.connection = vim.fn.input("Connection name (optional): ")
            recipe.command = vim.fn.input("SSH fallback command (optional): ")
        else
            recipe.command = vim.fn.input("Command: ")
            recipe.cwd = vim.fn.input("Cwd (optional): ")
        end

        local ok, err = actions.terminal_add.callback(recipe)
        if not ok then
            vim.notify("KVIM Workspaces: failed to add recipe: " .. tostring(err), vim.log.levels.ERROR)
        end
    end, {
        nargs = 0,
        desc = "Add workspace terminal recipe",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceTerminalList", function()
        actions.terminal_list.callback()
    end, {
        nargs = 0,
        desc = "List workspace terminal recipes",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceTerminalRemove", function(params)
        local ok, err = actions.terminal_remove.callback(params.args)
        if not ok then
            vim.notify("KVIM Workspaces: failed to remove recipe: " .. tostring(err), vim.log.levels.ERROR)
        end
    end, {
        nargs = 1,
        desc = "Remove workspace terminal recipe",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceTerminalRestore", function()
        actions.terminal_restore.callback()
    end, {
        nargs = 0,
        desc = "Restore workspace terminal recipes",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceTermHome", function()
        actions.goto_term_tab.callback()
    end, {
        nargs = 0,
        desc = "Open workspace term sessions home",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceTabCode", function()
        actions.goto_code_tab.callback()
    end, {
        nargs = 0,
        desc = "Go to workspace code tab",
    })

    vim.api.nvim_create_user_command("KvimWorkspaceTabTerm", function()
        actions.goto_term_tab.callback()
    end, {
        nargs = 0,
        desc = "Go to workspace term tab",
    })
end

return M
