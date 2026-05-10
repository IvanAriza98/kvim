-- lua/kvim/registry.lua

local M = {}
local modules = {}

function M.register(module)
	if type(module) ~= "table" then
		vim.notify("Kvim module must be a table", vim.log.levels.ERROR)
		return
	end

	if type(module.name) ~= "string" then
		vim.notify("Kvim module needs a name", vim.log.levels.ERROR)
		return
	end

	if type(module.actions) ~= "table" then
		vim.notify("Kvim module needs actions", vim.log.levels.ERROR)
		return
	end

	modules[module.name] = module
end


function M.get_modules()
	return modules
end

function M.run_action(module_name, action_name)
	if not module_name or module_name == "" then
		vim.notify("Kvim module name is required", vim.log.levels.ERROR)
		return
	end

	if not action_name or action_name == "" then
		vim.notify("Kvim action name is required", vim.log.levels.ERROR)
		return
	end

	local module = modules[module_name]

	if not module then
		vim.notify("Kvim module not found: " .. module_name, vim.log.levels.ERROR)
		return
	end

	local action = module.actions[action_name]
	if not action then
		vim.notify("Kvim action not found: " .. module_name .. "." .. action_name, vim.log.levels.ERROR)
		return
	end

	if action.callback then
		action.callback()
		return
	end

	if action.command then
		require("kvim.core.runner").run(action.command)
		return
	end
	vim.notify("Kvim action has no command or callback", vim.log.levels.ERROR)
end

return M
