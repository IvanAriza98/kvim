local M = {}

M.name = "svn"
M.actions = require("kvim.modules.svn.actions")

function M.setup(opts)
    opts = opts or {} -- Se deja preparado por si se quiere pasar configuraciones
    require("kvim.modules.svn.commands").setup()
    require("kvim.modules.svn.keymaps").setup()
end

return M
