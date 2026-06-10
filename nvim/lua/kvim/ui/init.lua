-- lua/kvim/ui/init.lua

local M = {}

function M.setup()
	local config = require("kvim.config").get()

	if not config.ui or not config.ui.enabled then
		return
	end

	-- UI base: opciones de editor + barra de estado.
	require("kvim.ui.editor").setup()
	require("kvim.ui.lualine").setup()
	require("kvim.ui.neovide").setup()
end

return M
