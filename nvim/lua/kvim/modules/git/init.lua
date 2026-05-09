local M = {}

M.name = "git"
M.actions = require("kvim.modules.git.actions")

function M.setup(opts)
    opts = opts or {}

    require("kvim.modules.git.keymaps").setup(opts)
    require("kvim.modules.git.commands").setup(opts)
end

function M.plugins()
    return require("kvim.modules.git.plugins")
end

return M
