local M = {}

local defaults = {
    enabled = true,
    family = "FiraCode Nerd Font Mono",
    neovide_size = 12,
    terminal_size = 11,
}

function M.get_config()
    local config = require("kvim.config").get()
    local font = ((config.ui or {}).font) or {}

    return vim.tbl_deep_extend("force", vim.deepcopy(defaults), font)
end

function M.format_guifont(family, size)
    return string.format("%s:h%s", family, tostring(size))
end

return M
