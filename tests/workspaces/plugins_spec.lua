describe("kvim.modules.workspaces.plugins", function()
    local plugins
    local tabenter_callback
    local goto_term_called
    local explorer_guard_called
    local notifications

    before_each(function()
        goto_term_called = 0
        explorer_guard_called = 0
        tabenter_callback = nil
        notifications = {}

        package.loaded["kvim.modules.workspaces.state"] = {
            get_tab_role = function()
                return "term"
            end,
            set_active_tab_role = function() end,
        }

        package.loaded["kvim.modules.workspaces.actions"] = {
            goto_term_tab = {
                callback = function()
                    goto_term_called = goto_term_called + 1
                end,
            },
            handle_explorer_opened_in_term = {
                callback = function()
                    explorer_guard_called = explorer_guard_called + 1
                end,
            },
        }

        _G.__orig_notify = vim.notify
        vim.notify = function(message, level)
            table.insert(notifications, { message = message, level = level })
        end

        _G.__orig_create_augroup = vim.api.nvim_create_augroup
        vim.api.nvim_create_augroup = function()
            return 1
        end

        _G.__orig_create_autocmd = vim.api.nvim_create_autocmd
        vim.api.nvim_create_autocmd = function(event, opts)
            if event == "TabEnter" then
                tabenter_callback = opts.callback
            end
            if event == "FileType" and opts.pattern == "neo-tree" then
                _G.__neo_tree_filetype_callback = opts.callback
            end
        end

        _G.__orig_get_option_value = vim.api.nvim_get_option_value
        vim.api.nvim_get_option_value = function(name)
            if name == "filetype" then
                return "neo-tree"
            end
            return ""
        end

        _G.__orig_tabpagenr = vim.fn.tabpagenr
        vim.fn.tabpagenr = function()
            return 2
        end

        _G.__orig_cmd = vim.cmd
        vim.cmd = function() end

        _G.__orig_schedule = vim.schedule
        vim.schedule = function(cb)
            cb()
        end

        package.loaded["kvim.modules.workspaces.plugins"] = nil
        plugins = require("kvim.modules.workspaces.plugins")
    end)

    after_each(function()
        vim.api.nvim_create_augroup = _G.__orig_create_augroup
        vim.api.nvim_create_autocmd = _G.__orig_create_autocmd
        vim.api.nvim_get_option_value = _G.__orig_get_option_value
        vim.fn.tabpagenr = _G.__orig_tabpagenr
        vim.cmd = _G.__orig_cmd
        vim.schedule = _G.__orig_schedule
        vim.notify = _G.__orig_notify

        _G.__orig_create_augroup = nil
        _G.__orig_create_autocmd = nil
        _G.__orig_get_option_value = nil
        _G.__orig_tabpagenr = nil
        _G.__orig_cmd = nil
        _G.__orig_schedule = nil
        _G.__orig_notify = nil
        _G.__neo_tree_filetype_callback = nil

        package.loaded["kvim.modules.workspaces.state"] = nil
        package.loaded["kvim.modules.workspaces.actions"] = nil
        package.loaded["kvim.modules.workspaces.plugins"] = nil
    end)

    it("redirects neo-tree away from term tab on TabEnter", function()
        local bufferline_spec = plugins[2]
        local opts = bufferline_spec.opts()

        assert.is_table(opts)
        assert.is_function(tabenter_callback)

        tabenter_callback()

        assert.are.equal(1, goto_term_called)
    end)

    it("runs explorer guard when neo-tree filetype opens", function()
        local bufferline_spec = plugins[2]
        local opts = bufferline_spec.opts()

        assert.is_table(opts)
        assert.is_function(_G.__neo_tree_filetype_callback)

        _G.__neo_tree_filetype_callback()

        assert.are.equal(1, explorer_guard_called)
        assert.are.equal("KVIM Workspaces: Neo-tree cannot be opened in term tab", notifications[1].message)
    end)
end)
