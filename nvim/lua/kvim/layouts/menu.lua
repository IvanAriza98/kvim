-- Módulo de menús para KVIM
-- Usa nvzone/menu para interfaces modernas con soporte de submenús

local M = {}

-- Estado para controlar si el menú debe mantenerse abierto
local menu_keep_open = false

-- Función auxiliar para abrir input sin cerrar el menú
function M._open_input(opts, callback)
    -- Cerrar menú temporalmente
    pcall(vim.cmd, "bd! NvimTree_menu")

    -- Abrir input
    vim.ui.input(opts, function(value)
        -- Reabrir menú
        if menu_keep_open then
            vim.defer_fn(function()
                M.open_main_menu()
            end, 100)
        end
        callback(value)
    end)
end

-- Función auxiliar para abrir select sin cerrar el menú
function M._open_select(items, opts, callback)
    -- Cerrar menú temporalmente
    pcall(vim.cmd, "bd! NvimTree_menu")

    vim.ui.select(items, opts, function(choice)
        -- Reabrir menú
        if menu_keep_open then
            vim.defer_fn(function()
                M.open_main_menu()
            end, 100)
        end
        callback(choice)
    end)
end

-- Abrir el menú principal de KVIM
function M.open_main_menu()
    local menu = require("menu")

    -- Calcular posición central de la pantalla
    local width = vim.o.columns
    local height = vim.o.lines
    local win_width = math.min(60, math.floor(width * 0.4))
    local win_height = math.min(25, math.floor(height * 0.6))
    local row = math.floor((height - win_height) / 2) - 1
    local col = math.floor((width - win_width) / 2)

    -- Resetear estado
    menu_keep_open = false

    menu.open({
        -- Título principal
        {
            name = "⚡ KVIM Config",
            hl = "Bold",
            title = true,
        },

        -- === Embedded ===
        {
            name = "│ Embedded",
            hl = "Bold",
        },
        {
            name = "  🔲 ESP-IDF",
            items = M.get_esp_idf_items(),
        },
        {
            name = "  📱 NRF-SDK",
            items = M.get_nrf_sdk_items(),
        },

        -- === General ===
        {
            name = "│ General",
            hl = "Bold",
        },
        {
            name = "  ⚙️ C++",
            cmd = function()
                vim.notify("C++ config: usa LSP y herramientas de desarrollo", vim.log.levels.INFO)
            end,
        },
        {
            name = "  🐍 Python",
            items = M.get_python_items(),
        },

        -- === MultiPlatform ===
        {
            name = "│ MultiPlatform",
            hl = "Bold",
        },
        {
            name = "  📱 Flutter",
            cmd = function()
                vim.notify("Flutter config: usa dart + flutter LSP", vim.log.levels.INFO)
            end,
        },

        -- === Communications ===
        {
            name = "│ Communications",
            hl = "Bold",
        },
        {
            name = "  🔐 SSH",
            items = M.get_ssh_items(),
        },

        -- === Environments ===
        {
            name = "│ Environments",
            hl = "Bold",
        },
        {
            name = "  🛠️ dev",
            cmd = function()
                require("kvim.workspace").goto_code()
            end,
        },
        {
            name = "  🚀 prod",
            cmd = function()
                require("kvim.workspace").goto_ssh()
            end,
        },
    }, {
        mouse = false, -- Navegación solo con teclado
        border = true,
        relative = "editor",
        position = {
            row = row,
            col = col,
        },
        size = {
            width = win_width,
            height = win_height,
        },
    })
end

-- Función para ejecutar acción que NO cierra el menú (configuración)
function M._exec_internal(cmd)
    menu_keep_open = true
    cmd()
end

-- Función para ejecutar acción que CIERRA el menú (operaciones externas)
function M._exec_external(cmd)
    menu_keep_open = false
    cmd()
end

-- === Submenú ESP-IDF ===
function M.get_esp_idf_items()
    local vars = require("kvim.env")
    local devices = require("kvim.utils.devices")
    local config_utils = require("kvim.utils.config-utils")

    local port = config_utils.getConfigField(vars.id.ESP_IDF, vars.key.IDF_PORT) or "Not set"
    local idfPath = config_utils.getConfigField(vars.id.ESP_IDF, vars.key.IDF_PATH) or "Not set"
    local family = config_utils.getConfigField(vars.id.ESP_IDF, vars.key.IDF_FAMILY) or "esp32"

    -- Obtener dispositivos USB
    local usb_devices = devices.get_usb_devices()
    local device_list = {}
    for _, dev in ipairs(usb_devices) do
        table.insert(device_list, dev.name)
    end

    return {
        {
            name = "  📋 Config",
            cmd = function()
                M._exec_internal(function()
                    M.configure_esp_idf()
                end)
            end,
        },
        {
            name = "  🔲 Family: " .. family,
            cmd = function()
                M._exec_internal(function()
                    M._open_select({
                        "esp32", "esp32s2", "esp32c2", "esp32s3", "esp32c3",
                        "esp32c6", "esp32h2", "esp32p4", "esp32c5", "esp32c61", "linux"
                    }, {
                        prompt = "Select ESP Family:",
                        default = family,
                    }, function(choice)
                        if choice then
                            config_utils.setConfigField(choice, vars.id.ESP_IDF, vars.key.IDF_FAMILY)
                            vim.notify("✓ ESP Family set to: " .. choice, vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  📁 IDF Path: " .. (idfPath ~= "" and idfPath or "Not set"),
            cmd = function()
                M._exec_internal(function()
                    M._open_input({
                        prompt = "IDF Path:",
                        default = idfPath,
                    }, function(path)
                        if path then
                            config_utils.setConfigField(path, vars.id.ESP_IDF, vars.key.IDF_PATH)
                            vim.notify("✓ IDF Path saved!", vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  🔌 Port: " .. port,
            cmd = function()
                M._exec_internal(function()
                    M._open_input({
                        prompt = "Serial Port:",
                        default = port,
                    }, function(p)
                        if p then
                            config_utils.setConfigField(p, vars.id.ESP_IDF, vars.key.IDF_PORT)
                            vim.notify("✓ Port saved!", vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  📱 Devices",
            items = #device_list > 0 and (function()
                local items = { { name = "    🔄 Refresh Devices", cmd = function() end } }
                for _, dev in ipairs(device_list) do
                    table.insert(items, {
                        name = "    " .. dev,
                        cmd = function()
                            config_utils.setConfigField(dev, vars.id.ESP_IDF, vars.key.IDF_PORT)
                            vim.notify("✓ Device selected: " .. dev, vim.log.levels.INFO)
                        end,
                    })
                end
                return items
            end)() or { { name = "    No devices found", cmd = function() end } },
        },
        {
            name = "  ─────────────────",
            cmd = function() end,
        },
        {
            name = "  ▶️  Build",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("EspIdfBuild")
                end)
            end,
        },
        {
            name = "  🚀 Flash",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("EspIdfFlash")
                end)
            end,
        },
        {
            name = "  📡 Monitor",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("EspIdfMonitor")
                end)
            end,
        },
    }
end

function M.configure_esp_idf()
    local config_utils = require("kvim.utils.config-utils")
    local vars = require("kvim.env")

    local family = config_utils.getConfigField(vars.id.ESP_IDF, vars.key.IDF_FAMILY) or "esp32"

    M._open_select({
        "esp32", "esp32s2", "esp32c2", "esp32s3", "esp32c3",
        "esp32c6", "esp32h2", "esp32p4", "esp32c5", "esp32c61", "linux"
    }, {
        prompt = "Select ESP Family:",
        default = family,
    }, function(choice)
        if choice then
            config_utils.setConfigField(choice, vars.id.ESP_IDF, vars.key.IDF_FAMILY)
            vim.notify("✓ ESP Family set to: " .. choice, vim.log.levels.INFO)
        end
    end)
end

-- === Submenú NRF-SDK ===
function M.get_nrf_sdk_items()
    local config_utils = require("kvim.utils.config-utils")
    local vars = require("kvim.env")

    local workspace = config_utils.getConfigField(vars.id.NRF_SDK, vars.key.NRF_WORKSPACE_PATH) or "Not set"
    local project = config_utils.getConfigField(vars.id.NRF_SDK, vars.key.NRF_PROJECT_NAME) or "Not set"
    local board = config_utils.getConfigField(vars.id.NRF_SDK, vars.key.NRF_BOARD_TARGET) or "Not set"

    return {
        {
            name = "  📋 Config",
            cmd = function()
                M._exec_internal(function()
                    M.configure_nrf_sdk()
                end)
            end,
        },
        {
            name = "  📁 Workspace: " .. (workspace ~= "" and workspace or "Not set"),
            cmd = function()
                M._exec_internal(function()
                    M._open_input({
                        prompt = "Workspace Path:",
                        default = workspace,
                    }, function(ws)
                        if ws then
                            config_utils.setConfigField(ws, vars.id.NRF_SDK, vars.key.NRF_WORKSPACE_PATH)
                            vim.notify("✓ Workspace saved!", vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  📦 Project: " .. (project ~= "" and project or "Not set"),
            cmd = function()
                M._exec_internal(function()
                    M._open_input({
                        prompt = "Project Name:",
                        default = project,
                    }, function(p)
                        if p then
                            config_utils.setConfigField(p, vars.id.NRF_SDK, vars.key.NRF_PROJECT_NAME)
                            vim.notify("✓ Project saved!", vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  🖥️  Board: " .. (board ~= "" and board or "Not set"),
            cmd = function()
                M._exec_internal(function()
                    M._open_input({
                        prompt = "Board Target:",
                        default = board,
                    }, function(b)
                        if b then
                            config_utils.setConfigField(b, vars.id.NRF_SDK, vars.key.NRF_BOARD_TARGET)
                            vim.notify("✓ Board saved!", vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  ─────────────────",
            cmd = function() end,
        },
        {
            name = "  ▶️  Build",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("NrfSdkBuild")
                end)
            end,
        },
        {
            name = "  🚀 Flash",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("NrfSdkFlash")
                end)
            end,
        },
        {
            name = "  🧪 Debug",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("NrfSdkDebug")
                end)
            end,
        },
    }
end

function M.configure_nrf_sdk()
    local config_utils = require("kvim.utils.config-utils")
    local vars = require("kvim.env")

    local workspace = config_utils.getConfigField(vars.id.NRF_SDK, vars.key.NRF_WORKSPACE_PATH) or ""
    local project = config_utils.getConfigField(vars.id.NRF_SDK, vars.key.NRF_PROJECT_NAME) or ""
    local board = config_utils.getConfigField(vars.id.NRF_SDK, vars.key.NRF_BOARD_TARGET) or ""

    M._open_input({
        prompt = "NRF-SDK Configuration\nWorkspace:",
        default = workspace,
    }, function(ws)
        if ws then
            config_utils.setConfigField(ws, vars.id.NRF_SDK, vars.key.NRF_WORKSPACE_PATH)
            M._open_input({
                prompt = "Project:",
                default = project,
            }, function(p)
                if p then
                    config_utils.setConfigField(p, vars.id.NRF_SDK, vars.key.NRF_PROJECT_NAME)
                    M._open_input({
                        prompt = "Board:",
                        default = board,
                    }, function(b)
                        if b then
                            config_utils.setConfigField(b, vars.id.NRF_SDK, vars.key.NRF_BOARD_TARGET)
                            vim.notify("✓ NRF-SDK config saved!", vim.log.levels.INFO)
                        end
                    end)
                end
            end)
        end
    end)
end

-- === Submenú Python ===
function M.get_python_items()
    local config_utils = require("kvim.utils.config-utils")
    local vars = require("kvim.env")

    local current_path = config_utils.getConfigField(vars.id.PYTHON, vars.key.PYT_PATH) or "Not set"

    return {
        {
            name = "  🔧 Config Python",
            cmd = function()
                M._exec_internal(function()
                    M.configure_python()
                end)
            end,
        },
        {
            name = "  📁 Path: " .. (current_path ~= "" and current_path or "Not set"),
            cmd = function()
                M._exec_internal(function()
                    M._open_input({
                        prompt = "Python Path:",
                        default = current_path,
                    }, function(input)
                        if input and input ~= "" then
                            config_utils.setConfigField(input, vars.id.PYTHON, vars.key.PYT_PATH)
                            vim.notify("✓ Python path saved: " .. input, vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  ─────────────────",
            cmd = function() end,
        },
        {
            name = "  ▶️  Run Current File",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("PythonRunCurrentFile")
                end)
            end,
        },
        {
            name = "  🐛 Debug",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("PythonDebugCurrentFile")
                end)
            end,
        },
    }
end

function M.configure_python()
    local config_utils = require("kvim.utils.config-utils")
    local vars = require("kvim.env")

    local current_path = config_utils.getConfigField(vars.id.PYTHON, vars.key.PYT_PATH) or ""

    M._open_input({
        prompt = "Python Path:",
        default = current_path,
    }, function(input)
        if input and input ~= "" then
            config_utils.setConfigField(input, vars.id.PYTHON, vars.key.PYT_PATH)
            vim.notify("✓ Python path saved: " .. input, vim.log.levels.INFO)
        end
    end)
end

-- === Submenú SSH ===
-- Formatea el nombre de una sesión SSH para mostrar en el menú
-- @param session table La sesión SSH (debe tener ip y opcionalmente user/name)
-- @return string El nombre formateado como "nombre(user)" o "ip(user)"
function M.format_ssh_session_name(session)
    if not session or not session.ip then
        return "(sin sesión)"
    end
    local display_name = session.name or session.ip
    if session.user then
        return display_name .. "(" .. session.user .. ")"
    end
    return display_name .. "()"
end

-- Obtiene los items del submenú SSH con múltiples sesiones
function M.get_ssh_items()
    local config_utils = require("kvim.utils.config-utils")

    local sessions = config_utils.getSSHSessions() or {}
    local active_idx = config_utils.getActiveSSH() or 1

    -- Construir lista de sesiones con indicador de activa
    local session_items = {}
    for i, session in ipairs(sessions) do
        local prefix = (i == active_idx) and "✅ " or "  "
        table.insert(session_items, {
            name = "  " .. prefix .. M.format_ssh_session_name(session),
            cmd = function()
                M._exec_internal(function()
                    config_utils.setActiveSSH(i)
                    vim.notify("✓ Sesión activa: " .. M.format_ssh_session_name(session), vim.log.levels.INFO)
                end)
            end,
        })
    end

    return {
        -- Lista de sesiones
        {
            name = "  🔐 Sesiones",
            items = #session_items > 0 and session_items or { {
                name = "    (sin sesiones)",
                cmd = function() end,
            } },
        },
        -- Separador
        {
            name = "  ─────────────────",
            cmd = function() end,
        },
        -- Opciones de conexión
        {
            name = "  📋 Conectar",
            cmd = function()
                M._exec_external(function()
                    if #sessions == 0 then
                        vim.notify("No hay sesiones SSH. Crea una primero.", vim.log.levels.WARN)
                        return
                    end
                    vim.cmd("SSHConnect")
                end)
            end,
        },
        {
            name = "  📋 Conectar a...",
            cmd = function()
                M._exec_internal(function()
                    if #sessions == 0 then
                        vim.notify("No hay sesiones SSH. Crea una primero.", vim.log.levels.WARN)
                        return
                    end
                    local choices = {}
                    for i, session in ipairs(sessions) do
                        choices[i] = M.format_ssh_session_name(session)
                    end
                    M._open_select(choices, {
                        prompt = "Seleccionar sesión SSH:",
                    }, function(choice)
                        if choice then
                            for i, name in ipairs(choices) do
                                if name == choice then
                                    vim.notify("✓ Conectando a: " .. choice, vim.log.levels.INFO)
                                    M._exec_external(function()
                                        require("kvim.workspace.ssh-manager").connect_to(i)
                                    end)
                                    break
                                end
                            end
                        end
                    end)
                end)
            end,
        },
        {
            name = "  🔑 Compartir clave pública",
            cmd = function()
                M._exec_external(function()
                    if #sessions == 0 then
                        vim.notify("No hay sesiones SSH. Crea una primero.", vim.log.levels.WARN)
                        return
                    end
                    vim.cmd("SSHShareKey")
                end)
            end,
        },
        -- Gestión de sesiones
        {
            name = "  ➕ Nueva sesión",
            cmd = function()
                M._exec_internal(function()
                    M.add_ssh_session()
                end)
            end,
        },
        {
            name = "  ✏️  Editar sesión",
            cmd = function()
                M._exec_internal(function()
                    if #sessions == 0 then
                        vim.notify("No hay sesiones SSH. Crea una primero.", vim.log.levels.WARN)
                        return
                    end
                    local choices = {}
                    for i, session in ipairs(sessions) do
                        choices[i] = M.format_ssh_session_name(session)
                    end
                    M._open_select(choices, {
                        prompt = "Editar sesión SSH:",
                    }, function(choice)
                        if choice then
                            for i, name in ipairs(choices) do
                                if name == choice then
                                    M.edit_ssh_session(i, sessions[i])
                                    break
                                end
                            end
                        end
                    end)
                end)
            end,
        },
        {
            name = "  🗑️  Eliminar sesión",
            cmd = function()
                M._exec_internal(function()
                    if #sessions == 0 then
                        vim.notify("No hay sesiones SSH.", vim.log.levels.WARN)
                        return
                    end
                    local choices = {}
                    for i, session in ipairs(sessions) do
                        choices[i] = M.format_ssh_session_name(session)
                    end
                    M._open_select(choices, {
                        prompt = "Eliminar sesión SSH:",
                    }, function(choice)
                        if choice then
                            for i, name in ipairs(choices) do
                                if name == choice then
                                    vim.ui.input({
                                        prompt = "Confirmar eliminar '" .. name .. "'? (s/n):",
                                    }, function(confirm)
                                        if confirm and (confirm == "s" or confirm == "S") then
                                            config_utils.deleteSSHSession(i)
                                            vim.notify("✓ Sesión eliminada", vim.log.levels.INFO)
                                        end
                                    end)
                                    break
                                end
                            end
                        end
                    end)
                end)
            end,
        },
        -- Separador
        {
            name = "  ─────────────────",
            cmd = function() end,
        },
        -- Transferencia de archivos
        {
            name = "  📤 SSH Upload",
            cmd = function()
                M._exec_external(function()
                    if #sessions == 0 then
                        vim.notify("No hay sesiones SSH. Crea una primero.", vim.log.levels.WARN)
                        return
                    end
                    vim.cmd("SSHUpload")
                end)
            end,
        },
        {
            name = "  📥 SSH Download",
            cmd = function()
                M._exec_external(function()
                    if #sessions == 0 then
                        vim.notify("No hay sesiones SSH. Crea una primero.", vim.log.levels.WARN)
                        return
                    end
                    vim.cmd("SSHDownload")
                end)
            end,
        },
        -- Separador
        {
            name = "  ─────────────────",
            cmd = function() end,
        },
        -- Cambio rápido entre sesiones
        {
            name = "  ⬇️  Siguiente Sesión",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("SSHNext")
                end)
            end,
        },
        {
            name = "  ⬆️  Sesión Anterior",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("SSHPrev")
                end)
            end,
        },
        {
            name = "  📋 Listar Sesiones",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("SSHList")
                end)
            end,
        },
    }
end

-- Añade una nueva sesión SSH
function M.add_ssh_session()
    local config_utils = require("kvim.utils.config-utils")

    local new_session = {
        ip = "",
        user = "",
        port = "22",
        path = "",
        key_type = "ed25519",
        name = "",
    }

    M._open_input({
        prompt = "Nombre (opcional, por defecto usa IP):",
        default = "",
    }, function(name)
        if name and name ~= "" then
            new_session.name = name
        end
        M._open_input({
            prompt = "IP:",
            default = new_session.ip,
        }, function(ip)
            if not ip or ip == "" then
                vim.notify("IP requerida", vim.log.levels.WARN)
                return
            end
            new_session.ip = ip

            -- Si no hay nombre, usar ip(user) por defecto
            if new_session.name == "" then
                new_session.name = ip
            end

            M._open_input({
                prompt = "Usuario:",
                default = new_session.user,
            }, function(user)
                new_session.user = user or ""

                M._open_input({
                    prompt = "Puerto:",
                    default = new_session.port,
                }, function(port)
                    new_session.port = port or "22"

                    M._open_input({
                        prompt = "Ruta por defecto:",
                        default = new_session.path,
                    }, function(path)
                        new_session.path = path or ""

                        M._open_select({
                            "rsa", "dsa", "ecdsa", "ecdsa-sk", "ed25519", "ed25519-sk"
                        }, {
                            prompt = "Tipo de clave:",
                            default = new_session.key_type,
                        }, function(key_type)
                            new_session.key_type = key_type or "ed25519"

                            config_utils.addSSHSession(new_session)
                            vim.notify("✓ Sesión añadida: " .. M.format_ssh_session_name(new_session), vim.log.levels.INFO)
                        end)
                    end)
                end)
            end)
        end)
    end)
end

-- Edita una sesión SSH existente
-- @param index number Índice de la sesión a editar (1-based)
-- @param session table La sesión SSH actual
function M.edit_ssh_session(index, session)
    local config_utils = require("kvim.utils.config-utils")

    local edited = {
        name = session.name or "",
        ip = session.ip or "",
        user = session.user or "",
        port = session.port or "22",
        path = session.path or "",
        key_type = session.key_type or "ed25519",
    }

    M._open_input({
        prompt = "Nombre:",
        default = edited.name,
    }, function(name)
        edited.name = name or ""

        M._open_input({
            prompt = "IP:",
            default = edited.ip,
        }, function(ip)
            if not ip or ip == "" then
                vim.notify("IP requerida", vim.log.levels.WARN)
                return
            end
            edited.ip = ip

            M._open_input({
                prompt = "Usuario:",
                default = edited.user,
            }, function(user)
                edited.user = user or ""

                M._open_input({
                    prompt = "Puerto:",
                    default = edited.port,
                }, function(port)
                    edited.port = port or "22"

                    M._open_input({
                        prompt = "Ruta por defecto:",
                        default = edited.path,
                    }, function(path)
                        edited.path = path or ""

                        M._open_select({
                            "rsa", "dsa", "ecdsa", "ecdsa-sk", "ed25519", "ed25519-sk"
                        }, {
                            prompt = "Tipo de clave:",
                            default = edited.key_type,
                        }, function(key_type)
                            edited.key_type = key_type or "ed25519"

                            config_utils.updateSSHSession(index, edited)
                            vim.notify("✓ Sesión actualizada: " .. M.format_ssh_session_name(edited), vim.log.levels.INFO)
                        end)
                    end)
                end)
            end)
        end)
    end)
end

function M.configure_ssh()
    local config_utils = require("kvim.utils.config-utils")
    local vars = require("kvim.env")

    local ip = config_utils.getConfigField(vars.id.SSH, vars.key.SSH_IP) or ""
    local port = config_utils.getConfigField(vars.id.SSH, vars.key.SSH_PORT) or "22"
    local user = config_utils.getConfigField(vars.id.SSH, vars.key.SSH_USER) or ""
    local path = config_utils.getConfigField(vars.id.SSH, vars.key.SSH_PATH) or ""
    local key_type = config_utils.getConfigField(vars.id.SSH, vars.key.SSH_KEY_TYPE) or "ed25519"

    M._open_input({
        prompt = "SSH Configuration\nIP:",
        default = ip,
    }, function(new_ip)
        if new_ip then
            config_utils.setConfigField(new_ip, vars.id.SSH, vars.key.SSH_IP)
            M._open_input({
                prompt = "Port:",
                default = port,
            }, function(new_port)
                if new_port then
                    config_utils.setConfigField(new_port, vars.id.SSH, vars.key.SSH_PORT)
                    M._open_input({
                        prompt = "User:",
                        default = user,
                    }, function(new_user)
                        if new_user then
                            config_utils.setConfigField(new_user, vars.id.SSH, vars.key.SSH_USER)
                            M._open_input({
                                prompt = "Default Path:",
                                default = path,
                            }, function(new_path)
                                if new_path then
                                    config_utils.setConfigField(new_path, vars.id.SSH, vars.key.SSH_PATH)
                                    M._open_select({
                                        "rsa", "dsa", "ecdsa", "ecdsa-sk", "ed25519", "ed25519-sk"
                                    }, {
                                        prompt = "Key Type:",
                                        default = key_type,
                                    }, function(choice)
                                        if choice then
                                            config_utils.setConfigField(choice, vars.id.SSH, vars.key.SSH_KEY_TYPE)
                                            vim.notify("✓ SSH config saved!", vim.log.levels.INFO)
                                        end
                                    end)
                                end
                            end)
                        end
                    end)
                end
            end)
        end
    end)
end

return M
