describe("kvim.modules.workspaces terminals", function()
    local actions
    local notifications
    local opened_commands
    local opened_connections

    before_each(function()
        notifications = {}
        opened_commands = {}
        opened_connections = {}

        package.loaded["kvim.modules.workspaces.storage"] = {
            save = function() return true end,
            load = function()
                return {
                    name = "demo",
                    root = "/tmp/project",
                    session = "demo",
                    version = 1,
                    connections = { active = nil },
                    terminals = {
                        { name = "shell-1", type = "shell", command = "echo hi", position = "bottom", auto_restore = true },
                    },
                    tasks = {},
                }
            end,
            list = function() return {} end,
            delete = function() return true end,
        }

        local current_workspace = nil
        local tab_roles = {}
        package.loaded["kvim.modules.workspaces.state"] = {
            set_current = function(workspace) current_workspace = workspace end,
            get_current = function() return current_workspace end,
            clear_current = function() current_workspace = nil end,
            set_tab_role = function(tabnr, role)
                tab_roles[tabnr] = role
            end,
            get_tab_role = function(tabnr)
                return tab_roles[tabnr]
            end,
            find_tab_by_role = function(role)
                for tabnr, tab_role in pairs(tab_roles) do
                    if tab_role == role then
                        return tabnr
                    end
                end

                return nil
            end,
            clear_tab_roles = function()
                tab_roles = {}
            end,
        }

        package.loaded["kvim.modules.workspaces.config"] = {
            get = function()
                return {
                    restore_terminals_on_load = true,
                    integrations = { connections = true },
                }
            end,
        }

        package.loaded["resession"] = {
            save = function() end,
            load = function() end,
        }

        package.loaded["kvim.core.terminal"] = {
            open_command = function(command)
                table.insert(opened_commands, command)
            end,
        }

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return {
                    { name = "ssh-dev", type = "ssh", host = "127.0.0.1", user = "test" },
                }
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = {
            open_connection = function(connection)
                table.insert(opened_connections, connection.name)
            end,
        }

        _G.__orig_notify = vim.notify
        vim.notify = function(msg)
            table.insert(notifications, msg)
        end

        _G.__orig_getcwd = vim.fn.getcwd
        vim.fn.getcwd = function() return "/tmp/project" end

        _G.__orig_isdirectory = vim.fn.isdirectory
        vim.fn.isdirectory = function() return 1 end

        _G.__orig_cmd = vim.cmd
        vim.cmd = function() end

        package.loaded["kvim.modules.workspaces.actions"] = nil
        actions = require("kvim.modules.workspaces.actions")
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        vim.fn.getcwd = _G.__orig_getcwd
        vim.fn.isdirectory = _G.__orig_isdirectory
        vim.cmd = _G.__orig_cmd
        _G.__orig_notify = nil
        _G.__orig_getcwd = nil
        _G.__orig_isdirectory = nil
        _G.__orig_cmd = nil

        package.loaded["kvim.modules.workspaces.actions"] = nil
        package.loaded["kvim.modules.workspaces.storage"] = nil
        package.loaded["kvim.modules.workspaces.state"] = nil
        package.loaded["kvim.modules.workspaces.config"] = nil
        package.loaded["resession"] = nil
        package.loaded["kvim.core.terminal"] = nil
        package.loaded["kvim.modules.connections.config"] = nil
        package.loaded["kvim.modules.connections.actions"] = nil
    end)

    it("restores shell terminal recipes on workspace load", function()
        actions.load.callback("demo")
        assert.are.same(1, #opened_commands)
    end)

    it("restores ssh recipe via connections integration", function()
        actions.create.callback("demo")
        actions.save_current.callback("demo")
        local recipe = {
            name = "ssh-term",
            type = "ssh",
            connection = "ssh-dev",
            auto_restore = true,
        }

        actions.terminal_add.callback(recipe)
        actions.terminal_restore.callback()
        assert.are.same(1, #opened_connections)
    end)

    it("uses fallback command when ssh connection is not found", function()
        actions.create.callback("demo")
        actions.save_current.callback("demo")
        actions.terminal_add.callback({
            name = "ssh-fallback",
            type = "ssh",
            connection = "missing",
            command = "ssh user@host",
            auto_restore = true,
        })

        actions.terminal_restore.callback()
        assert.is_true(#opened_commands >= 1)
    end)
end)
