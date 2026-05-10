-- lua/kvim/keymaps.lua

local M = {}

local function map(mode, lhs, rhs, opts)
	if not lhs or lhs == "" then
		return
	end

	vim.keymap.set(mode, lhs, rhs, opts)
end

function M.setup_personal(config)
	local opts = config.keymaps.opts
	local mappings = config.keymaps.mappings.personal

	map("n", mappings.save,		"<cmd>w!<CR>",	opts)
	map("n", mappings.close_buffer, "<cmd>q!<CR>",	opts)
	map("n", mappings.quit_all,	"<cmd>qa!<CR>",	opts)
	map("n", mappings.clear_search, "<cmd>noh<CR>",opts)
end

function M.setup_core(config)
	local opts = config.keymaps.opts
	local mappings = config.keymaps.mappings.core

	map("n", mappings.modules,	"<cmd>KvimModules<CR>",	opts)
	map("n", mappings.action,	"<cmd>KvimAction<CR>",	opts)

	map("n", mappings.run,		"<cmd>KvimRun<CR>",     opts)
	map("n", mappings.test,		"<cmd>KvimTest<CR>",	opts)
	map("n", mappings.build,	"<cmd>KvimBuild<CR>",	opts)
	map("n", mappings.format,	"<cmd>KvimFormat<CR>",	opts)
	map("n", mappings.lint,		"<cmd>KvimLint<CR>",	opts)
end

function M.setup_ui(config)
    local opts = config.keymaps.opts
    local mappings = config.keymaps.mappings.ui

    if not mappings then
        return
    end
    -- neo-tree
    map("n", mappings.explorer_toggle,      "<cmd>Neotree toggle filesystem left<CR>",  opts)
    map("n", mappings.explorer_focus,       "<cmd>Neotree focus filesystem left<CR>",   opts)
    map("n", mappings.explorer_reveal,      "<cmd>Neotree reveal filesystem left<CR>",  opts)
    map("n", mappings.explorer_close,       "<cmd>Neotree close<CR>",                   opts)
    map("n", mappings.explorer_git_status,  "<cmd>Neotree git_status left<CR>",         opts)
    map("n", mappings.explorer_buffers,     "<cmd>Neotree buffers left<CR>",            opts)
    -- yazi
    map("n", mappings.yazi,     "<cmd>Yazi<CR>",        opts)
    map("n", mappings.yazi_cwd, "<cmd>Yazi cwd<CR>",    opts)
    -- Telescope
    map("n", mappings.find_files,   "<cmd>Telescope find_files<CR>",    opts)
    map("n", mappings.live_grep,    "<cmd>Telescope live_grep<CR>",     opts)
    map("n", mappings.find_buffers, "<cmd>Telescope buffers<CR>",       opts)
    map("n", mappings.recent_files, "<cmd>Telescope oldfiles<CR>",      opts)
    map("n", mappings.help_tags,    "<cmd>Telescope help_tags<CR>",     opts)
end

function M.setup_terminal(config)
	local opts = config.keymaps.opts
	local mappings = config.keymaps.mappings.terminal
    local terminal = require("kvim.core.terminal")

    terminal.setup()
    
    -- exit from terminal-mode to normal-mode 
    map("t", mappings.exit_terminal, "<C-\\><C-n>", opts)
    -- open terminals
    map("n", mappings.open_right, function() terminal.open("right") end, opts)
    map("n", mappings.open_left, function() terminal.open("left") end, opts)
    map("n", mappings.open_top, function() terminal.open("top") end, opts)
    map("n", mappings.open_bottom, function() terminal.open("bottom") end, opts)
end

function M.setup()
	local config = require("kvim.config").get()

	if not config.keymaps.enabled then
		return
	end

	local presets = config.keymaps.presets

	if presets.personal then
		M.setup_personal(config)
	end

	if presets.core then
		M.setup_core(config)
	end

    if presets.ui then
        M.setup_ui(config)
    end

    if presets.terminal then
        M.setup_terminal(config)
    end
end

return M
