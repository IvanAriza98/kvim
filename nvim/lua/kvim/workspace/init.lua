-- =============================================================================
-- Workspace: Sistema de Tres Ambientes
-- =============================================================================
-- Este módulo gestiona tres tabs completamente separados:
--   - Code: entorno de programación
--   - SSH: conexiones a dispositivos remotos
--   - AI: entorno asistido con opencode

local M = {}

local state = {
    code_tab = nil,
    ssh_tab = nil,
    ai_tab = nil,
    ssh_initialized = false,
    ai_initialized = false,
    setup_done = false,
    keymaps_done = false,
    autocmds_done = false,
    syncing = false,
    is_exiting = false,
}

local excluded_buftypes = {
    terminal = true,
    help = true,
    nofile = true,
    prompt = true,
    quickfix = true,
}

local augroup = vim.api.nvim_create_augroup("KvimWorkspace", { clear = true })
local code_projects_cache = nil

local function get_code_projects()
    if code_projects_cache then
        return code_projects_cache
    end

    local ok, mod = pcall(require, "kvim.workspace.code-projects")
    if not ok then
        return nil
    end

    code_projects_cache = mod
    return code_projects_cache
end

-- =============================================================================
-- Helpers internos
-- =============================================================================

local function is_valid_tab(tab)
    return tab ~= nil and vim.api.nvim_tabpage_is_valid(tab)
end

local function get_tab_title(tab)
    local ok, title = pcall(vim.api.nvim_tabpage_get_var, tab, "title")
    if ok then
        return title
    end
    return nil
end

local function set_tab_title(tab, title)
    if is_valid_tab(tab) then
        vim.api.nvim_tabpage_set_var(tab, "title", title)
    end
end

local function move_tab_to(tab, position)
    if not is_valid_tab(tab) then
        return
    end

    local current = vim.api.nvim_get_current_tabpage()
    vim.api.nvim_set_current_tabpage(tab)
    vim.cmd("tabmove " .. position)

    if is_valid_tab(current) then
        vim.api.nvim_set_current_tabpage(current)
    end
end

local function find_tab_by_title(title)
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        if get_tab_title(tab) == title then
            return tab
        end
    end
    return nil
end

local function resolve_workspace_tabs()
    -- Estrategia mixta:
    -- 1. Si ya tenemos tabs válidos, usarlos.
    -- 2. Intentar encontrar por título.
    -- 3. Fallback: usar por posición (1=Code, 2=SSH, 3=AI).

    local tabs = vim.api.nvim_list_tabpages()
    local num_tabs = #tabs

    -- Si las referencias quedaron cruzadas, corregir.
    if is_valid_tab(state.code_tab) and get_tab_title(state.code_tab) == "SSH"
        and is_valid_tab(state.ssh_tab) and get_tab_title(state.ssh_tab) == "Code" then
        state.code_tab, state.ssh_tab = state.ssh_tab, state.code_tab
    end

    if not is_valid_tab(state.code_tab) then
        local found = find_tab_by_title("Code")
        if is_valid_tab(found) then
            state.code_tab = found
        elseif num_tabs >= 1 then
            -- Primer tab = Code
            state.code_tab = tabs[1]
        end
    end

    if not is_valid_tab(state.ssh_tab) then
        local found = find_tab_by_title("SSH")
        if is_valid_tab(found) then
            state.ssh_tab = found
        elseif num_tabs >= 2 then
            -- Segundo tab = SSH
            state.ssh_tab = tabs[2]
        end
    end

    if not is_valid_tab(state.ai_tab) then
        local found = find_tab_by_title("AI")
        if is_valid_tab(found) then
            state.ai_tab = found
        elseif num_tabs >= 3 then
            -- Tercer tab = AI
            state.ai_tab = tabs[3]
        end
    end

    -- Si existen tabs titulados, priorizarlos sobre referencias antiguas.
    local titled_code = find_tab_by_title("Code")
    if is_valid_tab(titled_code) then
        state.code_tab = titled_code
    end

    local titled_ssh = find_tab_by_title("SSH")
    if is_valid_tab(titled_ssh) then
        state.ssh_tab = titled_ssh
        state.ssh_initialized = true
    end

    local titled_ai = find_tab_by_title("AI")
    if is_valid_tab(titled_ai) then
        state.ai_tab = titled_ai
        state.ai_initialized = true
    end

    -- Verificar que Code y SSH no apunten al mismo
    if is_valid_tab(state.code_tab) and is_valid_tab(state.ssh_tab) and state.code_tab == state.ssh_tab then
        state.ssh_tab = nil
    end

    -- Verificar que AI no apunte al mismo tab que Code/SSH
    if is_valid_tab(state.ai_tab) and is_valid_tab(state.code_tab) and state.ai_tab == state.code_tab then
        state.ai_tab = nil
    end
    if is_valid_tab(state.ai_tab) and is_valid_tab(state.ssh_tab) and state.ai_tab == state.ssh_tab then
        state.ai_tab = nil
    end
end

local function mark_code_buffer(bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    if not M.is_code_workspace() then
        return
    end

    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if excluded_buftypes[buftype] then
        return
    end

    -- Asegurar visibilidad en bufferline para buffers de código.
    vim.api.nvim_set_option_value("buflisted", true, { buf = bufnr })
    vim.b[bufnr].kvim_workspace = "code"
end

local function is_valid_ssh_buffer(bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    return vim.b[bufnr].kvim_workspace == "ssh"
end

local function mark_ai_buffer(bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    if not M.is_ai_workspace() then
        return
    end

    -- Ocultar buffers de AI en bufferline, pero mantener su etiqueta de workspace.
    vim.api.nvim_set_option_value("buflisted", false, { buf = bufnr })
    vim.b[bufnr].kvim_workspace = "ai"
end

local function ensure_ai_workspace_runtime()
    local ok, opencode = pcall(require, "opencode")
    if ok and opencode and type(opencode.start) == "function" then
        pcall(opencode.start)
    end

    -- Esperar al próximo tick para que opencode tenga tiempo de abrir su terminal.
    local ai_tab = vim.api.nvim_get_current_tabpage()
    vim.schedule(function()
        if not is_valid_tab(ai_tab) then
            return
        end

        -- Si el usuario ya salió de AI, no tocar foco/ventanas.
        local current_tab = vim.api.nvim_get_current_tabpage()
        if current_tab ~= ai_tab then
            return
        end

        local wins = vim.api.nvim_tabpage_list_wins(ai_tab)
        local terminal_win = nil

        for _, win in ipairs(wins) do
            if vim.api.nvim_win_is_valid(win) then
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_is_valid(buf) then
                    local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
                    if buftype == "terminal" then
                        terminal_win = terminal_win or win
                    end
                end
            end
        end

        -- Si no hay terminal todavía, salir silenciosamente.
        if not terminal_win then
            return
        end

        -- Conservar una sola ventana (la primera terminal) y cerrar el resto.
        for _, win in ipairs(wins) do
            if win ~= terminal_win and vim.api.nvim_win_is_valid(win) then
                pcall(vim.api.nvim_win_close, win, true)
            end
        end

        -- Foco en la terminal principal y etiquetado del buffer AI (solo dentro de AI).
        if vim.api.nvim_win_is_valid(terminal_win) then
            if vim.api.nvim_get_current_tabpage() == ai_tab and vim.api.nvim_get_current_win() ~= terminal_win then
                pcall(vim.api.nvim_set_current_win, terminal_win)
            end
            mark_ai_buffer(vim.api.nvim_win_get_buf(terminal_win))
        end
    end)
end

local function ensure_workspace_tabs(opts)
    opts = opts or {}

    if state.syncing then
        return
    end

    state.syncing = true
    local current_tab = vim.api.nvim_get_current_tabpage()
    local ensure_ai = opts.ensure_ai == true or state.ai_initialized
    local ensure_ssh = opts.ensure_ssh == true or state.ssh_initialized or ensure_ai

    resolve_workspace_tabs()

    local tabs = vim.api.nvim_list_tabpages()
    if not is_valid_tab(state.code_tab) then
        state.code_tab = tabs[1]
    end

    -- Si Code y SSH apuntan al mismo tab (ej: se cerró Code), recrear Code.
    if is_valid_tab(state.code_tab) and is_valid_tab(state.ssh_tab) and state.code_tab == state.ssh_tab then
        vim.cmd("tabnew")
        state.code_tab = vim.api.nvim_get_current_tabpage()
    end

    if ensure_ssh and not is_valid_tab(state.ssh_tab) then
        vim.cmd("tabnew")
        state.ssh_tab = vim.api.nvim_get_current_tabpage()
        state.ssh_initialized = true

        -- El tab SSH no debe contaminar la bufferline principal.
        local ssh_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_option(ssh_buf, "buflisted", false)
    end

    if ensure_ai and not is_valid_tab(state.ai_tab) then
        vim.cmd("tabnew")
        state.ai_tab = vim.api.nvim_get_current_tabpage()
        state.ai_initialized = true

        -- El tab AI arranca oculto de bufferline hasta que opencode abra su terminal.
        local ai_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_set_option_value("buflisted", false, { buf = ai_buf })
    end

    set_tab_title(state.code_tab, "Code")
    if ensure_ssh and is_valid_tab(state.ssh_tab) then
        set_tab_title(state.ssh_tab, "SSH")
    end
    if ensure_ai and is_valid_tab(state.ai_tab) then
        set_tab_title(state.ai_tab, "AI")
    end

    -- Mantener orden canónico: tab 1 = Code, tab 2 = SSH, tab 3 = AI.
    move_tab_to(state.code_tab, 0)
    if ensure_ssh and is_valid_tab(state.ssh_tab) then
        move_tab_to(state.ssh_tab, 1)
    end
    if ensure_ai and is_valid_tab(state.ai_tab) then
        move_tab_to(state.ai_tab, 2)
    end

    if is_valid_tab(current_tab) then
        vim.api.nvim_set_current_tabpage(current_tab)
    else
        vim.api.nvim_set_current_tabpage(state.code_tab)
    end

    state.syncing = false
end

local function setup_keymaps()
    if state.keymaps_done then
        return
    end

    vim.keymap.set("n", "<leader>1", function()
        M.goto_code()
        vim.notify("dev", vim.log.levels.INFO)
    end, { noremap = true, silent = true, desc = "Go to dev environment" })

    vim.keymap.set("n", "<leader>2", function()
        M.goto_ssh()
        vim.notify("prod", vim.log.levels.INFO)
    end, { noremap = true, silent = true, desc = "Go to remote environment" })

    vim.keymap.set("n", "<leader>3", function()
        M.goto_ai()
        vim.notify("ai", vim.log.levels.INFO)
    end, { noremap = true, silent = true, desc = "Go to AI environment" })

    vim.keymap.set("n", "<leader><Tab>", function()
        if M.is_code_workspace() then
            M.goto_ssh()
            vim.notify("prod", vim.log.levels.INFO)
        elseif M.is_ssh_workspace() then
            M.goto_ai()
            vim.notify("ai", vim.log.levels.INFO)
        else
            M.goto_code()
            vim.notify("dev", vim.log.levels.INFO)
        end
    end, { noremap = true, silent = true, desc = "Cycle environment" })

    vim.keymap.set("n", "<leader>h", function()
        if M.is_code_workspace() then
            M.goto_ssh()
        end
    end, { noremap = true, silent = true, desc = "Go to remote environment" })

    vim.keymap.set("n", "<leader>l", function()
        if M.is_ssh_workspace() then
            M.goto_code()
        end
    end, { noremap = true, silent = true, desc = "Go to dev environment" })

    vim.keymap.set("n", "<leader>p", function()
        if not M.is_code_workspace() then
            M.goto_code()
        end

        local code_projects = get_code_projects()
        if code_projects and type(code_projects.show_project_picker) == "function" then
            pcall(code_projects.show_project_picker)
        end
    end, { noremap = true, silent = true, desc = "Show Code project picker" })

    vim.keymap.set("n", "<leader>n", function()
        if not M.is_code_workspace() then
            M.goto_code()
        end

        local code_projects = get_code_projects()
        if code_projects and type(code_projects.next_project) == "function" then
            pcall(code_projects.next_project)
        end
    end, { noremap = true, silent = true, desc = "Go to next Code project" })

    vim.keymap.set("n", "<leader>b", function()
        if not M.is_code_workspace() then
            M.goto_code()
        end

        local code_projects = get_code_projects()
        if code_projects and type(code_projects.prev_project) == "function" then
            pcall(code_projects.prev_project)
        end
    end, { noremap = true, silent = true, desc = "Go to previous Code project" })

    state.keymaps_done = true
end

local function setup_autocmds()
    if state.autocmds_done then
        return
    end

    vim.api.nvim_create_autocmd({ "VimEnter", "TabNewEntered", "TabEnter" }, {
        group = augroup,
        callback = function()
            ensure_workspace_tabs()

            local current_buf = vim.api.nvim_get_current_buf()
            if M.is_ssh_workspace() then
                local ok, ssh_manager = pcall(require, "kvim.workspace.ssh-manager")
                if ok and ssh_manager and type(ssh_manager.ensure_session_buffers) == "function" then
                    pcall(ssh_manager.ensure_session_buffers)
                end

                if not is_valid_ssh_buffer(current_buf) then
                    if ok and ssh_manager and type(ssh_manager.ensure_active_session) == "function" then
                        pcall(ssh_manager.ensure_active_session)
                    end
                else
                    if ok and ssh_manager and type(ssh_manager.on_buffer_enter) == "function" then
                        pcall(ssh_manager.on_buffer_enter, current_buf)
                    end
                end
                return
            end

            if M.is_ai_workspace() then
                ensure_ai_workspace_runtime()
                return
            end

            mark_code_buffer(current_buf)

            local code_projects = get_code_projects()
            if code_projects and type(code_projects.get_active_project_id) == "function"
                and type(code_projects.switch_project) == "function" then
                local active_id = code_projects.get_active_project_id()
                if active_id then
                    pcall(code_projects.switch_project, active_id)
                end
            end

            if code_projects and type(code_projects.on_buffer_enter) == "function" then
                pcall(code_projects.on_buffer_enter, current_buf)
            end
        end,
        desc = "Keep Code/SSH/AI workspace tabs stable",
    })

    vim.api.nvim_create_autocmd("TabClosed", {
        group = augroup,
        callback = function()
            if state.is_exiting then
                return
            end
            vim.schedule(ensure_workspace_tabs)
        end,
        desc = "Restore missing Code/SSH/AI workspace tabs",
    })

    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = augroup,
        callback = function()
            state.is_exiting = true
        end,
        desc = "Avoid recreating workspace tabs while exiting",
    })

    vim.api.nvim_create_autocmd("TabEnter", {
        group = augroup,
        callback = function()
            if M.is_ai_workspace() then
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_set_option_value("number", false, { scope = "local", win = win })
                        vim.api.nvim_set_option_value("relativenumber", false, { scope = "local", win = win })
                    end
                end
            end
        end,
        desc = "Disable line numbers in AI workspace",
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        group = augroup,
        callback = function(args)
            if M.is_ssh_workspace() then
                local ok, ssh_manager = pcall(require, "kvim.workspace.ssh-manager")
                if ok and ssh_manager and type(ssh_manager.on_buffer_enter) == "function" then
                    pcall(ssh_manager.on_buffer_enter, args.buf)
                end
                return
            end

            if M.is_ai_workspace() then
                mark_ai_buffer(args.buf)
                return
            end

            mark_code_buffer(args.buf)

            local code_projects = get_code_projects()
            if code_projects and type(code_projects.on_buffer_enter) == "function" then
                pcall(code_projects.on_buffer_enter, args.buf)
            end
        end,
        desc = "Tag Code/AI buffers and handle SSH lazy-connect",
    })

    state.autocmds_done = true
end

-- =============================================================================
-- API pública
-- =============================================================================

function M.setup()
    if state.setup_done then
        ensure_workspace_tabs()
        return
    end

    local code_projects = get_code_projects()
    if code_projects and type(code_projects.setup) == "function" then
        pcall(code_projects.setup)
    end

    setup_keymaps()
    setup_autocmds()
    ensure_workspace_tabs()
    mark_code_buffer(vim.api.nvim_get_current_buf())

    if code_projects and type(code_projects.on_buffer_enter) == "function" then
        pcall(code_projects.on_buffer_enter, vim.api.nvim_get_current_buf())
    end

    state.setup_done = true
end

function M.goto_code()
    ensure_workspace_tabs()
    local code_tab = find_tab_by_title("Code")
    if is_valid_tab(code_tab) then
        state.code_tab = code_tab
    end
    vim.api.nvim_set_current_tabpage(state.code_tab)

    local code_projects = get_code_projects()
    if code_projects and type(code_projects.get_active_project_id) == "function"
        and type(code_projects.switch_project) == "function" then
        local active_id = code_projects.get_active_project_id()
        if active_id then
            pcall(code_projects.switch_project, active_id)
        end
    end
end

function M.goto_ssh()
    state.ssh_initialized = true
    ensure_workspace_tabs({ ensure_ssh = true })
    local ssh_tab = find_tab_by_title("SSH")
    if is_valid_tab(ssh_tab) then
        state.ssh_tab = ssh_tab
    end
    vim.api.nvim_set_current_tabpage(state.ssh_tab)
end

function M.goto_ai()
    state.ai_initialized = true
    ensure_workspace_tabs({ ensure_ai = true })
    local ai_tab = find_tab_by_title("AI")
    if is_valid_tab(ai_tab) then
        state.ai_tab = ai_tab
    end
    vim.api.nvim_set_current_tabpage(state.ai_tab)
    ensure_ai_workspace_runtime()
end

function M.get_current_workspace()
    local current = vim.api.nvim_get_current_tabpage()

    -- Fuente principal: título del tab actual.
    local title = get_tab_title(current)
    if title == "Code" then
        return "code"
    end
    if title == "SSH" then
        return "ssh"
    end
    if title == "AI" then
        return "ai"
    end

    -- Fallback: resolver por referencias internas.
    resolve_workspace_tabs()

    if current == state.code_tab then
        return "code"
    end
    if current == state.ssh_tab then
        return "ssh"
    end
    if current == state.ai_tab then
        return "ai"
    end

    return "unknown"
end

function M.is_code_workspace()
    return M.get_current_workspace() == "code"
end

function M.is_ssh_workspace()
    return M.get_current_workspace() == "ssh"
end

function M.is_ai_workspace()
    return M.get_current_workspace() == "ai"
end

function M.mark_code_buffer_if_applicable(bufnr)
    mark_code_buffer(bufnr or vim.api.nvim_get_current_buf())
end

return M
