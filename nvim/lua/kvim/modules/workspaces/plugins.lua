return {
    {
        "stevearc/resession.nvim",
        config = function()
            local ok, resession = pcall(require, "resession")
            if not ok then
                vim.notify("KVIM Workspaces: resession.nvim no disponible", vim.log.levels.WARN)
                return
            end

            resession.setup({
                autosave = {
                    enabled = false,
                },
            })
        end,
    },

    {
        "akinsho/bufferline.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        opts = function()
            vim.opt.showtabline = 2

            local sync_group = vim.api.nvim_create_augroup("KvimWorkspaceTabRoleSync", { clear = true })
            vim.api.nvim_create_autocmd("TabEnter", {
                group = sync_group,
                callback = function()
                    local ok_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
                    if not ok_state then
                        return
                    end

                    local role = ws_state.get_tab_role(vim.fn.tabpagenr())
                    ws_state.set_active_tab_role(role)
                    pcall(vim.cmd, "redrawtabline")

                    if role ~= "term" then
                        return
                    end

                    local ok_ft, ft = pcall(vim.api.nvim_get_option_value, "filetype", { buf = 0 })
                    if not ok_ft or ft ~= "neo-tree" then
                        return
                    end

                    vim.schedule(function()
                        local ok_actions, ws_actions = pcall(require, "kvim.modules.workspaces.actions")
                        if ok_actions and ws_actions.goto_term_tab and type(ws_actions.goto_term_tab.callback) == "function" then
                            ws_actions.goto_term_tab.callback()
                        end
                    end)
                end,
            })

            vim.api.nvim_create_autocmd("FileType", {
                group = sync_group,
                pattern = "neo-tree",
                callback = function()
                    local ok_actions, ws_actions = pcall(require, "kvim.modules.workspaces.actions")
                    if not ok_actions or not ws_actions.handle_explorer_opened_in_term or type(ws_actions.handle_explorer_opened_in_term.callback) ~= "function" then
                        return
                    end

                    ws_actions.handle_explorer_opened_in_term.callback()
                end,
            })

            local function resolve_hl(name, fallback)
                local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
                if not ok or type(hl) ~= "table" then
                    return fallback
                end

                local fg = hl.fg and string.format("#%06x", hl.fg) or fallback.fg
                local bg = hl.bg and string.format("#%06x", hl.bg) or fallback.bg
                return { fg = fg, bg = bg }
            end

            local function role_label(role)
                if role == "code" then
                    return "󰈔 Code"
                end

                if role == "term" then
                    return " Term"
                end

                if type(role) == "string" and role ~= "" then
                    return role:sub(1, 1):upper() .. role:sub(2)
                end

                return nil
            end

            local function tab_badge(text, is_current)
                local selected = resolve_hl("TabLineSel", { fg = "#1e1e2e", bg = "#89b4fa" })
                local normal = resolve_hl("TabLine", { fg = "#a6adc8", bg = "#1e1e2e" })
                local style = is_current
                    and { fg = selected.fg, bg = selected.bg, bold = true, italic = true }
                    or { fg = normal.fg, bg = normal.bg, bold = false, italic = false }

                return {
                    text = " " .. text .. " ",
                    fg = style.fg,
                    bg = style.bg,
                    bold = style.bold,
                    italic = style.italic,
                }
            end

            return {
                options = {
                    mode = "buffers",
                    custom_filter = function(bufnr)
                        local ok_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
                        if not ok_state then
                            return true
                        end

                        local current_tabnr = vim.fn.tabpagenr()
                        local role = ws_state.get_tab_role(current_tabnr)
                        if role ~= "code" and role ~= "term" then
                            return true
                        end

                        local ok_buftype, buftype = pcall(vim.api.nvim_get_option_value, "buftype", { buf = bufnr })
                        if not ok_buftype then
                            return true
                        end

                        local is_terminal = (buftype == "terminal")
                        if role == "term" then
                            return is_terminal
                        end

                        return not is_terminal
                    end,
                    numbers = "none",
                    show_close_icon = false,
                    show_buffer_close_icons = false,
                    show_tab_indicators = false,
                    indicator = {
                        style = "none",
                    },
                    separator_style = "slant",
                    custom_areas = {
                        right = function()
                            local ok_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
                            if not ok_state then
                                return {}
                            end

                            local roles = ws_state.get_all_tab_roles()
                            if type(roles) ~= "table" or vim.tbl_isempty(roles) then
                                return {}
                            end

                            local active_role = ws_state.get_active_tab_role()
                            local current_tabnr = vim.fn.tabpagenr()
                            local ordered_tabnrs = {}
                            for tabnr, _ in pairs(roles) do
                                table.insert(ordered_tabnrs, tabnr)
                            end
                            table.sort(ordered_tabnrs)

                            local out = {}
                            for _, tabnr in ipairs(ordered_tabnrs) do
                                local label = role_label(roles[tabnr])
                                if label then
                                    local is_current = false
                                    if type(active_role) == "string" and active_role ~= "" then
                                        is_current = (roles[tabnr] == active_role)
                                    else
                                        is_current = (tabnr == current_tabnr)
                                    end
                                    table.insert(out, tab_badge(label, is_current))
                                end
                            end

                            return out
                        end,
                    },
                },
            }
        end,
    },
}
