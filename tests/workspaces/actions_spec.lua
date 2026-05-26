describe("kvim.modules.workspaces.actions", function()
    local actions
    local storage_calls
    local session_calls
    local current_workspace
    local saved_workspace

    before_each(function()
        storage_calls = { save = 0, load = 0 }
        session_calls = { save = 0, load = 0 }
        current_workspace = nil
        local tab_roles = {}

        package.loaded["kvim.modules.workspaces.storage"] = {
            save = function(workspace)
                storage_calls.save = storage_calls.save + 1
                saved_workspace = workspace
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
                    integrations = {
                        connections = true,
                    },
                }
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

        _G.__orig_buf_get_name = vim.api.nvim_buf_get_name
        vim.api.nvim_buf_get_name = function()
            return ""
        end

        _G.__orig_get_option_value = vim.api.nvim_get_option_value
        vim.api.nvim_get_option_value = function(name, opts)
            if name == "buftype" and opts and opts.buf then
                return ""
            end

            return _G.__orig_get_option_value(name, opts)
        end

        _G.__orig_buf_is_valid = vim.api.nvim_buf_is_valid
        vim.api.nvim_buf_is_valid = function()
            return true
        end

        package.loaded["kvim.modules.workspaces.actions"] = nil
        actions = require("kvim.modules.workspaces.actions")

        _G.__orig_list_bufs = vim.api.nvim_list_bufs
        vim.api.nvim_list_bufs = function()
            return {}
        end
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
        vim.api.nvim_buf_get_name = _G.__orig_buf_get_name
        vim.api.nvim_get_option_value = _G.__orig_get_option_value
        vim.api.nvim_buf_is_valid = _G.__orig_buf_is_valid
        _G.__orig_buf_get_name = nil
        _G.__orig_get_option_value = nil
        _G.__orig_buf_is_valid = nil
        vim.api.nvim_list_bufs = _G.__orig_list_bufs
        _G.__orig_list_bufs = nil

        package.loaded["kvim.modules.workspaces.actions"] = nil
        package.loaded["kvim.modules.workspaces.storage"] = nil
        package.loaded["kvim.modules.workspaces.state"] = nil
        package.loaded["kvim.modules.workspaces.config"] = nil
        package.loaded["resession"] = nil
    end)

    it("save_current calls storage and resession", function()
        actions.create.callback("demo")
        actions.save_current.callback("demo")
        assert.is_true(storage_calls.save >= 2)
        assert.is_true(session_calls.save >= 1)
    end)

    it("load calls storage and resession", function()
        actions.load.callback("demo")
        assert.are.same(1, storage_calls.load)
        assert.are.same(1, session_calls.load)
    end)

    it("current returns current workspace", function()
        actions.create.callback("demo")
        actions.save_current.callback("demo")
        local current = actions.current.callback()
        assert.are.same("demo", current.name)
    end)

    it("save_current captures terminal recipe with command", function()
        local terminal_buf = 99
        vim.api.nvim_get_option_value = function(name, opts)
            if name == "buftype" and opts and opts.buf == terminal_buf then
                return "terminal"
            end

            return ""
        end
        vim.api.nvim_buf_get_name = function(buf)
            if buf == terminal_buf then
                return "term:///tmp/project//999:ssh test@127.0.0.1"
            end

            return ""
        end

        vim.api.nvim_list_bufs = function()
            return { terminal_buf }
        end

        actions.create.callback("demo")
        actions.save_current.callback("demo")
        assert.is_table(saved_workspace.terminals)
        assert.are.same(1, #saved_workspace.terminals)
        assert.are.same("ssh", saved_workspace.terminals[1].type)
    end)

    it("save_current skips terminal without command", function()
        local terminal_buf = 98
        vim.api.nvim_get_option_value = function(name, opts)
            if name == "buftype" and opts and opts.buf == terminal_buf then
                return "terminal"
            end

            return ""
        end
        vim.api.nvim_buf_get_name = function(buf)
            if buf == terminal_buf then
                return "term:///tmp/project//999"
            end

            return ""
        end

        vim.api.nvim_list_bufs = function()
            return { terminal_buf }
        end

        actions.create.callback("demo")
        actions.save_current.callback("demo")
        assert.is_table(saved_workspace.terminals)
        assert.are.same(0, #saved_workspace.terminals)
    end)

    it("save_current fails when workspace is not active", function()
        local ok, err = actions.save_current.callback("demo")
        assert.is_nil(ok)
        assert.is_not_nil(err)
    end)

    it("next loads next workspace from current", function()
        actions.create.callback("a")
        actions.next.callback()
        assert.are.same(1, storage_calls.load)
        local current = actions.current.callback()
        assert.are.same("b", current.name)
    end)

    it("prev loads previous workspace from current", function()
        actions.create.callback("a")
        actions.prev.callback()
        assert.are.same(1, storage_calls.load)
        local current = actions.current.callback()
        assert.are.same("b", current.name)
    end)
end)
