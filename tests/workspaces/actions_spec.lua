describe("kvim.modules.workspaces.actions", function()
    local actions
    local storage_calls
    local session_calls
    local current_workspace
    local saved_workspace
    local created_buffers
    local buffer_lines
    local win_buffers
    local tabpages
    local buffer_vars
    local window_options
    local keymaps
    local buffer_options

    before_each(function()
        storage_calls = { save = 0, load = 0 }
        session_calls = { save = 0, load = 0 }
        current_workspace = nil
        created_buffers = {}
        buffer_lines = {}
        win_buffers = {}
        tabpages = { 1, 2 }
        buffer_vars = {}
        window_options = {
            number = true,
            relativenumber = true,
            cursorline = true,
            signcolumn = "yes",
            foldcolumn = "1",
        }
        keymaps = {}
        buffer_options = {}
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

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return {
                    { name = "ssh-dev", type = "ssh", host = "127.0.0.1", user = "test", port = 2222 },
                }
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = {
            reconnect_connection = function()
                return nil, "terminal buffer not found: ssh-dev"
            end,
            open_connection = function() end,
        }

        package.loaded["kvim.modules.connections.state"] = {
            get_connection_buffer = function()
                return nil
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

        _G.__orig_wo = vim.wo
        vim.wo = window_options

        _G.__orig_sockconnect = vim.fn.sockconnect
        vim.fn.sockconnect = function()
            return 1
        end

        _G.__orig_chanclose = vim.fn.chanclose
        vim.fn.chanclose = function() end

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

        _G.__orig_create_buf = vim.api.nvim_create_buf
        vim.api.nvim_create_buf = function()
            local bufnr = 200 + #created_buffers + 1
            table.insert(created_buffers, bufnr)
            return bufnr
        end

        _G.__orig_get_current_win = vim.api.nvim_get_current_win
        vim.api.nvim_get_current_win = function()
            return 1
        end

        _G.__orig_win_set_buf = vim.api.nvim_win_set_buf
        vim.api.nvim_win_set_buf = function(winid, bufnr)
            win_buffers[winid] = bufnr
        end

        _G.__orig_win_get_width = vim.api.nvim_win_get_width
        vim.api.nvim_win_get_width = function()
            return 80
        end

        _G.__orig_win_get_height = vim.api.nvim_win_get_height
        vim.api.nvim_win_get_height = function()
            return 24
        end

        _G.__orig_set_option_value = vim.api.nvim_set_option_value
        vim.api.nvim_set_option_value = function(name, value, opts)
            if opts and opts.buf then
                buffer_options[opts.buf] = buffer_options[opts.buf] or {}
                buffer_options[opts.buf][name] = value
            end
        end

        _G.__orig_buf_set_lines = vim.api.nvim_buf_set_lines
        vim.api.nvim_buf_set_lines = function(bufnr, _, _, _, lines)
            buffer_lines[bufnr] = lines
        end

        _G.__orig_buf_set_var = vim.api.nvim_buf_set_var
        vim.api.nvim_buf_set_var = function(bufnr, name, value)
            buffer_vars[bufnr] = buffer_vars[bufnr] or {}
            buffer_vars[bufnr][name] = value
        end

        _G.__orig_buf_get_var = vim.api.nvim_buf_get_var
        vim.api.nvim_buf_get_var = function(bufnr, name)
            if buffer_vars[bufnr] and buffer_vars[bufnr][name] ~= nil then
                return buffer_vars[bufnr][name]
            end

            error("missing buffer var: " .. tostring(name))
        end

        _G.__orig_buf_set_name = vim.api.nvim_buf_set_name
        vim.api.nvim_buf_set_name = function() end

        _G.__orig_keymap_set = vim.keymap.set
        vim.keymap.set = function(mode, lhs, rhs, opts)
            table.insert(keymaps, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
        end

        _G.__orig_tabpage_list_wins = vim.api.nvim_tabpage_list_wins
        vim.api.nvim_tabpage_list_wins = function(tabnr)
            if tabnr ~= 1 and tabnr ~= 2 then
                error("Invalid tabpage id: " .. tostring(tabnr))
            end
            return { 1 }
        end

        _G.__orig_list_tabpages = vim.api.nvim_list_tabpages
        vim.api.nvim_list_tabpages = function()
            local pages = {}
            for _, tabnr in ipairs(tabpages) do
                table.insert(pages, tabnr)
            end
            return pages
        end

        _G.__orig_tabpage_get_number = vim.api.nvim_tabpage_get_number
        vim.api.nvim_tabpage_get_number = function(tabpage)
            return tabpage
        end

        _G.__orig_win_get_buf = vim.api.nvim_win_get_buf
        vim.api.nvim_win_get_buf = function(winid)
            return win_buffers[winid] or 1
        end

        package.loaded["kvim.modules.workspaces.actions"] = nil
        actions = require("kvim.modules.workspaces.actions")

        _G.__orig_list_bufs = vim.api.nvim_list_bufs
        vim.api.nvim_list_bufs = function()
            local buffers = {}
            for _, bufnr in ipairs(created_buffers) do
                table.insert(buffers, bufnr)
            end
            return buffers
        end
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        vim.wo = _G.__orig_wo
        vim.fn.sockconnect = _G.__orig_sockconnect
        vim.fn.chanclose = _G.__orig_chanclose
        vim.fn.getcwd = _G.__orig_getcwd
        vim.fn.isdirectory = _G.__orig_isdirectory
        vim.cmd = _G.__orig_cmd

        _G.__orig_notify = nil
        _G.__orig_wo = nil
        _G.__orig_sockconnect = nil
        _G.__orig_chanclose = nil
        _G.__orig_getcwd = nil
        _G.__orig_isdirectory = nil
        _G.__orig_cmd = nil
        vim.api.nvim_buf_get_name = _G.__orig_buf_get_name
        vim.api.nvim_get_option_value = _G.__orig_get_option_value
        vim.api.nvim_buf_is_valid = _G.__orig_buf_is_valid
        vim.api.nvim_create_buf = _G.__orig_create_buf
        vim.api.nvim_get_current_win = _G.__orig_get_current_win
        vim.api.nvim_win_set_buf = _G.__orig_win_set_buf
        vim.api.nvim_win_get_width = _G.__orig_win_get_width
        vim.api.nvim_win_get_height = _G.__orig_win_get_height
        vim.api.nvim_set_option_value = _G.__orig_set_option_value
        vim.api.nvim_buf_set_lines = _G.__orig_buf_set_lines
        vim.api.nvim_buf_set_var = _G.__orig_buf_set_var
        vim.api.nvim_buf_get_var = _G.__orig_buf_get_var
        vim.api.nvim_buf_set_name = _G.__orig_buf_set_name
        vim.keymap.set = _G.__orig_keymap_set
        vim.api.nvim_tabpage_list_wins = _G.__orig_tabpage_list_wins
        vim.api.nvim_list_tabpages = _G.__orig_list_tabpages
        vim.api.nvim_tabpage_get_number = _G.__orig_tabpage_get_number
        vim.api.nvim_win_get_buf = _G.__orig_win_get_buf
        _G.__orig_buf_get_name = nil
        _G.__orig_get_option_value = nil
        _G.__orig_buf_is_valid = nil
        _G.__orig_create_buf = nil
        _G.__orig_get_current_win = nil
        _G.__orig_win_set_buf = nil
        _G.__orig_win_get_width = nil
        _G.__orig_win_get_height = nil
        _G.__orig_set_option_value = nil
        _G.__orig_buf_set_lines = nil
        _G.__orig_buf_set_var = nil
        _G.__orig_buf_get_var = nil
        _G.__orig_buf_set_name = nil
        _G.__orig_keymap_set = nil
        _G.__orig_tabpage_list_wins = nil
        _G.__orig_list_tabpages = nil
        _G.__orig_tabpage_get_number = nil
        _G.__orig_win_get_buf = nil
        vim.api.nvim_list_bufs = _G.__orig_list_bufs
        _G.__orig_list_bufs = nil

        package.loaded["kvim.modules.workspaces.actions"] = nil
        package.loaded["kvim.modules.workspaces.storage"] = nil
        package.loaded["kvim.modules.workspaces.state"] = nil
        package.loaded["kvim.modules.workspaces.config"] = nil
        package.loaded["resession"] = nil
        package.loaded["kvim.modules.connections.config"] = nil
        package.loaded["kvim.modules.connections.actions"] = nil
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

    it("goto_term_tab opens centered placeholder when no terminals exist", function()
        actions.create.callback("demo")
        local ok = actions.goto_term_tab.callback()

        assert.is_true(ok)
        assert.are.same(1, #created_buffers)
        assert.is_not_nil(buffer_lines[created_buffers[1]])
        local text = table.concat(buffer_lines[created_buffers[1]], "\n")
        assert.matches("KVIM Term", text)
        assert.matches("No hay terminales activas", text)
        assert.is_false(window_options.number)
        assert.is_false(window_options.relativenumber)
        assert.are.same("kvim-term", buffer_options[created_buffers[1]].filetype)
        assert.are.same("", window_options.colorcolumn)
    end)

    it("goto_term_tab prunes stale term tab role and does not fail", function()
        actions.create.callback("demo")
        tabpages = { 1 }

        local ok = actions.goto_term_tab.callback()

        assert.is_true(ok)
    end)

    it("goto_term_tab reuses existing placeholder buffer", function()
        actions.create.callback("demo")

        local ok_first = actions.goto_term_tab.callback()
        local created_first = #created_buffers
        local placeholder_buf = created_buffers[1]

        local ok_second = actions.goto_term_tab.callback()

        assert.is_true(ok_first)
        assert.is_true(ok_second)
        assert.are.same(created_first, #created_buffers)
        assert.are.same(placeholder_buf, win_buffers[1])
    end)

    it("goto_term_tab opens ssh sessions view for workspace recipes", function()
        actions.create.callback("demo")
        actions.terminal_add.callback({
            name = "ssh-term",
            type = "ssh",
            connection = "ssh-dev",
            auto_restore = true,
        })

        local ok = actions.goto_term_tab.callback()

        assert.is_true(ok)
        assert.are.same(1, #created_buffers)
        local text = table.concat(buffer_lines[created_buffers[1]], "\n")
        assert.matches("Sesiones SSH del workspace", text)
        assert.matches("ssh%-dev", text)
        assert.matches("test@127%.0%.0%.1:2222", text)
        assert.are.same("kvim-term-sessions", buffer_options[created_buffers[1]].filetype)
        assert.are.same("", window_options.colorcolumn)
    end)

    it("goto_term_tab shows opened indicator for active connection buffer", function()
        package.loaded["kvim.modules.connections.state"] = {
            get_connection_buffer = function(name)
                if name == "ssh-dev" then
                    return 77
                end
                return nil
            end,
        }

        vim.api.nvim_get_option_value = function(name, opts)
            if name == "buftype" and opts and opts.buf == 77 then
                return "terminal"
            end

            return ""
        end

        package.loaded["kvim.modules.workspaces.actions"] = nil
        actions = require("kvim.modules.workspaces.actions")

        actions.create.callback("demo")
        actions.terminal_add.callback({
            name = "ssh-term",
            type = "ssh",
            connection = "ssh-dev",
            auto_restore = true,
        })

        local ok = actions.goto_term_tab.callback()

        assert.is_true(ok)
        local text = table.concat(buffer_lines[created_buffers[1]], "\n")
        assert.matches("󰐃", text)
    end)

    it("goto_term_tab keeps active terminal visible instead of replacing it with sessions view", function()
        actions.create.callback("demo")
        actions.terminal_add.callback({
            name = "ssh-term",
            type = "ssh",
            connection = "ssh-dev",
            auto_restore = true,
        })

        vim.api.nvim_get_option_value = function(name, opts)
            if name == "buftype" and opts and opts.buf == 1 then
                return "terminal"
            end

            return ""
        end

        local ok = actions.goto_term_tab.callback()

        assert.is_true(ok)
        assert.are.same(0, #created_buffers)
    end)
end)
