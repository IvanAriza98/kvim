describe("kvim.ui.lualine", function()
    local lualine_ui
    local notified

    before_each(function()
        notified = {}
        _G.__orig_notify = vim.notify
        vim.notify = function(msg)
            table.insert(notified, msg)
        end

        package.loaded["kvim.ui.lualine"] = nil
        package.loaded["lualine"] = nil
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        _G.__orig_notify = nil
        package.loaded["kvim.ui.lualine"] = nil
        package.loaded["lualine"] = nil
    end)

    it("notifies when lualine plugin is missing", function()
        lualine_ui = require("kvim.ui.lualine")
        lualine_ui.setup()
        assert.is_true(#notified > 0)
        assert.matches("lualine", notified[#notified])
    end)

    it("calls lualine.setup with config when plugin exists", function()
        local called = 0
        local captured

        package.loaded["lualine"] = {
            setup = function(cfg)
                called = called + 1
                captured = cfg
            end,
        }

        lualine_ui = require("kvim.ui.lualine")
        lualine_ui.setup()

        assert.are.same(1, called)
        assert.is_table(captured)
        assert.is_table(captured.sections)
        assert.is_true(captured.options.globalstatus)
    end)
end)
