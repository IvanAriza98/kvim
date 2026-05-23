describe("kvim.core.lsp.servers", function()
    local servers
    local calls

    before_each(function()
        calls = {}
        _G.__orig_lsp_config = vim.lsp.config
        vim.lsp.config = function(name, opts)
            calls[name] = opts
        end

        package.loaded["kvim.core.lsp.servers"] = nil
        servers = require("kvim.core.lsp.servers")
    end)

    after_each(function()
        vim.lsp.config = _G.__orig_lsp_config
        _G.__orig_lsp_config = nil
        package.loaded["kvim.core.lsp.servers"] = nil
    end)

    it("registers expected language servers", function()
        servers.setup()

        assert.is_table(calls.lua_ls)
        assert.is_table(calls.clangd)
        assert.is_table(calls.pyright)
        assert.is_table(calls.ts_ls)
        assert.is_table(calls.bashls)
        assert.is_table(calls.jsonls)
        assert.is_table(calls.yamlls)
    end)

    it("configures lua_ls and clangd with expected options", function()
        servers.setup()

        assert.are.same("LuaJIT", calls.lua_ls.settings.Lua.runtime.version)
        assert.are.same(false, calls.lua_ls.settings.Lua.telemetry.enable)
        assert.is_table(calls.clangd.cmd)
        assert.is_true(vim.tbl_contains(calls.clangd.cmd, "--background-index"))
        assert.is_true(vim.tbl_contains(calls.clangd.cmd, "--clang-tidy"))
    end)
end)
