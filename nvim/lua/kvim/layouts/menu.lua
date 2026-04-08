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
    local config_utils = require("kvim.utils.config-utils")
    local vars = require("kvim.env")
    local devices = require("kvim.utils.devices")

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
            name = "  📋 Config: " .. family,
            cmd = function()
                M._exec_internal(function()
                    M.configure_esp_idf()
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
function M.get_ssh_items()
    local config_utils = require("kvim.utils.config-utils")
    local vars = require("kvim.env")

    local ip = config_utils.getConfigField(vars.id.SSH, vars.key.SSH_IP) or "Not set"
    local port = config_utils.getConfigField(vars.id.SSH, vars.key.SSH_PORT) or "22"
    local user = config_utils.getConfigField(vars.id.SSH, vars.key.SSH_USER) or "Not set"

    return {
        {
            name = "  📋 Config",
            cmd = function()
                M._exec_internal(function()
                    M.configure_ssh()
                end)
            end,
        },
        {
            name = "  🌐 IP: " .. (ip ~= "" and ip or "Not set"),
            cmd = function()
                M._exec_internal(function()
                    M._open_input({
                        prompt = "SSH IP Address:",
                        default = ip,
                    }, function(new_ip)
                        if new_ip then
                            config_utils.setConfigField(new_ip, vars.id.SSH, vars.key.SSH_IP)
                            vim.notify("✓ SSH IP saved!", vim.log.levels.INFO)
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
                        prompt = "SSH Port:",
                        default = port,
                    }, function(new_port)
                        if new_port then
                            config_utils.setConfigField(new_port, vars.id.SSH, vars.key.SSH_PORT)
                            vim.notify("✓ SSH Port saved!", vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  👤 User: " .. (user ~= "" and user or "Not set"),
            cmd = function()
                M._exec_internal(function()
                    M._open_input({
                        prompt = "SSH User:",
                        default = user,
                    }, function(new_user)
                        if new_user then
                            config_utils.setConfigField(new_user, vars.id.SSH, vars.key.SSH_USER)
                            vim.notify("✓ SSH User saved!", vim.log.levels.INFO)
                        end
                    end)
                end)
            end,
        },
        {
            name = "  📂 SSH Connect",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("SSHConnect")
                end)
            end,
        },
        {
            name = "  📤 SSH Upload",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("SSHUpload")
                end)
            end,
        },
        {
            name = "  📥 SSH Download",
            cmd = function()
                M._exec_external(function()
                    vim.cmd("SSHDownload")
                end)
            end,
        },
    }
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
