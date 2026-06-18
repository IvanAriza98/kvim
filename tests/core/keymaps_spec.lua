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
                            ui = true,
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
                            ui = {
                                explorer_toggle = "<leader>e",
                                explorer_focus = "<leader>E",
                                explorer_reveal = "<leader>fe",
                                explorer_close = "<leader>ec",
                                explorer_git_status = "<leader>eg",
                                explorer_buffers = "<leader>eb",
                            },
                        },
                    },
                }
            end,
        }

        package.loaded["kvim.modules.workspaces.state"] = {
            get_tab_role = function()
                return nil
            end,
        }

        package.loaded["kvim.modules.workspaces.actions"] = {
            explorer_in_code_tab = {
                callback = function() end,
            },
        }

        _G.__orig_cmd = vim.cmd
        vim.cmd = function() end

        _G.__orig_tabpagenr = vim.fn.tabpagenr
        vim.fn.tabpagenr = function()
            return 1
        end

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
        vim.cmd = _G.__orig_cmd
        _G.__orig_cmd = nil
        vim.fn.tabpagenr = _G.__orig_tabpagenr
        _G.__orig_tabpagenr = nil
        package.loaded["kvim.core.keymaps"] = nil
        package.loaded["kvim.config"] = nil
        package.loaded["kvim.modules.workspaces.state"] = nil
        package.loaded["kvim.modules.workspaces.actions"] = nil
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

    it("redirects explorer actions through code tab when launched from term", function()
        local called_with = {}
        local notifications = {}

        _G.__orig_notify = vim.notify
        vim.notify = function(message, level)
            table.insert(notifications, { message = message, level = level })
        end

        package.loaded["kvim.modules.workspaces.actions"] = {
            explorer_in_code_tab = {
                callback = function(command)
                    table.insert(called_with, command)
                end,
            },
        }

        keymaps.setup()

        local explorer_rhs
        for _, call in ipairs(calls) do
            if call.lhs == "<leader>e" then
                explorer_rhs = call.rhs
                break
            end
        end

        assert.is_function(explorer_rhs)
        explorer_rhs()

        assert.are.equal(1, #called_with)
        assert.are.same("Neotree toggle filesystem left", called_with[1])

        vim.notify = _G.__orig_notify
        _G.__orig_notify = nil
    end)
end)
