local M = {}

local function apply_terminal_palette()
    local palette = {
        "#45475a", -- black
        "#f38ba8", -- red
        "#a6e3a1", -- green
        "#f9e2af", -- yellow
        "#89b4fa", -- blue
        "#f5c2e7", -- magenta
        "#94e2d5", -- cyan
        "#bac2de", -- white
        "#585b70", -- bright black
        "#f38ba8", -- bright red
        "#a6e3a1", -- bright green
        "#f9e2af", -- bright yellow
        "#89b4fa", -- bright blue
        "#f5c2e7", -- bright magenta
        "#94e2d5", -- bright cyan
        "#a6adc8", -- bright white
    }

    for index, color in ipairs(palette) do
        vim.g["terminal_color_" .. tostring(index - 1)] = color
    end
end

function M.setup()
    if not vim.g.neovide then
        return
    end

    local config = require("kvim.config").get()
    local font_utils = require("kvim.ui.font")
    local font = font_utils.get_config()
    local neovide = ((config.ui or {}).neovide) or {}

    if neovide.enabled == false then
        return
    end

    if font.enabled ~= false and type(font.family) == "string" and font.family ~= "" then
        local guifont_value = font_utils.format_guifont(font.family, font.neovide_size or 12)
        local ok, err = pcall(function()
            vim.o.guifont = guifont_value
        end)

        if not ok then
            vim.schedule(function()
                vim.notify(
                    string.format("KVIM could not apply Neovide font '%s': %s", guifont_value, tostring(err)),
                    vim.log.levels.WARN
                )
            end)
        end
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

    apply_terminal_palette()
end

return M
