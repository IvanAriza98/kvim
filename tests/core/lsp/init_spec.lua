describe("kvim.core.lsp.init", function()
    local lsp
    local notified

    before_each(function()
        notified = {}
        _G.__orig_notify = vim.notify
        vim.notify = function(msg)
            table.insert(notified, msg)
        end

        package.loaded["kvim.core.lsp"] = nil
        package.loaded["kvim.core.lsp.diagnostics"] = nil
        package.loaded["kvim.core.lsp.keymaps"] = nil
        package.loaded["kvim.core.lsp.servers"] = nil
        package.loaded["mason"] = nil
        package.loaded["mason-lspconfig"] = nil
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        _G.__orig_notify = nil
        package.loaded["kvim.core.lsp"] = nil
        package.loaded["kvim.core.lsp.diagnostics"] = nil
        package.loaded["kvim.core.lsp.keymaps"] = nil
        package.loaded["kvim.core.lsp.servers"] = nil
        package.loaded["mason"] = nil
        package.loaded["mason-lspconfig"] = nil
    end)

    it("notifies when mason is missing", function()
        lsp = require("kvim.core.lsp")
        lsp.setup()
        assert.is_true(#notified > 0)
    end)

    it("notifies when mason-lspconfig is missing", function()
        package.loaded["mason"] = {
            setup = function() end,
        }

        lsp = require("kvim.core.lsp")
        lsp.setup()

        assert.is_true(#notified > 0)
        assert.matches("mason%-lspconfig", notified[#notified])
    end)

    it("configures diagnostics, keymaps, servers and mason", function()
        local calls = {
            diagnostics = 0,
            keymaps = 0,
            servers = 0,
            mason = 0,
            mason_lsp = 0,
        }
        local captured_mason_lsp_opts

        package.loaded["kvim.core.lsp.diagnostics"] = {
            setup = function()
                calls.diagnostics = calls.diagnostics + 1
            end,
        }
        package.loaded["kvim.core.lsp.keymaps"] = {
            setup = function()
                calls.keymaps = calls.keymaps + 1
            end,
        }
        package.loaded["kvim.core.lsp.servers"] = {
            setup = function()
                calls.servers = calls.servers + 1
            end,
        }

        package.loaded["mason"] = {
            setup = function()
                calls.mason = calls.mason + 1
            end,
        }
        package.loaded["mason-lspconfig"] = {
            setup = function(opts)
                calls.mason_lsp = calls.mason_lsp + 1
                captured_mason_lsp_opts = opts
            end,
        }

        lsp = require("kvim.core.lsp")
        lsp.setup()

        assert.are.same(1, calls.diagnostics)
        assert.are.same(1, calls.keymaps)
        assert.are.same(1, calls.servers)
        assert.are.same(1, calls.mason)
        assert.are.same(1, calls.mason_lsp)
        assert.is_table(captured_mason_lsp_opts)
        assert.is_table(captured_mason_lsp_opts.ensure_installed)
        assert.is_true(vim.tbl_contains(captured_mason_lsp_opts.ensure_installed, "lua_ls"))
        assert.is_true(vim.tbl_contains(captured_mason_lsp_opts.ensure_installed, "clangd"))
        assert.is_true(vim.tbl_contains(captured_mason_lsp_opts.ensure_installed, "pyright"))
        assert.is_true(vim.tbl_contains(captured_mason_lsp_opts.ensure_installed, "ts_ls"))
        assert.is_true(vim.tbl_contains(captured_mason_lsp_opts.ensure_installed, "bashls"))
        assert.is_true(vim.tbl_contains(captured_mason_lsp_opts.ensure_installed, "jsonls"))
        assert.is_true(vim.tbl_contains(captured_mason_lsp_opts.ensure_installed, "yamlls"))
        assert.is_true(captured_mason_lsp_opts.automatic_enable)
    end)
end)
