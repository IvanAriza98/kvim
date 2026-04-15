-- =============================================================================
-- SSH Manager: Gestor de Terminales SSH en Tab 2
-- =============================================================================
-- Este módulo gestiona conexiones SSH en el workspace SSH (Tab 2).
-- Usa :term nativo (no toggleterm) para crear buffers separados.
-- Cada sesión SSH tiene su propio buffer y estado asociado.
-- Flujo actual:
--   1) Se crean buffers placeholder por sesión (sin conectar).
--   2) Al entrar en un buffer SSH, se conecta on-demand con termopen().
--   3) El índice de sesión activa se sincroniza desde el buffer visible.

local M = {}

local config_utils = require("kvim.utils.config-utils")
local workspace = require("kvim.workspace")

-- Tabla para almacenar buffers SSH por índice de sesión.
-- key: session index, value: bufnr
local ssh_buffers = {}
local ensuring_active = false
local handling_buf_enter = false

local augroup = vim.api.nvim_create_augroup("KvimSshManager", { clear = true })

-- =============================================================================
-- Funciones de Conexión SSH
-- =============================================================================

-- Función para obtener el nombre del buffer SSH
-- @param session table La sesión SSH
-- @return string Nombre del buffer
local function get_buffer_name(session)
    local user = session.user or "unknown"
    local ip = session.ip or "unknown"
    return "ssh://" .. user .. "@" .. ip
end

-- Función para verificar si un buffer SSH existe y está vivo
-- @param bufnr number Número de buffer
-- @return boolean
local function buffer_exists(bufnr)
    if not bufnr or bufnr == 0 then
        return false
    end
    return vim.api.nvim_buf_is_valid(bufnr)
end

local function is_ssh_buffer(bufnr)
    if not buffer_exists(bufnr) then
        return false
    end
    return vim.b[bufnr].kvim_workspace == "ssh"
end

local function is_ssh_connected(bufnr)
    if not buffer_exists(bufnr) then
        return false
    end

    if vim.b[bufnr].kvim_ssh_connected == true then
        return true
    end

    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    return buftype == "terminal"
end

-- Función para obtener la sesión SSH activa
-- @return table|nil La sesión activa o nil
local function get_active_session()
    local active_idx = config_utils.getActiveSSH()
    if not active_idx then
        return nil
    end

    local sessions = config_utils.getSSHSessions()
    if not sessions or not sessions[active_idx] then
        return nil
    end

    return sessions[active_idx]
end

local function get_session(session_index)
    local sessions = config_utils.getSSHSessions()
    if not sessions or not sessions[session_index] then
        return nil
    end
    return sessions[session_index]
end

local function set_buffer_metadata(bufnr, session_index, connected)
    vim.api.nvim_set_option_value("buflisted", true, { buf = bufnr })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
    vim.b[bufnr].kvim_workspace = "ssh"
    vim.b[bufnr].kvim_ssh_session_index = session_index
    vim.b[bufnr].kvim_ssh_connected = connected and true or false
end

local function render_placeholder(bufnr, session)
    if not buffer_exists(bufnr) then
        return
    end

    local user = session.user or ""
    local ip = session.ip or ""
    local port = tostring(session.port or "22")
    local name = session.name or ip or "SSH"

    local lines = {
        "KVIM SSH placeholder",
        "",
        "Session: " .. name,
        "Target : " .. ((user ~= "") and (user .. "@" .. ip) or ip),
        "Port   : " .. port,
        "",
        "La conexión se iniciará al entrar en este buffer.",
    }

    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

local function create_placeholder_buffer(session_index, session)
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(bufnr, get_buffer_name(session))
    vim.api.nvim_set_option_value("buflisted", true, { buf = bufnr })
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
    set_buffer_metadata(bufnr, session_index, false)
    render_placeholder(bufnr, session)
    return bufnr
end

local function ensure_session_buffer(session_index, session)
    local existing = ssh_buffers[session_index]
    if existing and buffer_exists(existing) then
        set_buffer_metadata(existing, session_index, is_ssh_connected(existing))
        -- Si el usuario cambió nombre/ip/user, refrescar nombre para trazabilidad.
        local wanted_name = get_buffer_name(session)
        if vim.api.nvim_buf_get_name(existing) ~= wanted_name then
            pcall(vim.api.nvim_buf_set_name, existing, wanted_name)
        end
        return existing
    end

    local bufnr = create_placeholder_buffer(session_index, session)
    ssh_buffers[session_index] = bufnr
    return bufnr
end

local function open_session_buffer(session_index)
    local session = get_session(session_index)
    if not session then
        vim.notify("SSH: Sesión no encontrada", vim.log.levels.ERROR)
        return nil
    end

    local bufnr = ensure_session_buffer(session_index, session)
    workspace.goto_ssh()
    vim.api.nvim_win_set_buf(0, bufnr)
    set_buffer_metadata(bufnr, session_index, is_ssh_connected(bufnr))
    return bufnr
end

-- Función para crear una terminal SSH en un buffer
-- @param session table La sesión SSH
-- @param session_index number Índice de sesión (1-based)
-- @return number|nil El número de buffer conectado
local function connect_session_buffer(session, session_index)
    local user = session.user or ""
    local ip = session.ip or ""
    local port = session.port or "22"

    if not ip or ip == "" then
        vim.notify("SSH: IP no definida", vim.log.levels.ERROR)
        return nil
    end

    local buf_name = get_buffer_name(session)
    local destination = (user and user ~= "") and (user .. "@" .. ip) or ip
    local cmd = string.format("ssh -p %s %s", port, destination)

    local bufnr = open_session_buffer(session_index)
    if not bufnr or not buffer_exists(bufnr) then
        return nil
    end

    -- Si ya está conectado, no reconectar.
    if is_ssh_connected(bufnr) then
        return bufnr
    end

    -- Si el buffer ya es terminal previo, crear uno nuevo para reconectar limpio.
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if buftype == "terminal" then
        bufnr = create_placeholder_buffer(session_index, session)
        ssh_buffers[session_index] = bufnr
        workspace.goto_ssh()
        vim.api.nvim_win_set_buf(0, bufnr)
    end

    -- Preparar buffer placeholder para convertirlo a terminal limpia.
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    vim.api.nvim_set_option_value("readonly", false, { buf = bufnr })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    vim.api.nvim_set_option_value("modified", false, { buf = bufnr })

    -- Abrir terminal nativa en el buffer actual
    local job_id = vim.fn.termopen(cmd, {
        on_stdout = function()
        end,
        on_stderr = function()
        end,
        on_exit = function()
            if buffer_exists(bufnr) then
                vim.b[bufnr].kvim_ssh_connected = false
            end
        end,
    })

    if job_id and job_id > 0 then
        set_buffer_metadata(bufnr, session_index, true)
        vim.b[bufnr].kvim_ssh_job_id = job_id
        pcall(vim.api.nvim_buf_set_name, bufnr, buf_name)
        -- termopen puede resetear opciones del buffer; re-aplicar.
        vim.api.nvim_set_option_value("buflisted", true, { buf = bufnr })
        vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
    end

    -- Ir a modo insert en la terminal
    vim.cmd("startinsert")

    return bufnr
end

-- =============================================================================
-- API Pública
-- =============================================================================

-- Crea (si faltan) los buffers placeholder de todas las sesiones.
function M.ensure_session_buffers()
    local sessions = config_utils.getSSHSessions()
    if not sessions or #sessions == 0 then
        return
    end

    for i, session in ipairs(sessions) do
        ensure_session_buffer(i, session)
    end
end

-- Conectar a la sesión SSH activa
function M.connect()
    local session = get_active_session()
    if not session then
        vim.notify("SSH: No hay sesión activa. Selecciona una primero.", vim.log.levels.WARN)
        return
    end

    local active_idx = config_utils.getActiveSSH()
    if not active_idx then
        vim.notify("SSH: No hay sesión activa.", vim.log.levels.WARN)
        return
    end

    local bufnr = connect_session_buffer(session, active_idx)
    if bufnr then
        ssh_buffers[active_idx] = bufnr
        vim.notify("SSH: Conectado a " .. (session.ip or "?"), vim.log.levels.INFO)
    end
end

-- Asegura que la sesión activa esté visible en el workspace SSH.
-- Reusa buffer existente si está vivo; si no, crea conexión.
function M.ensure_active_session()
    if ensuring_active then
        return
    end

    ensuring_active = true

    local ok, err = pcall(function()
        local sessions = config_utils.getSSHSessions()
        local active_idx = config_utils.getActiveSSH()

        -- Sin sesiones configuradas: salida silenciosa.
        if not sessions or #sessions == 0 then
            return
        end

        -- Índice activo inválido: no forzar nada.
        if not active_idx or not sessions[active_idx] then
            return
        end

        M.ensure_session_buffers()

        -- Mostrar buffer de la sesión activa y conectar solo si hace falta.
        local active_buf = open_session_buffer(active_idx)
        if active_buf and not is_ssh_connected(active_buf) then
            M.connect()
        end
    end)

    ensuring_active = false

    if not ok then
        vim.schedule(function()
            vim.notify("SSH: error asegurando sesión activa: " .. tostring(err), vim.log.levels.WARN)
        end)
    end
end

-- Conectar a una sesión específica
-- @param session_index number Índice de la sesión (1-based)
function M.connect_to(session_index)
    local sessions = config_utils.getSSHSessions()
    if not sessions or not sessions[session_index] then
        vim.notify("SSH: Sesión no encontrada", vim.log.levels.ERROR)
        return
    end

    -- Mantener la sesión elegida como activa de forma explícita
    config_utils.setActiveSSH(session_index)

    local bufnr = open_session_buffer(session_index)
    if bufnr and not is_ssh_connected(bufnr) then
        M.connect()
    end
end

-- Conectar a todas las sesiones (crear buffers para cada una)
function M.connect_all()
    local sessions = config_utils.getSSHSessions()
    if not sessions or #sessions == 0 then
        vim.notify("SSH: No hay sesiones configuradas", vim.log.levels.WARN)
        return
    end

    local first_bufnr = nil
    for i, session in ipairs(sessions) do
        local bufnr = connect_session_buffer(session, i)
        if bufnr then
            ssh_buffers[i] = bufnr
            if not first_bufnr then
                first_bufnr = bufnr
            end
        end
    end

    -- Mostrar primer buffer
    if first_bufnr then
        workspace.goto_ssh()
        vim.api.nvim_win_set_buf(0, first_bufnr)
    end

    vim.notify("SSH: " .. #sessions .. " conexiones inicializadas", vim.log.levels.INFO)
end

-- Cambiar a la siguiente sesión SSH
function M.next_session()
    local sessions = config_utils.getSSHSessions()
    if not sessions or #sessions == 0 then
        return
    end

    local current = config_utils.getActiveSSH() or 0
    local next_idx = (current % #sessions) + 1

    config_utils.setActiveSSH(next_idx)
    local bufnr = open_session_buffer(next_idx)
    if bufnr and not is_ssh_connected(bufnr) then
        M.connect()
    end
end

-- Cambiar a la sesión anterior SSH
function M.prev_session()
    local sessions = config_utils.getSSHSessions()
    if not sessions or #sessions == 0 then
        return
    end

    local current = config_utils.getActiveSSH() or 1
    local prev_idx = ((current - 2 + #sessions) % #sessions) + 1

    config_utils.setActiveSSH(prev_idx)
    local bufnr = open_session_buffer(prev_idx)
    if bufnr and not is_ssh_connected(bufnr) then
        M.connect()
    end
end

-- Listar toutes les sessions SSH disponibles
function M.list_sessions()
    local sessions = config_utils.getSSHSessions()
    if not sessions or #sessions == 0 then
        vim.notify("SSH: No hay sesiones configuradas", vim.log.levels.WARN)
        return
    end

    local msg = "Sesiones SSH:\n"
    for i, session in ipairs(sessions) do
        local active = (i == config_utils.getActiveSSH()) and " [ACTIVE]" or ""
        local connected = ssh_buffers[i] and buffer_exists(ssh_buffers[i]) and " [CONNECTED]" or ""
        msg = msg .. string.format("  %d: %s@%s%s%s\n", i, session.user or "", session.ip, active, connected)
    end

    vim.notify(msg, vim.log.levels.INFO)
end

-- Cerrar la conexión actual (cerrar buffer)
function M.disconnect()
    local current = config_utils.getActiveSSH()
    if current and ssh_buffers[current] then
        local bufnr = ssh_buffers[current]
        if buffer_exists(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
        ssh_buffers[current] = nil
        vim.notify("SSH: Conexión cerrada", vim.log.levels.INFO)
    end
end

-- Cerrar todas las conexiones
function M.disconnect_all()
    for _, bufnr in pairs(ssh_buffers) do
        if buffer_exists(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end
    ssh_buffers = {}
    vim.notify("SSH: Todas las conexiones cerradas", vim.log.levels.INFO)
end

-- Hook para autocmd BufEnter/BufWinEnter.
-- Mantiene sincronizada la sesión activa y conecta on-demand.
function M.on_buffer_enter(bufnr)
    if handling_buf_enter then
        return
    end

    if not is_ssh_buffer(bufnr) then
        return
    end

    local is_ssh_ws = false
    local ok_ws, ws = pcall(require, "kvim.workspace")
    if ok_ws and ws and type(ws.is_ssh_workspace) == "function" then
        is_ssh_ws = ws.is_ssh_workspace()
    end

    if not is_ssh_ws then
        return
    end

    local session_index = vim.b[bufnr].kvim_ssh_session_index
    if not session_index then
        return
    end

    local session = get_session(session_index)
    if not session then
        return
    end

    local active_idx = config_utils.getActiveSSH()
    if active_idx ~= session_index then
        config_utils.setActiveSSH(session_index)
    end

    if is_ssh_connected(bufnr) then
        return
    end

    handling_buf_enter = true
    local ok, err = pcall(function()
        connect_session_buffer(session, session_index)
    end)
    handling_buf_enter = false

    if not ok then
        vim.schedule(function()
            vim.notify("SSH: error al conectar buffer: " .. tostring(err), vim.log.levels.WARN)
        end)
    end
end

-- Expone el bufnr asociado a un índice de sesión (debug/integraciones).
function M.get_buffer_for_session(session_index)
    return ssh_buffers[session_index]
end

vim.api.nvim_create_autocmd("BufWipeout", {
    group = augroup,
    callback = function(args)
        local bufnr = args.buf
        for idx, ssh_buf in pairs(ssh_buffers) do
            if ssh_buf == bufnr then
                ssh_buffers[idx] = nil
                break
            end
        end
    end,
    desc = "Clear SSH buffer registry on wipeout",
})

return M
