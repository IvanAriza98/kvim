local M = {}

local defaults = {
    enabled = true,
    prefix = "<leader>w",
    auto_restore = false,
    auto_save = false,
}

local options = vim.deepcopy(defaults)

function M.setup(opts)
    options = vim.tbl_deep_extend("force", defaults, opts or {})
end

function M.get()
    return options
end

return M
