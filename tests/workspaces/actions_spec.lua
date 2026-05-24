describe("kvim.modules.workspaces.actions", function()
    local actions
    local storage_calls
    local session_calls
    local current_workspace

    before_each(function()
        storage_calls = { save = 0, load = 0 }
        session_calls = { save = 0, load = 0 }
        current_workspace = nil

        package.loaded["kvim.modules.workspaces.storage"] = {
            save = function(workspace)
                storage_calls.save = storage_calls.save + 1
                return true
            end,
            load = function(name)
                storage_calls.load = storage_calls.load + 1
                return {
                    name = name,
                    root = "/tmp/project",
                    session = name,
                    version = 1,
                    connections = { active = nil },
                    terminals = {},
                    tasks = {},
                }
            end,
            list = function()
                return { "a", "b" }
            end,
            delete = function()
                return true
            end,
        }

        package.loaded["kvim.modules.workspaces.state"] = {
            set_current = function(workspace)
                current_workspace = workspace
            end,
            get_current = function()
                return current_workspace
            end,
            clear_current = function()
                current_workspace = nil
            end,
        }

        package.loaded["resession"] = {
            save = function()
                session_calls.save = session_calls.save + 1
            end,
            load = function()
                session_calls.load = session_calls.load + 1
            end,
        }

        _G.__orig_notify = vim.notify
        vim.notify = function() end

        _G.__orig_getcwd = vim.fn.getcwd
        vim.fn.getcwd = function()
            return "/tmp/project"
        end

        _G.__orig_isdirectory = vim.fn.isdirectory
        vim.fn.isdirectory = function()
            return 1
        end

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
        package.loaded["resession"] = nil
    end)

    it("save_current calls storage and resession", function()
        actions.save_current.callback("demo")
        assert.are.same(1, storage_calls.save)
        assert.are.same(1, session_calls.save)
    end)

    it("load calls storage and resession", function()
        actions.load.callback("demo")
        assert.are.same(1, storage_calls.load)
        assert.are.same(1, session_calls.load)
    end)

    it("current returns current workspace", function()
        actions.save_current.callback("demo")
        local current = actions.current.callback()
        assert.are.same("demo", current.name)
    end)
end)
