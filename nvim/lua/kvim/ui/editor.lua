-- lua/kvim/ui/editor.lua

local M = {}

local function setup_numbers(numbers)
	if not numbers or not numbers.enabled or numbers.mode == "none" then
	    vim.opt.number = false
		vim.opt.relativenumber = false
	end

	if numbers.mode == "absolute" then
		vim.opt.number = true
		vim.opt.relativenumber = false
		return
	end 	

	if numbers.mode == "relative" then
		vim.opt.number = false
		vim.opt.relativenumber = true 
		return
	end
	
	if numbers.mode == "hybrid" then
		vim.opt.number =true 
		vim.opt.relativenumber = true 
		return
	end
end

local function setup_indentation(indentation)
	indentation = indentation or {}

	vim.opt.tabstop = indentation.tabstop or 4
	vim.opt.shiftwidth = indentation.shiftwidth or 4
	vim.opt.softtabstop = indentation.softtabstop or 4
	vim.opt.expandtab = indentation.expandtab ~= false
	vim.opt.smartindent = indentation.smartindent ~= false
	vim.opt.autoindent = indentation.autoindent ~= false
end

function M.setup()
	local config = require("kvim.config").get()
	local editor = config.ui.editor or {}

	setup_numbers(editor.numbers)
	setup_indentation(editor.indentation)

	vim.opt.cursorline = editor.cursorline
	vim.opt.signcolumn = editor.signcolumn or "yes"
	vim.opt.wrap = editor.wrap
	vim.opt.scrolloff = editor.scrolloff or 8
	vim.opt.sidescrolloff = editor.sidescrolloff or 8
	vim.opt.termguicolors = editor.termguicolors ~= false

end

return M
