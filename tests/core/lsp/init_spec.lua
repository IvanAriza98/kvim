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
        package.loaded["mason"] = nil
        package.loaded["mason-lspconfig"] = nil
    end)

    after_each(function()
        vim.notify = _G.__orig_notify
        _G.__orig_notify = nil
        package.loaded["kvim.core.lsp"] = nil
        package.loaded["mason"] = nil
        package.loaded["mason-lspconfig"] = nil
    end)

    it("notifies when mason is missing", function()
        lsp = require("kvim.core.lsp")
        lsp.setup()
        assert.is_true(#notified > 0)
    end)
end)
