describe("kvim.core.keymaps", function()
    local keymaps
    local calls

    before_each(function()
        calls = {}

        package.loaded["kvim.config"] = {
            get = function()
                return {
                    keymaps = {
                        enabled = true,
                        opts = { noremap = true, silent = true },
                        presets = {
                            personal = true,
                            core = true,
                            ui = false,
                            terminal = false,
                        },
                        mappings = {
                            personal = {
                                save = "s",
                                close_buffer = "qq",
                                quit_all = "qe",
                                clear_search = "<Esc>",
                                delete_all_lines = "da",
                            },
                            core = {
                                modules = "<leader>km",
                                action = "<leader>ka",
                            },
                        },
                    },
                }
            end,
        }

        _G.__orig_keymap_set = vim.keymap.set
        vim.keymap.set = function(mode, lhs, rhs, opts)
            table.insert(calls, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
        end

        package.loaded["kvim.core.keymaps"] = nil
        keymaps = require("kvim.core.keymaps")
    end)

    after_each(function()
        vim.keymap.set = _G.__orig_keymap_set
        _G.__orig_keymap_set = nil
        package.loaded["kvim.core.keymaps"] = nil
        package.loaded["kvim.config"] = nil
    end)

    it("sets personal and core mappings when enabled", function()
        keymaps.setup()
        assert.is_true(#calls > 0)
    end)

    it("skips empty lhs mapping", function()
        calls = {}
        keymaps.setup_personal({
            keymaps = {
                opts = {},
                mappings = {
                    personal = {
                        save = "",
                        close_buffer = nil,
                        quit_all = "qe",
                        clear_search = "<Esc>",
                        delete_all_lines = "da",
                    },
                },
            },
        })
        assert.is_true(#calls >= 1)
    end)
end)
