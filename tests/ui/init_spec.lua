describe("kvim.ui.init", function()
    local ui
    local calls

    before_each(function()
        calls = { editor = 0, lualine = 0 }

        package.loaded["kvim.ui"] = nil
        package.loaded["kvim.config"] = nil
        package.loaded["kvim.ui.editor"] = nil
        package.loaded["kvim.ui.lualine"] = nil
    end)

    after_each(function()
        package.loaded["kvim.ui"] = nil
        package.loaded["kvim.config"] = nil
        package.loaded["kvim.ui.editor"] = nil
        package.loaded["kvim.ui.lualine"] = nil
    end)

    it("does nothing when ui is disabled", function()
        package.loaded["kvim.config"] = {
            get = function()
                return { ui = { enabled = false } }
            end,
        }
        package.loaded["kvim.ui.editor"] = { setup = function() calls.editor = calls.editor + 1 end }
        package.loaded["kvim.ui.lualine"] = { setup = function() calls.lualine = calls.lualine + 1 end }

        ui = require("kvim.ui")
        ui.setup()

        assert.are.same(0, calls.editor)
        assert.are.same(0, calls.lualine)
    end)

    it("calls editor and lualine setup when enabled", function()
        package.loaded["kvim.config"] = {
            get = function()
                return { ui = { enabled = true } }
            end,
        }
        package.loaded["kvim.ui.editor"] = { setup = function() calls.editor = calls.editor + 1 end }
        package.loaded["kvim.ui.lualine"] = { setup = function() calls.lualine = calls.lualine + 1 end }

        ui = require("kvim.ui")
        ui.setup()

        assert.are.same(1, calls.editor)
        assert.are.same(1, calls.lualine)
    end)
end)
