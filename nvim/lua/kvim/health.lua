-- lua/kvim/health.lua

local M = {}

function M.check()
  require("kvim.modules.connections.health").check()
end

return M
