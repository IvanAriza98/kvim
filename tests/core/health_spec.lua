describe("kvim.health", function()
    local health
    local original_health
    local original_executable

    before_each(function()
        package.loaded["kvim.health"] = nil
        package.loaded["kvim.core.health"] = nil
        package.loaded["kvim.config"] = nil
        package.loaded["kvim.modules.connections.health"] = nil

        original_health = vim.health
        original_executable = vim.fn.executable

        local events = {}

        vim.health = {
            start = function(message)
                table.insert(events, { type = "start", message = message })
            end,
            ok = function(message)
                table.insert(events, { type = "ok", message = message })
            end,
            warn = function(message)
                table.insert(events, { type = "warn", message = message })
            end,
            error = function(message)
                table.insert(events, { type = "error", message = message })
            end,
        }

        _G.__kvim_health_events = events
        _G.__kvim_connections_called = false

        vim.fn.executable = function(cmd)
            local available = {
                git = 1,
                neovide = 0,
                lazygit = 1,
                svn = 1,
                lazysvn = 0,
                ssh = 1,
                scp = 1,
                ["ssh-keygen"] = 1,
                ["ssh-copy-id"] = 0,
                picocom = 0,
            }

            return available[cmd] or 0
        end

        package.loaded["kvim.config"] = {
            get = function()
                return {
                    modules = {
                        git = { enabled = true },
                        svn = { enabled = true },
                        connections = { enabled = true },
                    },
                }
            end,
        }

        package.loaded["kvim.modules.connections.health"] = {
            check = function()
                _G.__kvim_connections_called = true
            end,
        }

        health = require("kvim.health")
    end)

    after_each(function()
        vim.health = original_health
        vim.fn.executable = original_executable
        vim.env.NVIM_APPNAME = nil

        _G.__kvim_health_events = nil
        _G.__kvim_connections_called = nil

        package.loaded["kvim.health"] = nil
        package.loaded["kvim.core.health"] = nil
        package.loaded["kvim.config"] = nil
        package.loaded["kvim.modules.connections.health"] = nil
    end)

    it("reports general environment status and enabled module dependencies", function()
        vim.env.NVIM_APPNAME = "kvim"

        health.check()

        local messages = {}

        for _, event in ipairs(_G.__kvim_health_events) do
            table.insert(messages, event.message)
        end

        assert.is_true(vim.tbl_contains(messages, "NVIM_APPNAME is set to 'kvim'"))
        assert.is_true(vim.tbl_contains(messages, "git executable found"))
        assert.is_true(vim.tbl_contains(messages, "neovide executable not found"))
        assert.is_true(vim.tbl_contains(messages, "git module: lazygit executable found"))
        assert.is_true(vim.tbl_contains(messages, "svn module: lazysvn executable not found"))
        assert.is_true(vim.tbl_contains(messages, "connections module: ssh executable found"))
        assert.is_true(_G.__kvim_connections_called)
    end)

    it("warns when NVIM_APPNAME is not kvim", function()
        vim.env.NVIM_APPNAME = "nvim"

        health.check()

        local warned = false

        for _, event in ipairs(_G.__kvim_health_events) do
            if event.type == "warn" and event.message == "NVIM_APPNAME is 'nvim' instead of recommended 'kvim'" then
                warned = true
                break
            end
        end

        assert.is_true(warned)
    end)
end)
