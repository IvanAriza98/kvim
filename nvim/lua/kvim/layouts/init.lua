-- =============================================================================
-- Layouts: UI Component Lazy Loading System
-- =============================================================================
-- This module implements deferred loading for heavyweight UI components
-- to minimize Neovim startup time. All layouts use nui-components.
--
-- Loading Strategy:
--   1. FileType autocmds: Load main-menu and cmd-buffer on first file open (100ms)
--   2. VimEnter autocmd: Load config dialogs at 500ms (non-blocking)
--
-- Components Loaded:
--   - kvim.layouts.main-menu: Main menu UI (nui-menu)
--   - kvim.layouts.cmd-buffer: Command buffer UI (nui-popup)
--   - kvim.layouts.configs.esp-idf.config: ESP-IDF settings dialog
--   - kvim.layouts.configs.nrf-sdk.config: NRF-SDK settings dialog
--   - kvim.layouts.configs.general.python-config: Python project settings
--
-- This approach ensures core editing functionality is immediately available
-- while config dialogs load after the user is already in the editor.

vim.cmd([[
augroup kvim_lazy_layouts
  autocmd!
  autocmd FileType * ++once lua require("kvim.layouts.main-menu")
  autocmd FileType * ++once lua require("kvim.layouts.cmd-buffer")
augroup END
]])

--- Defers module loading using vim.defer_fn.
--- Modules are loaded only when actually needed.
---
--- @param module string The module path to require (e.g., "kvim.layouts.configs.esp-idf.config")
--- @param delay number Milliseconds to wait before loading (default: 100)
local lazy_load = function(module, delay)
	vim.defer_fn(function()
		require(module)
	end, delay or 100)
end

--- Load config dialogs on VimEnter with 500ms delay.
--- This prevents blocking the editor while config UI initializes.
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		vim.defer_fn(function()
			lazy_load("kvim.layouts.configs.esp-idf.config", 500)
			lazy_load("kvim.layouts.configs.nrf-sdk.config", 500)
			lazy_load("kvim.layouts.configs.general.python-config", 500)
		end, 500)
	end,
})
