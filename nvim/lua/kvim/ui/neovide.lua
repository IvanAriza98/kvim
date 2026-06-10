local M = {}

function M.setup()
    if not vim.g.neovide then
        return
    end

    local config = require("kvim.config").get()
    local neovide = ((config.ui or {}).neovide) or {}

    if neovide.enabled == false then
        return
    end

    if neovide.scale_factor ~= nil then
        vim.g.neovide_scale_factor = neovide.scale_factor
    end

    if neovide.transparency ~= nil then
        vim.g.neovide_opacity = neovide.transparency
    end

    if neovide.cursor_animation_length ~= nil then
        vim.g.neovide_cursor_animation_length = neovide.cursor_animation_length
    end

    if neovide.scroll_animation_length ~= nil then
        vim.g.neovide_scroll_animation_length = neovide.scroll_animation_length
    end

    if neovide.hide_mouse_when_typing ~= nil then
        vim.g.neovide_hide_mouse_when_typing = neovide.hide_mouse_when_typing
    end

    if neovide.remember_window_size ~= nil then
        vim.g.neovide_remember_window_size = neovide.remember_window_size
    end

    if neovide.fullscreen ~= nil then
        vim.g.neovide_fullscreen = neovide.fullscreen
    end
end

return M
