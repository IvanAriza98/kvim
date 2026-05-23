describe("kvim.core.runner", function()
    local runner
    local cmds
    local notified

    before_each(function()
        cmds = {}
        notified = {}

        package.loaded["kvim.config"] = {
            get = function()
                return {
                    terminal = {
                        position = "bottom",
                        height = 9,
                    },
                }
            end,
        }

        _G.__orig_notify = vim.notify
        vim.notify = function(msg)
            table.insert(notified, msg)
        end

        _G.__orig_cmd = vim.cmd
        vim.cmd = function(command)
            table.insert(cmds, command)
        end

        package.loaded["kvim.core.runner"] = nil
        runner = require("kvim.core.runner")
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        vim.cmd = _G.__orig_cmd
        _G.__orig_notify = nil
        _G.__orig_cmd = nil
        package.loaded["kvim.core.runner"] = nil
        package.loaded["kvim.config"] = nil
    end)

    it("opens bottom split, resizes and starts terminal", function()
        runner.run("echo test")
        assert.are.same("botright split", cmds[1])
        assert.are.same("resize 9", cmds[2])
        assert.matches("^terminal ", cmds[3])
        assert.are.same("startinsert", cmds[4])
    end)

    it("notifies on invalid command", function()
        runner.run(nil)
        assert.is_true(#notified > 0)
        assert.are.same(0, #cmds)
    end)
end)
