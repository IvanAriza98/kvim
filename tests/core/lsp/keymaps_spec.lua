describe("kvim.core.lsp.keymaps", function()
    local keymaps
    local captured_callback
    local jump_counts

    before_each(function()
        captured_callback = nil
        jump_counts = {}

        _G.__orig_create_autocmd = vim.api.nvim_create_autocmd
        vim.api.nvim_create_autocmd = function(_, opts)
            captured_callback = opts.callback
            return 1
        end

        _G.__orig_create_augroup = vim.api.nvim_create_augroup
        vim.api.nvim_create_augroup = function()
            return 1
        end

        _G.__orig_keymap_set = vim.keymap.set
        vim.keymap.set = function() end

        _G.__orig_diag_jump = vim.diagnostic.jump
        vim.diagnostic.jump = function(opts)
            table.insert(jump_counts, opts.count)
        end

        package.loaded["kvim.core.lsp.keymaps"] = nil
        keymaps = require("kvim.core.lsp.keymaps")
    end)

    after_each(function()
        vim.api.nvim_create_autocmd = _G.__orig_create_autocmd
        vim.api.nvim_create_augroup = _G.__orig_create_augroup
        vim.keymap.set = _G.__orig_keymap_set
        vim.diagnostic.jump = _G.__orig_diag_jump

        _G.__orig_create_autocmd = nil
        _G.__orig_create_augroup = nil
        _G.__orig_keymap_set = nil
        _G.__orig_diag_jump = nil
        package.loaded["kvim.core.lsp.keymaps"] = nil
    end)

    it("registers LspAttach autocmd", function()
        keymaps.setup()
        assert.is_function(captured_callback)
    end)

    it("maps diagnostic jumps in opposite directions", function()
        local mappings = {}
        vim.keymap.set = function(_, lhs, rhs)
            mappings[lhs] = rhs
        end

        keymaps.setup()
        captured_callback({ buf = 1 })

        mappings["[d"]()
        mappings["]d"]()

        assert.are.same(-1, jump_counts[1])
        assert.are.same(1, jump_counts[2])
    end)
end)
