-- Bufferline: Barra de buffers con estilo
-- Muestra los buffers abiertos como pestañas en la parte superior
return {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons", -- Iconos para tipos de archivo
    lazy = true,                                  -- Carga perezosa
    event = "VeryLazy",                           -- Se carga después de iniciar (no bloquea startup)
    config = function()
        local bufferline = require('bufferline')

        local function get_storm_palette()
            local fallback = {
                bg_dark = "#24283b",
                blue = "#7aa2f7",
                orange = "#ff9e64",
                cyan = "#2ac3de",
            }

            local ok, tokyonight_colors = pcall(require, "tokyonight.colors")
            if not ok or type(tokyonight_colors.setup) ~= "function" then
                return fallback
            end

            local colors = tokyonight_colors.setup({ style = "storm" }) or {}

            return {
                bg_dark = colors.bg_dark or colors.bg or fallback.bg_dark,
                blue = colors.blue or colors.cyan or fallback.blue,
                orange = colors.orange or fallback.orange,
                cyan = colors.cyan or colors.teal or fallback.cyan,
            }
        end

        local storm = get_storm_palette()

        local function get_current_workspace()
            local ok, workspace = pcall(require, "kvim.workspace")
            if not ok or type(workspace.get_current_workspace) ~= "function" then
                return "code"
            end

            return workspace.get_current_workspace() or "code"
        end

        local normalize_project_tag
        local get_active_code_project

        local function get_workspace_badge(workspace_name)
            if workspace_name == "ssh" then
                return {
                    text = " 🚀 prod ",
                    fg = storm.bg_dark,
                    bg = storm.orange,
                }
            end

            if workspace_name == "ai" then
                return {
                    text = " 🤖 ai ",
                    fg = storm.bg_dark,
                    bg = storm.cyan,
                }
            end

            local active_project = get_active_code_project()
            local badge_text = " 🛠️ dev "

            if active_project.name ~= nil then
                badge_text = string.format(" 🛠️ dev:%s ", active_project.name)
            end

            return {
                text = badge_text,
                fg = storm.bg_dark,
                bg = storm.blue,
            }
        end

        local function get_buffer_workspace(buf_number)
            return vim.b[buf_number].kvim_workspace
        end

        normalize_project_tag = function(value)
            if value == nil then
                return nil
            end

            local as_string = tostring(value)
            local trimmed = vim.trim(as_string)

            if trimmed == "" then
                return nil
            end

            return trimmed
        end

        get_active_code_project = function()
            local active_project = {
                id = nil,
                name = nil,
            }

            local ok, code_projects = pcall(require, "kvim.workspace.code-projects")
            if not ok then
                return active_project
            end

            if type(code_projects.get_active_project_name) == "function" then
                local ok_name, project_name = pcall(code_projects.get_active_project_name)
                if ok_name then
                    active_project.name = normalize_project_tag(project_name)
                end
            end

            if type(code_projects.get_active_project_id) == "function" then
                local ok_id, project_id = pcall(code_projects.get_active_project_id)
                if ok_id then
                    active_project.id = normalize_project_tag(project_id)
                end
            end

            return active_project
        end

        bufferline.setup({
            options = {
                -- Indicador visual para el buffer activo
                indicator = { icon = '|', style = 'icon' },
                -- Estilo de los separadores entre buffers
                separator_style = "slope",
                always_show_bufferline = true,
                -- Formato de números: muestra ID y número ordinal (ej: 1|3)
                numbers = function(opts)
                    return string.format('%s|%s', opts.id, opts.raise(opts.ordinal))
                end,
                -- Presets de estilo (descomentar para modificar)
                style_preset = {
                    -- bufferline.style_preset.no_italic,   -- Sin cursiva
                    -- bufferline.style_preset.no_bold,     -- Sin negrita
                    -- bufferline.style_preset.minimal      -- Estilo minimalista
                },
                -- Filtra buffers según workspace activo
                custom_filter = function(buf_number)
                    local current_workspace = get_current_workspace()
                    local buffer_workspace = get_buffer_workspace(buf_number)

                    if current_workspace == "ssh" then
                        return buffer_workspace == "ssh"
                    end

                    if current_workspace == "ai" then
                        return false
                    end

                    if buffer_workspace ~= nil and buffer_workspace ~= "" and buffer_workspace ~= "code" then
                        return false
                    end

                    local active_project = get_active_code_project()
                    local has_active_project = active_project.id ~= nil

                    if not has_active_project then
                        return true
                    end

                    local buffer_project = normalize_project_tag(vim.b[buf_number].kvim_code_project)
                    if buffer_project ~= nil then
                        return buffer_project == active_project.id
                    end

                    return buf_number == vim.api.nvim_get_current_buf()
                end,
                -- Indicador informativo de workspace alternativo
                custom_areas = {
                    right = function()
                        local current_workspace = get_current_workspace()

                        return {
                            get_workspace_badge(current_workspace),
                        }
                    end,
                },
            }
        })
    end,
}
