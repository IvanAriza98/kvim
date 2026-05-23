describe("kvim.ui.editor", function()
    local editor

    before_each(function()
        package.loaded["kvim.ui.editor"] = nil
        package.loaded["kvim.config"] = nil
    end)

    after_each(function()
        package.loaded["kvim.ui.editor"] = nil
        package.loaded["kvim.config"] = nil
    end)

    it("applies absolute number mode", function()
        package.loaded["kvim.config"] = {
            get = function()
                return {
                    ui = {
                        editor = {
                            numbers = { enabled = true, mode = "absolute" },
                            indentation = {},
                            cursorline = true,
                            signcolumn = "yes",
                            wrap = false,
                        },
                    },
                }
            end,
        }

        editor = require("kvim.ui.editor")
        editor.setup()

        assert.is_true(vim.opt.number:get())
        assert.is_false(vim.opt.relativenumber:get())
    end)

    it("applies hybrid number mode", function()
        package.loaded["kvim.config"] = {
            get = function()
                return {
                    ui = {
                        editor = {
                            numbers = { enabled = true, mode = "hybrid" },
                            indentation = {},
                            cursorline = true,
                            signcolumn = "yes",
                            wrap = false,
                        },
                    },
                }
            end,
        }

        editor = require("kvim.ui.editor")
        editor.setup()

        assert.is_true(vim.opt.number:get())
        assert.is_true(vim.opt.relativenumber:get())
    end)

    it("applies indentation defaults and custom values", function()
        package.loaded["kvim.config"] = {
            get = function()
                return {
                    ui = {
                        editor = {
                            numbers = { enabled = false, mode = "none" },
                            indentation = {
                                tabstop = 2,
                                shiftwidth = 2,
                                softtabstop = 2,
                                expandtab = true,
                                smartindent = true,
                                autoindent = true,
                            },
                            cursorline = false,
                            signcolumn = "yes",
                            wrap = true,
                            scrolloff = 5,
                            sidescrolloff = 6,
                            termguicolors = true,
                        },
                    },
                }
            end,
        }

        editor = require("kvim.ui.editor")
        editor.setup()

        assert.are.same(2, vim.opt.tabstop:get())
        assert.are.same(2, vim.opt.shiftwidth:get())
        assert.are.same(2, vim.opt.softtabstop:get())
        assert.is_true(vim.opt.expandtab:get())
        assert.are.same(5, vim.opt.scrolloff:get())
        assert.are.same(6, vim.opt.sidescrolloff:get())
    end)
end)
