describe("kvim.modules.workspaces.config", function()
    local config

    before_each(function()
        package.loaded["kvim.modules.workspaces.config"] = nil
        config = require("kvim.modules.workspaces.config")
    end)

    after_each(function()
        package.loaded["kvim.modules.workspaces.config"] = nil
    end)

    it("loads defaults", function()
        local opts = config.get()
        assert.is_true(opts.enabled)
        assert.are.same("<leader>w", opts.prefix)
        assert.is_false(opts.auto_restore)
        assert.is_false(opts.auto_save)
    end)

    it("overrides prefix", function()
        config.setup({ prefix = "<leader>x" })
        local opts = config.get()
        assert.are.same("<leader>x", opts.prefix)
    end)
end)
