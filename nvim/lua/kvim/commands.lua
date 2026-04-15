local M = {}

local function run_in_terminal(cmd, direction)
    local term = require("toggleterm.terminal").Terminal:new({
        cmd = cmd,
        direction = direction or "horizontal",
        hidden = true,
    })
    term:toggle()
end

function M.esp_idf_build()
    local idf = require("kvim.utils.esp-idf-commands")
    local cmd = idf.idfBuildProject()
    if cmd then
        run_in_terminal(cmd, "horizontal")
    end
end

function M.esp_idf_flash()
    local idf = require("kvim.utils.esp-idf-commands")
    local cmd = idf.idfFlashProject()
    if cmd then
        run_in_terminal(cmd, "horizontal")
    end
end

function M.esp_idf_monitor()
    local idf = require("kvim.utils.esp-idf-commands")
    local cmd = idf.idfMonitorProject()
    if cmd then
        run_in_terminal(cmd, "float")
    end
end

function M.nrf_sdk_build()
    local nrf = require("kvim.utils.nrf-sdk-commands")
    local cmd = nrf.nrfBuildProject()
    if cmd then
        run_in_terminal(cmd, "horizontal")
    end
end

function M.nrf_sdk_flash()
    local nrf = require("kvim.utils.nrf-sdk-commands")
    local cmd = nrf.nrfFlashProject()
    if cmd then
        run_in_terminal(cmd, "horizontal")
    end
end

function M.nrf_sdk_debug()
    local nrf = require("kvim.utils.nrf-sdk-commands")
    local cmd = nrf.nrfDebugMonitorProject()
    if cmd then
        run_in_terminal(cmd, "horizontal")
    end
end

function M.python_run()
    local python = require("kvim.utils.python-commands")
    local cmd = python.pytExecute()
    if cmd then
        run_in_terminal(cmd, "horizontal")
    end
end

function M.ssh_connect()
    require("kvim.workspace.ssh-manager").connect()
end

function M.ssh_upload()
    -- Legacy path: upload/download todavía dependen de kvim.utils.ssh.
    -- Conexión y navegación de sesiones ya usan kvim.workspace.ssh-manager.
    local ssh = require("kvim.utils.ssh")
    local file = vim.fn.input("File to upload: ", vim.fn.expand("%:p:h"))
    if file and file ~= "" then
        ssh.transfer_file(file, true)
    end
end

function M.ssh_download()
    -- Legacy path: upload/download todavía dependen de kvim.utils.ssh.
    -- Conexión y navegación de sesiones ya usan kvim.workspace.ssh-manager.
    local ssh = require("kvim.utils.ssh")
    local file = vim.fn.input("File to download: ")
    if file and file ~= "" then
        ssh.transfer_file(file, false)
    end
end

function M.ssh_share_key()
    local ssh = require("kvim.utils.ssh")
    ssh.share_pub_key()
end

vim.api.nvim_create_user_command("EspIdfBuild", function()
    M.esp_idf_build()
end, {})

vim.api.nvim_create_user_command("EspIdfFlash", function()
    M.esp_idf_flash()
end, {})

vim.api.nvim_create_user_command("EspIdfMonitor", function()
    M.esp_idf_monitor()
end, {})

vim.api.nvim_create_user_command("NrfSdkBuild", function()
    M.nrf_sdk_build()
end, {})

vim.api.nvim_create_user_command("NrfSdkFlash", function()
    M.nrf_sdk_flash()
end, {})

vim.api.nvim_create_user_command("NrfSdkDebug", function()
    M.nrf_sdk_debug()
end, {})

vim.api.nvim_create_user_command("PythonRunCurrentFile", function()
    M.python_run()
end, {})

vim.api.nvim_create_user_command("SSHConnect", function()
    M.ssh_connect()
end, {})

vim.api.nvim_create_user_command("SSHNext", function()
    require("kvim.workspace.ssh-manager").next_session()
end, {})

vim.api.nvim_create_user_command("SSHPrev", function()
    require("kvim.workspace.ssh-manager").prev_session()
end, {})

vim.api.nvim_create_user_command("SSHList", function()
    require("kvim.workspace.ssh-manager").list_sessions()
end, {})

vim.api.nvim_create_user_command("SSHUpload", function()
    M.ssh_upload()
end, {})

vim.api.nvim_create_user_command("SSHDownload", function()
    M.ssh_download()
end, {})

vim.api.nvim_create_user_command("SSHShareKey", function()
    M.ssh_share_key()
end, {})

return M
