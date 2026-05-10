-- lua/kvim/modules/connections/init.lua

local M = {}

M.name = "connections"
M.actions = require("kvim.modules.connections.actions")

function M.setup(opts)
  opts = opts or {}

  require("kvim.modules.connections.commands").setup(opts)
  require("kvim.modules.connections.keymaps").setup(opts)
end

return M
