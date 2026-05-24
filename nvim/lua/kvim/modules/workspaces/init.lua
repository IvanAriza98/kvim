local M = {}

M.name = "workspaces"
M.actions = require("kvim.modules.workspaces.actions")

function M.setup(opts)
    opts = opts or {}

    require("kvim.modules.workspaces.config").setup(opts)
    require("kvim.modules.workspaces.commands").setup(opts)
    require("kvim.modules.workspaces.keymaps").setup(opts)
end

function M.plugins()
    return require("kvim.modules.workspaces.plugins")
end

return M
