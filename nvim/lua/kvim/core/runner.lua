-- lua/kvim/runner.lua

local M = {}

local function expand_command(command)
	local file = vim.fn.expand("%")
	local filepath = vim.fn.expand("%:p")
	local filename = vim.fn.expand("%:t")
	local cwd = vim.fn.getcwd()

	command = command:gsub("{file}", vim.fn.shellescape(file))
	command = command:gsub("{filepath}", vim.fn.shellescape(filepath))
	command = command:gsub("{filename}", vim.fn.shellescape(filename))
	command = command:gsub("{cwd}", vim.fn.shellescape(cwd))

	return command
end

function M.run(command)
	command = expand_command(command)

	local config = require("kvim.config").get()

	if config.terminal.position == "bottom" then
		vim.cmd("botright split")
		vim.cmd("resize " .. config.terminal.height)
	else
		vim.cmd("botright vertical split")
	end

	vim.cmd("terminal " .. command)
	vim.cmd("startinsert")
end

return M
