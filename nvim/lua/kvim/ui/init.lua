-- lua/kvim/ui/init.lua

local M = {}

function M.setup()
	local config = require("kvim.config").get()

	if not config.ui or not config.ui.enabled then
		return 
	end

	require("kvim.ui.editor").setup()
	-- require("kvim.ui.theme").setup()
end

return M
