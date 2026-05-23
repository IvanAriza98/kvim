describe("kvim.core.terminal", function()
    local terminal
    local cmds

    before_each(function()
        cmds = {}
        _G.__orig_cmd = vim.cmd
        vim.cmd = function(c)
            table.insert(cmds, c)
        end

        package.loaded["kvim.core.terminal"] = nil
        terminal = require("kvim.core.terminal")
    end)

    after_each(function()
        vim.cmd = _G.__orig_cmd
        _G.__orig_cmd = nil
        package.loaded["kvim.core.terminal"] = nil
    end)

    it("opens terminal split at requested position", function()
        terminal.open("right")
        assert.are.same("rightbelow vsplit", cmds[1])
    end)

    it("opens terminal command when provided", function()
        cmds = {}
        terminal.open_command("echo ok", { position = "bottom" })
        assert.are.same("botright split", cmds[1])
        assert.are.same("terminal echo ok", cmds[2])
        assert.are.same("startinsert", cmds[#cmds])
    end)
end)
