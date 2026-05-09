-- lua/kvim/commands.lua

local M = {}

function M.setup()
	vim.api.nvim_create_user_command("KvimModules", function()
		local modules = require("kvim").get_modules()

		for name, _ in pairs(modules) do
			print(name)
		end
	end, {})

	vim.api.nvim_create_user_command("KvimAction", function(opts)
		local args = vim.split(opts.args, " ")

		local module_name = args[1]
		local action_name = args[2]

		if not module_name or not action_name then
			vim.notify("Usage: :KvimAction <module> <action>", vim.log.levels.ERROR)
			return
		end

		require("kvim").run_action(module_name, action_name)
	end, { nargs = "*" })
end

return M
