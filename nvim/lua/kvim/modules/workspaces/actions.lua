local M = {}

local storage = require("kvim.modules.workspaces.storage")
local state = require("kvim.modules.workspaces.state")
local config = require("kvim.modules.workspaces.config")

local function safe_buf_var(bufnr, varname)
    local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, varname)
    if not ok then
        return nil
    end

    return value
end

local function set_active_tab_role(role)
    if type(state.set_active_tab_role) == "function" then
        state.set_active_tab_role(role)
    end
end

local function get_buf_buftype(bufnr)
    local ok, buftype = pcall(vim.api.nvim_get_option_value, "buftype", { buf = bufnr })
    if not ok then
        return ""
    end

    return buftype
end

local function get_resession()
    local ok, resession = pcall(require, "resession")
    if not ok then
        return nil, "resession.nvim is not available"
    end

    return resession
end

local function derive_name_from_cwd()
    local cwd = vim.fn.getcwd()
    local name = vim.fn.fnamemodify(cwd, ":t")
    if not name or name == "" then
        return "workspace"
    end

    return name
end

local function build_workspace(name)
    local workspace_name = name
    if not workspace_name or workspace_name == "" then
        workspace_name = derive_name_from_cwd()
    end

    return {
        name = workspace_name,
        root = vim.fn.getcwd(),
        session = workspace_name,
        version = 1,
        layout = vim.deepcopy(config.get().layout),
        connections = {
            active = nil,
        },
        terminals = {},
        tasks = {},
    }
end

local function ensure_workspace_layout(workspace)
    workspace.layout = workspace.layout or {}
    workspace.layout.mode = workspace.layout.mode or "role_tabs"
    workspace.layout.tabs = workspace.layout.tabs or {
        { role = "code", title = "code" },
        { role = "term", title = "term" },
    }

    return workspace
end

local function get_current_tabnr()
    local ok, tabnr = pcall(vim.fn.tabpagenr)
    if not ok then
        return 1
    end

    return tabnr
end

local function goto_tabnr(tabnr)
    local ok = pcall(vim.cmd, "tabnext " .. tostring(tabnr))
    return ok
end

local function ensure_single_window_in_current_tab()
    pcall(vim.cmd, "silent! only")
end

local function refresh_bufferline()
    pcall(function()
        vim.cmd("redrawtabline")
    end)

    pcall(function()
        local bufferline = require("bufferline")
        if type(bufferline.refresh) == "function" then
            bufferline.refresh()
        end
    end)
end

local function ensure_role_tabs(workspace)
    state.clear_tab_roles()
    set_active_tab_role(nil)

    local tabs = (workspace.layout and workspace.layout.tabs) or {
        { role = "code", title = "code" },
        { role = "term", title = "term" },
    }

    local original_tabnr = get_current_tabnr()

    for index, tab in ipairs(tabs) do
        if index == 1 then
            goto_tabnr(1)
        else
            pcall(vim.cmd, "tabnew")
        end

        local tabnr = get_current_tabnr()
        state.set_tab_role(tabnr, tab.role or "term")
    end

    goto_tabnr(original_tabnr)
    local active_role = state.get_tab_role(original_tabnr)
    set_active_tab_role(active_role)
    refresh_bufferline()
end

local function ensure_role_tab(role)
    local tabnr = state.find_tab_by_role(role)
    if tabnr then
        return tabnr
    end

    pcall(vim.cmd, "tabnew")
    local new_tabnr = get_current_tabnr()
    state.set_tab_role(new_tabnr, role)
    refresh_bufferline()
    return new_tabnr
end

local function get_role_from_terminal_buffer(bufnr)
    local role = safe_buf_var(bufnr, "kvim_workspace_recipe_role")
    if type(role) == "string" and role ~= "" then
        return role
    end

    local winids = vim.fn.win_findbuf(bufnr)
    if type(winids) == "table" and #winids > 0 then
        local tabinfo = vim.fn.win_id2tabwin(winids[1])
        if type(tabinfo) == "table" then
            local tabnr = tabinfo[1]
            local tab_role = state.get_tab_role(tabnr)
            if tab_role and tab_role ~= "" then
                return tab_role
            end
        end
    end

    return "term"
end

local function get_current_workspace()
    local current = state.get_current()
    if not current then
        vim.notify("KVIM Workspaces: no active workspace", vim.log.levels.WARN)
        return nil
    end

    current.terminals = current.terminals or {}
    return current
end

local function goto_role_tab(role)
    local tabnr = state.find_tab_by_role(role)
    if not tabnr then
        return nil
    end

    local ok = pcall(vim.cmd, "tabnext " .. tostring(tabnr))
    if not ok then
        return nil
    end

    set_active_tab_role(role)

    return tabnr
end

local function resolve_connection_by_name(name)
    local cfg = config.get()
    if not (cfg.integrations and cfg.integrations.connections) then
        return nil, "connections integration disabled"
    end

    local ok_conn_config, conn_config = pcall(require, "kvim.modules.connections.config")
    if not ok_conn_config then
        return nil, "connections module not available"
    end

    local connections = conn_config.load({})
    for _, connection in ipairs(connections or {}) do
        if connection.name == name and connection.type == "ssh" then
            return connection
        end
    end

    return nil, "connection not found: " .. tostring(name)
end

local function parse_term_name(bufname)
    if type(bufname) ~= "string" or bufname == "" then
        return nil, nil
    end

    -- Ejemplo típico: term:///ruta/cwd//12345:comando --flag
    local cwd = bufname:match("^term://(.-)//%d+:")
    local command = bufname:match("^term://.-//%d+:(.+)$")

    return command, cwd
end

local function looks_like_ssh_command(command)
    if type(command) ~= "string" then
        return false
    end

    return command:match("^%s*ssh%s") ~= nil
end

local function resolve_connection_for_command(command)
    local cfg = config.get()
    if not (cfg.integrations and cfg.integrations.connections) then
        return nil
    end

    local ok_conn_config, conn_config = pcall(require, "kvim.modules.connections.config")
    if not ok_conn_config then
        return nil
    end

    local connections = conn_config.load({})
    for _, connection in ipairs(connections or {}) do
        if connection.type == "ssh" and connection.host then
            local target = connection.host
            if connection.user and connection.user ~= "" then
                target = connection.user .. "@" .. connection.host
            end

            if command:find(target, 1, true) then
                return connection.name
            end
        end
    end

    return nil
end

local function extract_terminal_recipe(bufnr, index)
    if get_buf_buftype(bufnr) ~= "terminal" then
        return nil, "not a terminal buffer"
    end

    local command = safe_buf_var(bufnr, "kvim_workspace_recipe_command")
    local cwd = safe_buf_var(bufnr, "kvim_workspace_recipe_cwd")
    local recipe_type = safe_buf_var(bufnr, "kvim_workspace_recipe_type")
    local recipe_connection = safe_buf_var(bufnr, "kvim_workspace_recipe_connection")
    local recipe_position = safe_buf_var(bufnr, "kvim_workspace_recipe_position")

    if type(command) ~= "string" or command == "" then
        local parsed_command, parsed_cwd = parse_term_name(vim.api.nvim_buf_get_name(bufnr))
        command = parsed_command
        cwd = cwd or parsed_cwd
    end

    if type(command) ~= "string" or command == "" then
        return nil, "no command"
    end

    local recipe = {
        name = "terminal-" .. tostring(index),
        command = command,
        cwd = cwd,
        position = recipe_position or "bottom",
        auto_restore = true,
        type = recipe_type or "shell",
        role = get_role_from_terminal_buffer(bufnr),
    }

    if recipe_connection and recipe_connection ~= "" then
        recipe.connection = recipe_connection
        recipe.type = "ssh"
    elseif recipe.type == "ssh" or looks_like_ssh_command(command) then
        recipe.type = "ssh"
        recipe.connection = resolve_connection_for_command(command)
    end

    return recipe
end

local function collect_open_terminals()
    local recipes = {}
    local stats = {
        detected = 0,
        saved = 0,
        skipped_no_command = 0,
        skipped_invalid = 0,
    }

    local buffers = vim.api.nvim_list_bufs()
    for _, bufnr in ipairs(buffers) do
        if vim.api.nvim_buf_is_valid(bufnr) and get_buf_buftype(bufnr) == "terminal" then
            stats.detected = stats.detected + 1

            local recipe, err = extract_terminal_recipe(bufnr, stats.detected)
            if recipe then
                table.insert(recipes, recipe)
                stats.saved = stats.saved + 1
            elseif err == "no command" then
                stats.skipped_no_command = stats.skipped_no_command + 1
            else
                stats.skipped_invalid = stats.skipped_invalid + 1
            end
        end
    end

    return recipes, stats
end

local function restore_shell_recipe(recipe)
    if type(recipe.command) ~= "string" or recipe.command == "" then
        return false, "shell recipe requires command"
    end

    local command = recipe.command
    if type(recipe.cwd) == "string" and recipe.cwd ~= "" then
        command = "cd " .. vim.fn.shellescape(recipe.cwd) .. " && " .. command
    end

    local terminal = require("kvim.core.terminal")
    terminal.open_command(command, {
        position = recipe.position or "bottom",
        name = recipe.name or "KVIM Workspace Terminal",
        listed = true,
        split = false,
        startinsert = false,
    })

    return true
end

local function restore_ssh_recipe(recipe)
    if recipe.connection and recipe.connection ~= "" then
        local connection, conn_err = resolve_connection_by_name(recipe.connection)
        if connection then
            local ok_actions, conn_actions = pcall(require, "kvim.modules.connections.actions")
            if not ok_actions then
                if type(recipe.command) == "string" and recipe.command ~= "" then
                    return restore_shell_recipe(recipe)
                end

                return nil, "connections actions not available"
            end

            conn_actions.open_connection(connection, { startinsert = false })
            return true
        end

        if type(recipe.command) == "string" and recipe.command ~= "" then
            return restore_shell_recipe(recipe)
        end

        return nil, conn_err
    end

    if type(recipe.command) == "string" and recipe.command ~= "" then
        return restore_shell_recipe(recipe)
    end

    return nil, "ssh recipe requires connection or command fallback"
end

local function restore_terminals(workspace)
    local terminals = workspace.terminals or {}
    local restored = 0
    local skipped = 0
    local failed = 0

    for _, recipe in ipairs(terminals) do
        if recipe.auto_restore == false then
            skipped = skipped + 1
        else
            local role = recipe.role or "term"
            local role_tab = ensure_role_tab(role)
            goto_tabnr(role_tab)

            if role == "term" then
                ensure_single_window_in_current_tab()
            end

            local ok, err
            if recipe.type == "shell" then
                ok, err = restore_shell_recipe(recipe)
            elseif recipe.type == "ssh" then
                ok, err = restore_ssh_recipe(recipe)
            else
                ok, err = nil, "unsupported recipe type: " .. tostring(recipe.type)
            end

            if ok then
                restored = restored + 1
            else
                failed = failed + 1
                vim.notify("KVIM Workspaces: terminal restore failed: " .. tostring(err), vim.log.levels.WARN)
            end
        end
    end

    vim.notify(
        "KVIM Workspaces: terminals restored=" .. restored .. " skipped=" .. skipped .. " failed=" .. failed,
        vim.log.levels.INFO
    )

    local code_tab = state.find_tab_by_role("code")
    if code_tab then
        goto_tabnr(code_tab)
        set_active_tab_role("code")
    end

    refresh_bufferline()
end

M.save_current = {
    callback = function(name)
        local current = state.get_current()
        if not current then
            vim.notify("KVIM Workspaces: no active workspace. Use :KvimWorkspaceCreate <name>", vim.log.levels.ERROR)
            return nil, "no active workspace"
        end

        local resession, resession_err = get_resession()
        if not resession then
            vim.notify("KVIM Workspaces: " .. resession_err, vim.log.levels.ERROR)
            return nil, resession_err
        end

        local workspace = build_workspace(name or current.name)
        workspace.name = current.name or workspace.name
        workspace.session = current.session or workspace.session
        workspace.layout = current.layout or workspace.layout
        ensure_workspace_layout(workspace)
        local terminals, terminal_stats = collect_open_terminals()
        workspace.terminals = terminals

        local ok_save, err_save = storage.save(workspace)
        if not ok_save then
            vim.notify("KVIM Workspaces: failed to save workspace: " .. tostring(err_save), vim.log.levels.ERROR)
            return nil, err_save
        end

        local ok_session, err_session = pcall(resession.save, workspace.session)
        if not ok_session then
            vim.notify("KVIM Workspaces: failed to save session: " .. tostring(err_session), vim.log.levels.ERROR)
            return nil, tostring(err_session)
        end

        state.set_current(workspace)
        vim.notify(
            "KVIM Workspaces: saved workspace '" .. workspace.name .. "' | terminals detected="
                .. tostring(terminal_stats.detected)
                .. " saved=" .. tostring(terminal_stats.saved)
                .. " skipped_no_command=" .. tostring(terminal_stats.skipped_no_command),
            vim.log.levels.INFO
        )
        return workspace
    end,
}

M.load = {
    callback = function(name)
        if not name or name == "" then
            vim.notify("KVIM Workspaces: workspace name is required", vim.log.levels.ERROR)
            return nil, "workspace name is required"
        end

        local resession, resession_err = get_resession()
        if not resession then
            vim.notify("KVIM Workspaces: " .. resession_err, vim.log.levels.ERROR)
            return nil, resession_err
        end

        local workspace, load_err = storage.load(name)
        if not workspace then
            vim.notify("KVIM Workspaces: failed to load workspace: " .. tostring(load_err), vim.log.levels.ERROR)
            return nil, load_err
        end

        ensure_workspace_layout(workspace)

        if workspace.root and workspace.root ~= "" and vim.fn.isdirectory(workspace.root) == 1 then
            vim.cmd("cd " .. vim.fn.fnameescape(workspace.root))
        end

        ensure_role_tabs(workspace)

        local session_name = workspace.session or workspace.name
        local ok_session, err_session = pcall(resession.load, session_name)
        if not ok_session then
            vim.notify("KVIM Workspaces: failed to load session: " .. tostring(err_session), vim.log.levels.ERROR)
            return nil, tostring(err_session)
        end

        state.set_current(workspace)

        local cfg = config.get()
        if cfg.restore_terminals_on_load then
            restore_terminals(workspace)
        end

        vim.notify("KVIM Workspaces: loaded workspace '" .. workspace.name .. "'", vim.log.levels.INFO)
        return workspace
    end,
}

M.create = {
    callback = function(name)
        if type(name) ~= "string" or name == "" then
            vim.notify("KVIM Workspaces: workspace name is required", vim.log.levels.ERROR)
            return nil, "workspace name is required"
        end

        local workspace = build_workspace(name)
        ensure_workspace_layout(workspace)

        ensure_role_tabs(workspace)
        local code_tab = state.find_tab_by_role("code")
        if code_tab then
            pcall(vim.cmd, "tabnext " .. tostring(code_tab))
            set_active_tab_role("code")
        end

        refresh_bufferline()

        local ok_save, err_save = storage.save(workspace)
        if not ok_save then
            vim.notify("KVIM Workspaces: failed to create workspace: " .. tostring(err_save), vim.log.levels.ERROR)
            return nil, err_save
        end

        local resession = select(1, get_resession())
        if resession then
            pcall(resession.save, workspace.session)
        end

        state.set_current(workspace)
        vim.notify("KVIM Workspaces: created workspace '" .. workspace.name .. "'", vim.log.levels.INFO)
        return workspace
    end,
}

M.list = {
    callback = function()
        local workspaces, err = storage.list()
        if not workspaces then
            vim.notify("KVIM Workspaces: failed to list workspaces: " .. tostring(err), vim.log.levels.ERROR)
            return nil, err
        end

        if #workspaces == 0 then
            vim.notify("KVIM Workspaces: no workspaces found", vim.log.levels.INFO)
            return workspaces
        end

        vim.ui.select(workspaces, {
            prompt = "Selecciona workspace para cargar",
        }, function(choice)
            if not choice or choice == "" then
                return
            end

            M.load.callback(choice)
        end)

        return workspaces
    end,
}

local function switch_workspace_by_offset(offset)
    local workspaces, err = storage.list()
    if not workspaces then
        vim.notify("KVIM Workspaces: failed to list workspaces: " .. tostring(err), vim.log.levels.ERROR)
        return nil, err
    end

    if #workspaces == 0 then
        vim.notify("KVIM Workspaces: no workspaces found", vim.log.levels.INFO)
        return nil, "no workspaces"
    end

    if #workspaces == 1 then
        return M.load.callback(workspaces[1])
    end

    local current = state.get_current()
    local current_name = current and current.name or nil
    local current_index = nil

    if current_name then
        for index, name in ipairs(workspaces) do
            if name == current_name then
                current_index = index
                break
            end
        end
    end

    if not current_index then
        current_index = 1
    end

    local target_index = ((current_index - 1 + offset) % #workspaces) + 1
    return M.load.callback(workspaces[target_index])
end

M.next = {
    callback = function()
        return switch_workspace_by_offset(1)
    end,
}

M.prev = {
    callback = function()
        return switch_workspace_by_offset(-1)
    end,
}

M.delete = {
    callback = function(name)
        if not name or name == "" then
            vim.notify("KVIM Workspaces: workspace name is required", vim.log.levels.ERROR)
            return nil, "workspace name is required"
        end

        local ok_delete, err_delete = storage.delete(name)
        if not ok_delete then
            vim.notify("KVIM Workspaces: failed to delete workspace: " .. tostring(err_delete), vim.log.levels.ERROR)
            return nil, err_delete
        end

        local current = state.get_current()
        if current and current.name == name then
            state.clear_current()
        end

        vim.notify("KVIM Workspaces: deleted workspace '" .. name .. "'", vim.log.levels.INFO)
        return true
    end,
}

M.current = {
    callback = function()
        local current = state.get_current()
        if not current then
            vim.notify("KVIM Workspaces: no active workspace", vim.log.levels.INFO)
            return nil
        end

        vim.notify("KVIM Workspaces: current workspace '" .. current.name .. "'", vim.log.levels.INFO)
        return current
    end,
}

M.terminal_add = {
    callback = function(recipe)
        local workspace = get_current_workspace()
        if not workspace then
            return nil, "no active workspace"
        end

        if type(recipe) ~= "table" then
            return nil, "recipe must be a table"
        end

        if type(recipe.name) ~= "string" or recipe.name == "" then
            return nil, "recipe.name is required"
        end

        if recipe.type ~= "shell" and recipe.type ~= "ssh" then
            return nil, "recipe.type must be 'shell' or 'ssh'"
        end

        workspace.terminals = workspace.terminals or {}
        recipe.role = recipe.role or state.get_tab_role(get_current_tabnr()) or "term"
        table.insert(workspace.terminals, recipe)

        local ok_save, err_save = storage.save(workspace)
        if not ok_save then
            return nil, err_save
        end

        state.set_current(workspace)
        vim.notify("KVIM Workspaces: terminal recipe added: " .. recipe.name, vim.log.levels.INFO)
        return workspace
    end,
}

M.terminal_list = {
    callback = function()
        local workspace = get_current_workspace()
        if not workspace then
            return nil, "no active workspace"
        end

        local terminals = workspace.terminals or {}
        if #terminals == 0 then
            vim.notify("KVIM Workspaces: no terminal recipes", vim.log.levels.INFO)
            return terminals
        end

        local names = {}
        for _, recipe in ipairs(terminals) do
            table.insert(names, recipe.name .. "(" .. tostring(recipe.type) .. ")")
        end

        vim.notify("KVIM Workspaces: " .. table.concat(names, ", "), vim.log.levels.INFO)
        return terminals
    end,
}

M.terminal_remove = {
    callback = function(name)
        local workspace = get_current_workspace()
        if not workspace then
            return nil, "no active workspace"
        end

        if type(name) ~= "string" or name == "" then
            return nil, "recipe name is required"
        end

        workspace.terminals = workspace.terminals or {}
        local index = nil
        for i, recipe in ipairs(workspace.terminals) do
            if recipe.name == name then
                index = i
                break
            end
        end

        if not index then
            return nil, "recipe not found: " .. name
        end

        table.remove(workspace.terminals, index)

        local ok_save, err_save = storage.save(workspace)
        if not ok_save then
            return nil, err_save
        end

        state.set_current(workspace)
        vim.notify("KVIM Workspaces: terminal recipe removed: " .. name, vim.log.levels.INFO)
        return workspace
    end,
}

M.terminal_restore = {
    callback = function()
        local workspace = get_current_workspace()
        if not workspace then
            return nil, "no active workspace"
        end

        restore_terminals(workspace)
        return true
    end,
}

M.goto_code_tab = {
    callback = function()
        local tabnr = state.find_tab_by_role("code")
        if not tabnr then
            local workspace = state.get_current()
            if workspace then
                ensure_workspace_layout(workspace)
                ensure_role_tabs(workspace)
                tabnr = state.find_tab_by_role("code")
            end
        end

        if not tabnr then
            vim.notify("KVIM Workspaces: code tab not found", vim.log.levels.WARN)
            return nil
        end

        goto_role_tab("code")
        refresh_bufferline()
        return true
    end,
}

M.goto_term_tab = {
    callback = function()
        local tabnr = state.find_tab_by_role("term")
        if not tabnr then
            local workspace = state.get_current()
            if workspace then
                ensure_workspace_layout(workspace)
                ensure_role_tabs(workspace)
                tabnr = state.find_tab_by_role("term")
            end
        end

        if not tabnr then
            vim.notify("KVIM Workspaces: term tab not found", vim.log.levels.WARN)
            return nil
        end

        goto_role_tab("term")
        refresh_bufferline()
        return true
    end,
}

return M
