describe("kvim.core.commands", function()
    local commands
    local notified
    local run_action_calls

    before_each(function()
        package.loaded["kvim"] = {
            get_modules = function()
                return { alpha = {}, beta = {} }
            end,
            run_action = function(module_name, action_name)
                table.insert(run_action_calls, { module_name, action_name })
            end,
        }
        package.loaded["kvim.core.commands"] = nil

        notified = {}
        run_action_calls = {}
        _G.__orig_notify = vim.notify
        vim.notify = function(msg)
            table.insert(notified, msg)
        end

        pcall(vim.api.nvim_del_user_command, "KvimModules")
        pcall(vim.api.nvim_del_user_command, "KvimAction")

        commands = require("kvim.core.commands")
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        _G.__orig_notify = nil
        pcall(vim.api.nvim_del_user_command, "KvimModules")
        pcall(vim.api.nvim_del_user_command, "KvimAction")
        package.loaded["kvim.core.commands"] = nil
        package.loaded["kvim"] = nil
    end)

    it("registers KvimModules and KvimAction", function()
        commands.setup()
        local registered = vim.api.nvim_get_commands({})
        assert.is_not_nil(registered.KvimModules)
        assert.is_not_nil(registered.KvimAction)
    end)

    it("shows usage when KvimAction args are missing", function()
        commands.setup()
        vim.cmd("KvimAction")
        assert.is_true(#notified > 0)
    end)

    it("forwards module/action args to kvim.run_action", function()
        commands.setup()
        vim.cmd("KvimAction git status")
        assert.are.same({ { "git", "status" } }, run_action_calls)
    end)
end)
