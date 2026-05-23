describe("kvim.core.registry", function()
    local registry
    local notified
    local runner_calls

    before_each(function()
        package.loaded["kvim.core.registry"] = nil
        package.loaded["kvim.core.runner"] = {
            run = function(cmd)
                table.insert(runner_calls, cmd)
            end,
        }

        notified = {}
        runner_calls = {}
        local original_notify = vim.notify
        _G.__orig_notify = original_notify
        vim.notify = function(msg)
            table.insert(notified, msg)
        end

        registry = require("kvim.core.registry")
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        _G.__orig_notify = nil
        package.loaded["kvim.core.registry"] = nil
        package.loaded["kvim.core.runner"] = nil
    end)

    it("registers module with optional actions", function()
        registry.register({ name = "demo" })
        local modules = registry.get_modules()
        assert.is_table(modules.demo)
        assert.is_table(modules.demo.actions)
    end)

    it("runs callback action safely", function()
        local called = false
        registry.register({
            name = "m",
            actions = {
                ok = {
                    callback = function()
                        called = true
                    end,
                },
            },
        })

        registry.run_action("m", "ok")
        assert.is_true(called)
    end)

    it("delegates command action to runner", function()
        registry.register({
            name = "m2",
            actions = {
                run = { command = "echo hi" },
            },
        })

        registry.run_action("m2", "run")
        assert.are.same({ "echo hi" }, runner_calls)
    end)

    it("notifies when callback throws", function()
        registry.register({
            name = "m3",
            actions = {
                bad = {
                    callback = function()
                        error("boom")
                    end,
                },
            },
        })

        registry.run_action("m3", "bad")
        assert.is_true(#notified > 0)
    end)
end)
