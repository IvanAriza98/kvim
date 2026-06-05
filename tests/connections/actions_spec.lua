describe("kvim.modules.connections.actions", function()
    local actions
    local set_vars
    local written_file
    local install_key_calls
    local ensured_key_calls
    local notifications
    local connection_buffers
    local opened_terminal_commands
    local focused_win
    local focused_buf
    local current_bufnr
    local deleted_buffers
    local buffer_options
    local input_responses
    local saved_workspaces
    local workspace_names
    local workspace_store

    before_each(function()
        set_vars = {}
        written_file = nil
        install_key_calls = {}
        ensured_key_calls = {}
        notifications = {}
        connection_buffers = {}
        opened_terminal_commands = {}
        focused_win = nil
        focused_buf = nil
        current_bufnr = 10
        deleted_buffers = {}
        input_responses = {}
        saved_workspaces = {}
        workspace_names = {}
        workspace_store = {}
        buffer_options = setmetatable({}, {
            __index = function(_, bufnr)
                local value = { buflisted = true, bufhidden = "" }
                rawset(buffer_options, bufnr, value)
                return value
            end,
        })

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
            get_active_connection = function()
                return nil
            end,
            clear_active_connection = function() end,
            set_connection_buffer = function(name, bufnr)
                connection_buffers[name] = bufnr
            end,
            get_connection_buffer = function(name)
                return connection_buffers[name]
            end,
            clear_connection_buffer = function(name)
                connection_buffers[name] = nil
            end,
        }
        package.loaded["kvim.modules.connections.config"] = {
            load = function() return {} end,
            filter_by_type = function() return {} end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }
        package.loaded["kvim.modules.connections.picker"] = {
            select = function() end,
        }
        package.loaded["kvim.modules.connections.ssh_keys"] = {
            install_key = function(conn)
                table.insert(install_key_calls, conn)
            end,
            ensure_local_key_for_connection = function(conn)
                table.insert(ensured_key_calls, conn)
                return true, "existing"
            end,
            key_path_for_connection = function(conn)
                return "/home/test/.ssh/kvim_" .. tostring(conn.name or "connection") .. "_ed25519"
            end,
        }
        package.loaded["kvim.core.terminal"] = {
            open_command = function(command, opts)
                table.insert(opened_terminal_commands, {
                    command = command,
                    opts = opts,
                })
                current_bufnr = current_bufnr + 1
            end,
        }

        _G.__orig_notify = vim.notify
        vim.notify = function(message, level)
            table.insert(notifications, {
                message = message,
                level = level,
            })
        end

        _G.__orig_executable = vim.fn.executable
        vim.fn.executable = function()
            return 1
        end

        _G.__orig_ui_select = vim.ui.select

        _G.__orig_input = vim.fn.input
        vim.fn.input = function()
            return table.remove(input_responses, 1) or ""
        end

        _G.__orig_filereadable = vim.fn.filereadable
        vim.fn.filereadable = function()
            return 0
        end

        _G.__orig_dofile = _G.dofile

        _G.__orig_bo = vim.bo
        vim.bo = buffer_options

        _G.__orig_get_current_buf = vim.api.nvim_get_current_buf
        vim.api.nvim_get_current_buf = function()
            return current_bufnr
        end

        _G.__orig_buf_set_var = vim.api.nvim_buf_set_var
        vim.api.nvim_buf_set_var = function(_, name, value)
            set_vars[name] = value
        end

        _G.__orig_buf_get_var = vim.api.nvim_buf_get_var
        vim.api.nvim_buf_get_var = function(_, name)
            error("missing buffer var: " .. tostring(name))
        end

        _G.__orig_buf_is_valid = vim.api.nvim_buf_is_valid
        vim.api.nvim_buf_is_valid = function()
            return true
        end

        _G.__orig_get_option_value = vim.api.nvim_get_option_value
        vim.api.nvim_get_option_value = function(name, opts)
            if name == "buftype" and opts and opts.buf then
                return "terminal"
            end

            return _G.__orig_get_option_value(name, opts)
        end

        _G.__orig_win_findbuf = vim.fn.win_findbuf
        vim.fn.win_findbuf = function()
            return { 7 }
        end

        _G.__orig_set_current_win = vim.api.nvim_set_current_win
        vim.api.nvim_set_current_win = function(winid)
            focused_win = winid
        end

        _G.__orig_set_current_buf = vim.api.nvim_set_current_buf
        vim.api.nvim_set_current_buf = function(bufnr)
            focused_buf = bufnr
        end

        _G.__orig_buf_delete = vim.api.nvim_buf_delete
        vim.api.nvim_buf_delete = function(bufnr)
            table.insert(deleted_buffers, bufnr)
        end

        _G.__orig_mkdir = vim.fn.mkdir
        vim.fn.mkdir = function()
            return 1
        end

        _G.__orig_writefile = vim.fn.writefile
        vim.fn.writefile = function(lines, file)
            written_file = {
                lines = lines,
                file = file,
            }
            return 0
        end

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        vim.fn.executable = _G.__orig_executable
        vim.fn.input = _G.__orig_input
        vim.fn.filereadable = _G.__orig_filereadable
        _G.dofile = _G.__orig_dofile
        vim.ui.select = _G.__orig_ui_select
        vim.bo = _G.__orig_bo
        vim.api.nvim_get_current_buf = _G.__orig_get_current_buf
        vim.api.nvim_buf_set_var = _G.__orig_buf_set_var
        vim.api.nvim_buf_get_var = _G.__orig_buf_get_var
        vim.api.nvim_buf_is_valid = _G.__orig_buf_is_valid
        vim.api.nvim_get_option_value = _G.__orig_get_option_value
        vim.fn.mkdir = _G.__orig_mkdir
        vim.fn.writefile = _G.__orig_writefile
        vim.fn.win_findbuf = _G.__orig_win_findbuf
        vim.api.nvim_set_current_win = _G.__orig_set_current_win
        vim.api.nvim_set_current_buf = _G.__orig_set_current_buf
        vim.api.nvim_buf_delete = _G.__orig_buf_delete

        _G.__orig_notify = nil
        _G.__orig_executable = nil
        _G.__orig_input = nil
        _G.__orig_filereadable = nil
        _G.__orig_dofile = nil
        _G.__orig_ui_select = nil
        _G.__orig_bo = nil
        _G.__orig_get_current_buf = nil
        _G.__orig_buf_set_var = nil
        _G.__orig_buf_get_var = nil
        _G.__orig_buf_is_valid = nil
        _G.__orig_get_option_value = nil
        _G.__orig_mkdir = nil
        _G.__orig_writefile = nil
        _G.__orig_win_findbuf = nil
        _G.__orig_set_current_win = nil
        _G.__orig_set_current_buf = nil
        _G.__orig_buf_delete = nil

        package.loaded["kvim.modules.connections.actions"] = nil
        package.loaded["kvim.modules.connections.ssh"] = nil
        package.loaded["kvim.modules.connections.serial"] = nil
        package.loaded["kvim.modules.connections.state"] = nil
        package.loaded["kvim.modules.connections.config"] = nil
        package.loaded["kvim.modules.connections.picker"] = nil
        package.loaded["kvim.modules.connections.ssh_keys"] = nil
        package.loaded["kvim.core.terminal"] = nil
        package.loaded["kvim.modules.workspaces.state"] = nil
        package.loaded["kvim.modules.workspaces.storage"] = nil
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
        assert.are.same(true, set_vars.kvim_connection_managed)
        assert.are.same("ssh-dev", set_vars.kvim_connection_name)
        assert.are.same("ssh", set_vars.kvim_connection_type)
        assert.are.equal(11, connection_buffers["ssh-dev"])
    end)

    it("reconnects ssh connection in existing terminal buffer", function()
        local all_connections = {
            {
                type = "ssh",
                name = "docker-test-1",
                host = "127.0.0.1",
                user = "test",
            },
        }

        connection_buffers["docker-test-1"] = 10

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return all_connections
            end,
            filter_by_type = function()
                return {}
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        local ok = actions.reconnect_connection({}, "docker-test-1")

        assert.is_true(ok)
        assert.are.equal(1, #opened_terminal_commands)
        assert.are.equal("ssh test@127.0.0.1", opened_terminal_commands[1].command)
        assert.is_false(opened_terminal_commands[1].opts.split)
        assert.are.equal(7, focused_win)
        assert.are.equal(11, connection_buffers["docker-test-1"])
        assert.is_false(buffer_options[10].buflisted)
    end)

    it("reconnect errors when connection name is missing", function()
        local ok, err = actions.reconnect_connection({}, "")

        assert.is_nil(ok)
        assert.are.equal("connection name is required", err)
    end)

    it("reconnect errors when connection is not found", function()
        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return {}
            end,
            filter_by_type = function()
                return {}
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        local ok, err = actions.reconnect_connection({}, "missing")

        assert.is_nil(ok)
        assert.are.equal("connection not found: missing", err)
    end)

    it("reconnect errors when associated buffer is invalid", function()
        local all_connections = {
            {
                type = "ssh",
                name = "docker-test-1",
                host = "127.0.0.1",
                user = "test",
            },
        }

        connection_buffers["docker-test-1"] = 10
        vim.api.nvim_buf_is_valid = function()
            return false
        end

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return all_connections
            end,
            filter_by_type = function()
                return {}
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        local ok, err = actions.reconnect_connection({}, "docker-test-1")

        assert.is_nil(ok)
        assert.are.equal("terminal buffer is no longer valid: docker-test-1", err)
        assert.is_nil(connection_buffers["docker-test-1"])
    end)

    it("reconnect discovers restored terminal buffer from buffer metadata", function()
        local all_connections = {
            {
                type = "ssh",
                name = "docker-test-restore",
                host = "127.0.0.1",
                user = "test",
            },
        }

        vim.api.nvim_list_bufs = function()
            return { 31 }
        end

        vim.api.nvim_buf_get_var = function(_, name)
            if name == "kvim_connection_managed" then
                return true
            end

            if name == "kvim_connection_name" then
                return "docker-test-restore"
            end

            if name == "kvim_connection_type" then
                return "ssh"
            end

            error("missing buffer var: " .. tostring(name))
        end

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return all_connections
            end,
            filter_by_type = function()
                return {}
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        local ok = actions.reconnect_connection({}, "docker-test-restore")

        assert.is_true(ok)
        assert.are.equal(1, #opened_terminal_commands)
        assert.are.equal("ssh test@127.0.0.1", opened_terminal_commands[1].command)
        assert.are.equal(11, connection_buffers["docker-test-restore"])
        assert.is_false(buffer_options[31].buflisted)
    end)

    it("reconnect discovers restored terminal buffer from workspace recipe metadata", function()
        local all_connections = {
            {
                type = "ssh",
                name = "docker-test-recipe",
                host = "127.0.0.1",
                user = "test",
            },
        }

        vim.api.nvim_list_bufs = function()
            return { 41 }
        end

        vim.api.nvim_buf_get_var = function(_, name)
            if name == "kvim_workspace_recipe_connection" then
                return "docker-test-recipe"
            end

            if name == "kvim_workspace_recipe_type" then
                return "ssh"
            end

            error("missing buffer var: " .. tostring(name))
        end

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return all_connections
            end,
            filter_by_type = function()
                return {}
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        local ok = actions.reconnect_connection({}, "docker-test-recipe")

        assert.is_true(ok)
        assert.are.equal(1, #opened_terminal_commands)
        assert.are.equal("ssh test@127.0.0.1", opened_terminal_commands[1].command)
        assert.are.equal(11, connection_buffers["docker-test-recipe"])
        assert.is_false(buffer_options[41].buflisted)
    end)

    it("reconnect discovers restored terminal buffer from workspace recipe command", function()
        local all_connections = {
            {
                type = "ssh",
                name = "docker-test-1",
                host = "127.0.0.1",
                user = "test",
                port = 2222,
            },
        }

        vim.api.nvim_list_bufs = function()
            return { 51 }
        end

        vim.api.nvim_buf_get_var = function(_, name)
            if name == "kvim_workspace_recipe_command" then
                return "ssh -p 2222 test@127.0.0.1"
            end

            error("missing buffer var: " .. tostring(name))
        end

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return all_connections
            end,
            filter_by_type = function()
                return {}
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        local ok = actions.reconnect_connection({}, "docker-test-1")

        assert.is_true(ok)
        assert.are.equal(1, #opened_terminal_commands)
        assert.are.equal("ssh test@127.0.0.1", opened_terminal_commands[1].command)
        assert.are.equal(11, connection_buffers["docker-test-1"])
        assert.is_false(buffer_options[51].buflisted)
    end)

    it("attaches added ssh connection to active workspace when accepted", function()
        local selected_type_callback
        local current_workspace = {
            name = "demo",
            terminals = {},
        }

        package.loaded["kvim.modules.workspaces.state"] = {
            get_current = function()
                return current_workspace
            end,
            set_current = function(workspace)
                current_workspace = workspace
            end,
        }

        package.loaded["kvim.modules.workspaces.storage"] = {
            save = function(workspace)
                table.insert(saved_workspaces, vim.deepcopy(workspace))
                return true
            end,
        }

        vim.ui.select = function(items, _, cb)
            selected_type_callback = cb
            cb(items[1])
        end

        input_responses = {
            "docker-test-4",
            "127.0.0.1",
            "test",
            "2222",
            "",
            "",
            "y",
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        actions.add_connection({})

        assert.is_not_nil(written_file)
        assert.are.equal(1, #saved_workspaces)
        assert.are.equal("docker-test-4", saved_workspaces[1].terminals[1].connection)
        assert.are.equal("ssh", saved_workspaces[1].terminals[1].type)
    end)

    it("does not attach added ssh connection to workspace when declined", function()
        local current_workspace = {
            name = "demo",
            terminals = {},
        }

        package.loaded["kvim.modules.workspaces.state"] = {
            get_current = function()
                return current_workspace
            end,
            set_current = function(workspace)
                current_workspace = workspace
            end,
        }

        package.loaded["kvim.modules.workspaces.storage"] = {
            save = function(workspace)
                table.insert(saved_workspaces, vim.deepcopy(workspace))
                return true
            end,
        }

        vim.ui.select = function(items, _, cb)
            cb(items[1])
        end

        input_responses = {
            "docker-test-5",
            "127.0.0.1",
            "test",
            "2222",
            "",
            "",
            "n",
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        actions.add_connection({})

        assert.is_not_nil(written_file)
        assert.are.equal(0, #saved_workspaces)
    end)

    it("does not attach serial connection to workspace", function()
        local current_workspace = {
            name = "demo",
            terminals = {},
        }

        package.loaded["kvim.modules.workspaces.state"] = {
            get_current = function()
                return current_workspace
            end,
            set_current = function(workspace)
                current_workspace = workspace
            end,
        }

        package.loaded["kvim.modules.workspaces.storage"] = {
            save = function(workspace)
                table.insert(saved_workspaces, vim.deepcopy(workspace))
                return true
            end,
        }

        vim.ui.select = function(items, _, cb)
            cb(items[2])
        end

        input_responses = {
            "esp32",
            "/dev/ttyUSB0",
            "115200",
            "picocom",
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        actions.add_connection({})

        assert.is_not_nil(written_file)
        assert.are.equal(0, #saved_workspaces)
    end)

    it("delete_connection removes ssh recipes from workspaces", function()
        local current_workspace = {
            name = "demo",
            terminals = {
                { name = "docker-test-1", type = "ssh", connection = "docker-test-1" },
            },
        }

        workspace_names = { "demo", "other" }
        workspace_store = {
            demo = vim.deepcopy(current_workspace),
            other = {
                name = "other",
                terminals = {
                    { name = "docker-test-1", type = "ssh", connection = "docker-test-1" },
                    { name = "keep-shell", type = "shell", command = "echo hi" },
                },
            },
        }

        package.loaded["kvim.modules.workspaces.state"] = {
            get_current = function()
                return current_workspace
            end,
            set_current = function(workspace)
                current_workspace = workspace
            end,
        }

        package.loaded["kvim.modules.workspaces.storage"] = {
            list = function()
                return workspace_names
            end,
            load = function(name)
                return vim.deepcopy(workspace_store[name])
            end,
            save = function(workspace)
                workspace_store[workspace.name] = vim.deepcopy(workspace)
                table.insert(saved_workspaces, vim.deepcopy(workspace))
                return true
            end,
        }

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return {
                    { type = "ssh", name = "docker-test-1", host = "127.0.0.1", user = "test" },
                }
            end,
            filter_by_type = function()
                return {}
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        vim.fn.filereadable = function(path)
            if path == "/tmp/kvim_test_connections.lua" then
                return 1
            end

            return 0
        end

        _G.dofile = function(path)
            if path == "/tmp/kvim_test_connections.lua" then
                return {
                    { type = "ssh", name = "docker-test-1", host = "127.0.0.1", user = "test" },
                }
            end

            return {}
        end

        input_responses = { "y" }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        actions.delete_connection({}, "docker-test-1")

        assert.are.equal(2, #saved_workspaces)
        assert.are.same(0, #workspace_store.demo.terminals)
        assert.are.same(1, #workspace_store.other.terminals)
        assert.are.same("keep-shell", workspace_store.other.terminals[1].name)
        assert.are.same(0, #current_workspace.terminals)
    end)

    it("delete_connection skips workspace cleanup for serial connections", function()
        workspace_names = { "demo" }
        workspace_store = {
            demo = {
                name = "demo",
                terminals = {
                    { name = "keep-ssh", type = "ssh", connection = "keep-ssh" },
                },
            },
        }

        package.loaded["kvim.modules.workspaces.storage"] = {
            list = function()
                return workspace_names
            end,
            load = function(name)
                return vim.deepcopy(workspace_store[name])
            end,
            save = function(workspace)
                workspace_store[workspace.name] = vim.deepcopy(workspace)
                table.insert(saved_workspaces, vim.deepcopy(workspace))
                return true
            end,
        }

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return {
                    { type = "serial", name = "esp32", device = "/dev/ttyUSB0", baudrate = 115200 },
                }
            end,
            filter_by_type = function()
                return {}
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        vim.fn.filereadable = function(path)
            if path == "/tmp/kvim_test_connections.lua" then
                return 1
            end

            return 0
        end

        _G.dofile = function(path)
            if path == "/tmp/kvim_test_connections.lua" then
                return {
                    { type = "serial", name = "esp32", device = "/dev/ttyUSB0", baudrate = 115200 },
                }
            end

            return {}
        end

        input_responses = { "y" }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        actions.delete_connection({}, "esp32")

        assert.are.equal(0, #saved_workspaces)
        assert.are.same(1, #workspace_store.demo.terminals)
    end)

    it("persists missing ssh identity_file and IdentitiesOnly on install key", function()
        local selected
        local all_connections = {
            {
                type = "ssh",
                name = "docker-test-1",
                host = "127.0.0.1",
                user = "test",
                port = 2222,
            },
        }

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return all_connections
            end,
            filter_by_type = function(connections, ctype)
                local result = {}
                for _, conn in ipairs(connections) do
                    if conn.type == ctype then
                        table.insert(result, conn)
                    end
                end
                return result
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.picker"] = {
            select = function(items, cb)
                selected = items[1]
                cb(selected)
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        actions.install_ssh_key_picker({})

        assert.are.equal(1, #install_key_calls)
        assert.are.equal("/home/test/.ssh/kvim_docker-test-1_ed25519", install_key_calls[1].identity_file)
        assert.are.equal("yes", install_key_calls[1].options.IdentitiesOnly)

        assert.is_not_nil(written_file)
        assert.are.equal("/tmp/kvim_test_connections.lua", written_file.file)

        local content = table.concat(written_file.lines, "\n")
        assert.matches("identity_file", content)
        assert.matches("IdentitiesOnly", content)
    end)

    it("setup ssh key installs after ensuring local key", function()
        local all_connections = {
            {
                type = "ssh",
                name = "docker-test-2",
                host = "127.0.0.1",
                user = "test",
            },
        }

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return all_connections
            end,
            filter_by_type = function(connections, ctype)
                local result = {}
                for _, conn in ipairs(connections) do
                    if conn.type == ctype then
                        table.insert(result, conn)
                    end
                end
                return result
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.picker"] = {
            select = function(items, cb)
                cb(items[1])
            end,
        }

        package.loaded["kvim.modules.connections.ssh_keys"] = {
            install_key = function(conn)
                table.insert(install_key_calls, conn)
            end,
            ensure_local_key_for_connection = function(conn)
                table.insert(ensured_key_calls, conn)
                return true, "generated"
            end,
            key_path_for_connection = function(conn)
                return "/home/test/.ssh/kvim_" .. tostring(conn.name or "connection") .. "_ed25519"
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        actions.setup_ssh_key_picker({})

        assert.are.equal(1, #ensured_key_calls)
        assert.are.equal("docker-test-2", ensured_key_calls[1].name)
        assert.are.equal(1, #install_key_calls)
    end)

    it("setup ssh key installs when local key already exists", function()
        local all_connections = {
            {
                type = "ssh",
                name = "docker-test-3",
                host = "127.0.0.1",
                user = "test",
            },
        }

        package.loaded["kvim.modules.connections.config"] = {
            load = function()
                return all_connections
            end,
            filter_by_type = function(connections, ctype)
                local result = {}
                for _, conn in ipairs(connections) do
                    if conn.type == ctype then
                        table.insert(result, conn)
                    end
                end
                return result
            end,
            get_config_file = function()
                return "/tmp/kvim_test_connections.lua"
            end,
        }

        package.loaded["kvim.modules.connections.picker"] = {
            select = function(items, cb)
                cb(items[1])
            end,
        }

        package.loaded["kvim.modules.connections.ssh_keys"] = {
            install_key = function(conn)
                table.insert(install_key_calls, conn)
            end,
            ensure_local_key_for_connection = function(conn)
                table.insert(ensured_key_calls, conn)
                return true, "existing"
            end,
            key_path_for_connection = function(conn)
                return "/home/test/.ssh/kvim_" .. tostring(conn.name or "connection") .. "_ed25519"
            end,
        }

        package.loaded["kvim.modules.connections.actions"] = nil
        actions = require("kvim.modules.connections.actions")

        actions.setup_ssh_key_picker({})

        assert.are.equal(1, #ensured_key_calls)
        assert.are.equal(1, #install_key_calls)
        assert.are.equal("docker-test-3", install_key_calls[1].name)
    end)
end)
