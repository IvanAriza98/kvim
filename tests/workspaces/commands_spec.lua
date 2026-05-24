describe("kvim.modules.workspaces.commands", function()
    local commands

    before_each(function()
        package.loaded["kvim.modules.workspaces.actions"] = {
            save_current = { callback = function() end },
            load = { callback = function() end },
            list = { callback = function() end },
            delete = { callback = function() end },
            current = { callback = function() end },
        }

        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceSave")
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceLoad")
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceList")
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceDelete")
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceCurrent")

        package.loaded["kvim.modules.workspaces.commands"] = nil
        commands = require("kvim.modules.workspaces.commands")
    end)

    after_each(function()
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceSave")
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceLoad")
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceList")
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceDelete")
        pcall(vim.api.nvim_del_user_command, "KvimWorkspaceCurrent")

        package.loaded["kvim.modules.workspaces.commands"] = nil
        package.loaded["kvim.modules.workspaces.actions"] = nil
    end)

    it("registers workspace commands", function()
        commands.setup()
        local registered = vim.api.nvim_get_commands({})

        assert.is_not_nil(registered.KvimWorkspaceSave)
        assert.is_not_nil(registered.KvimWorkspaceLoad)
        assert.is_not_nil(registered.KvimWorkspaceList)
        assert.is_not_nil(registered.KvimWorkspaceDelete)
        assert.is_not_nil(registered.KvimWorkspaceCurrent)
    end)
end)
