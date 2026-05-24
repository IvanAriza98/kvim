describe("kvim.modules.workspaces.storage", function()
    local storage
    local test_state_dir

    before_each(function()
        test_state_dir = vim.fn.tempname()

        _G.__orig_stdpath = vim.fn.stdpath
        vim.fn.stdpath = function(kind)
            if kind == "state" then
                return test_state_dir
            end

            return _G.__orig_stdpath(kind)
        end

        package.loaded["kvim.modules.workspaces.storage"] = nil
        storage = require("kvim.modules.workspaces.storage")
    end)

    after_each(function()
        vim.fn.stdpath = _G.__orig_stdpath
        _G.__orig_stdpath = nil
        vim.fn.delete(test_state_dir, "rf")
        package.loaded["kvim.modules.workspaces.storage"] = nil
    end)

    it("builds workspace path", function()
        local path = storage.workspace_path("demo")
        assert.matches("demo%.json$", path)
    end)

    it("saves and loads workspace", function()
        local workspace = {
            name = "demo",
            root = "/tmp/demo",
            session = "demo",
            version = 1,
            connections = { active = nil },
            terminals = {},
            tasks = {},
        }

        local ok_save, err_save = storage.save(workspace)
        assert.is_true(ok_save)
        assert.is_nil(err_save)

        local loaded, err_load = storage.load("demo")
        assert.is_nil(err_load)
        assert.are.same("demo", loaded.name)
        assert.are.same("/tmp/demo", loaded.root)
    end)

    it("lists and deletes workspaces", function()
        storage.save({ name = "a", root = "/tmp/a", session = "a", version = 1, connections = { active = nil }, terminals = {}, tasks = {} })
        storage.save({ name = "b", root = "/tmp/b", session = "b", version = 1, connections = { active = nil }, terminals = {}, tasks = {} })

        local listed = storage.list()
        assert.is_true(#listed >= 2)

        local ok_delete = storage.delete("a")
        assert.is_true(ok_delete)
    end)

    it("fails if workspace name is missing", function()
        local ok_save, err_save = storage.save({ root = "/tmp/x" })
        assert.is_nil(ok_save)
        assert.is_not_nil(err_save)
    end)
end)
