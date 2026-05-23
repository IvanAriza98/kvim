describe("kvim.core.lsp.diagnostics", function()
    local diagnostics
    local captured

    before_each(function()
        captured = nil
        _G.__orig_diag_config = vim.diagnostic.config
        vim.diagnostic.config = function(opts)
            captured = opts
        end

        package.loaded["kvim.core.lsp.diagnostics"] = nil
        diagnostics = require("kvim.core.lsp.diagnostics")
    end)

    after_each(function()
        vim.diagnostic.config = _G.__orig_diag_config
        _G.__orig_diag_config = nil
        package.loaded["kvim.core.lsp.diagnostics"] = nil
    end)

    it("configures diagnostic signs and float options", function()
        diagnostics.setup()
        assert.is_table(captured)
        assert.are.same("rounded", captured.float.border)
        assert.is_table(captured.signs.text)
    end)
end)
