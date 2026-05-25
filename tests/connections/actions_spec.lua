describe("kvim.modules.connections.actions", function()
    local actions
    local set_vars

    before_each(function()
        set_vars = {}

        package.loaded["kvim.modules.connections.ssh"] = {
            build_command = function()
                return "ssh test@127.0.0.1"
            end,
        }
        package.loaded["kvim.modules.connections.serial"] = {
            build_command = function()
                return "picocom /dev/ttyUSB0"
            end,
        }
        package.loaded["kvim.modules.connections.state"] = {
            set_active_connection = function() end,
        }
        package.loaded["kvim.modules.connections.config"] = {
            load = function() return {} end,
            filter_by_type = function() return {} end,
        }
        package.loaded["kvim.modules.connections.picker"] = {
            select = function() end,
        }
        package.loaded["kvim.modules.connections.ssh_keys"] = {}
        package.loaded["kvim.core.terminal"] = {
            open_command = function() end,
        }

        _G.__orig_notify = vim.notify
        vim.notify = function() end

        _G.__orig_executable = vim.fn.executable
        vim.fn.executable = function()
            return 1
        end

        _G.__orig_get_current_buf = vim.api.nvim_get_current_buf
        vim.api.nvim_get_current_buf = function()
            return 10
        end

        _G.__orig_buf_set_var = vim.api.nvim_buf_set_var
        vim.api.nvim_buf_set_var = function(_, name, value)
            set_vars[name] = value
        end

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        vim.fn.executable = _G.__orig_executable
        vim.api.nvim_get_current_buf = _G.__orig_get_current_buf
        vim.api.nvim_buf_set_var = _G.__orig_buf_set_var

        _G.__orig_notify = nil
        _G.__orig_executable = nil
        _G.__orig_get_current_buf = nil
        _G.__orig_buf_set_var = nil

        package.loaded["kvim.modules.connections.actions"] = nil
        package.loaded["kvim.modules.connections.ssh"] = nil
        package.loaded["kvim.modules.connections.serial"] = nil
        package.loaded["kvim.modules.connections.state"] = nil
        package.loaded["kvim.modules.connections.config"] = nil
        package.loaded["kvim.modules.connections.picker"] = nil
        package.loaded["kvim.modules.connections.ssh_keys"] = nil
        package.loaded["kvim.core.terminal"] = nil
    end)

    it("stores workspace recipe metadata when opening connection", function()
        actions.open_connection({
            name = "ssh-dev",
            type = "ssh",
            position = "right",
            host = "127.0.0.1",
            user = "test",
        })

        assert.are.same("ssh test@127.0.0.1", set_vars.kvim_workspace_recipe_command)
        assert.are.same("ssh", set_vars.kvim_workspace_recipe_type)
        assert.are.same("ssh-dev", set_vars.kvim_workspace_recipe_connection)
        assert.are.same("right", set_vars.kvim_workspace_recipe_position)
    end)
end)
