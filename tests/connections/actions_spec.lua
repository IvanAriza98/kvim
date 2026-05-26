describe("kvim.modules.connections.actions", function()
    local actions
    local set_vars
    local written_file
    local install_key_calls
    local ensured_key_calls

    before_each(function()
        set_vars = {}
        written_file = nil
        install_key_calls = {}
        ensured_key_calls = {}

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
        vim.api.nvim_get_current_buf = _G.__orig_get_current_buf
        vim.api.nvim_buf_set_var = _G.__orig_buf_set_var
        vim.fn.mkdir = _G.__orig_mkdir
        vim.fn.writefile = _G.__orig_writefile

        _G.__orig_notify = nil
        _G.__orig_executable = nil
        _G.__orig_get_current_buf = nil
        _G.__orig_buf_set_var = nil
        _G.__orig_mkdir = nil
        _G.__orig_writefile = nil

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
