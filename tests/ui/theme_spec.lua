describe("kvim.ui.theme", function()
    local theme
    local notified

    before_each(function()
        notified = {}

        _G.__orig_notify = vim.notify
        vim.notify = function(msg)
            table.insert(notified, msg)
        end

        package.loaded["kvim.ui.theme"] = nil
        package.loaded["kvim.config"] = nil
        package.loaded["catppuccin"] = nil
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        _G.__orig_notify = nil
        if _G.__orig_cmd then
            vim.cmd = _G.__orig_cmd
            _G.__orig_cmd = nil
        end
        package.loaded["kvim.ui.theme"] = nil
        package.loaded["kvim.config"] = nil
        package.loaded["catppuccin"] = nil
    end)

    it("does nothing when theme is disabled", function()
        package.loaded["kvim.config"] = {
            get = function()
                return { ui = { theme = { enabled = false } } }
            end,
        }

        theme = require("kvim.ui.theme")
        theme.setup()

        assert.are.same(0, #notified)
    end)

    it("notifies when catppuccin plugin is missing", function()
        package.loaded["kvim.config"] = {
            get = function()
                return { ui = { theme = { enabled = true, name = "catppuccin", style = "mocha" } } }
            end,
        }

        theme = require("kvim.ui.theme")
        theme.setup()

        assert.is_true(#notified > 0)
        assert.matches("catppuccin", notified[#notified])
    end)

    it("configures catppuccin and applies colorscheme", function()
        local captured
        local cmds = {}

        package.loaded["kvim.config"] = {
            get = function()
                return { ui = { theme = { enabled = true, name = "catppuccin", style = "latte" } } }
            end,
        }
        package.loaded["catppuccin"] = {
            setup = function(opts)
                captured = opts
            end,
        }

        _G.__orig_cmd = vim.cmd
        vim.cmd = setmetatable({}, {
            __index = function()
                return function(arg)
                    table.insert(cmds, arg)
                end
            end,
            __call = function(_, arg)
                table.insert(cmds, arg)
            end,
        })

        theme = require("kvim.ui.theme")
        theme.setup()

        vim.cmd = _G.__orig_cmd
        _G.__orig_cmd = nil

        assert.is_table(captured)
        assert.are.same("latte", captured.flavour)
        assert.is_true(vim.tbl_contains(cmds, "catppuccin") or vim.tbl_contains(cmds, "colorscheme catppuccin"))
    end)

    it("warns on unknown theme", function()
        package.loaded["kvim.config"] = {
            get = function()
                return { ui = { theme = { enabled = true, name = "unknown-theme" } } }
            end,
        }

        theme = require("kvim.ui.theme")
        theme.setup()

        assert.is_true(#notified > 0)
        assert.matches("unknown theme", notified[#notified])
    end)
end)
