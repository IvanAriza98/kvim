-- lua/kvim/modules/connections/actions.lua

local M = {}

local ssh = require("kvim.modules.connections.ssh")
local state = require("kvim.modules.connections.state")
local config = require("kvim.modules.connections.config")
local picker = require("kvim.modules.connections.picker")
local serial = require("kvim.modules.connections.serial")
local ssh_keys = require("kvim.modules.connections.ssh_keys")

local function executable_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function open_connection_terminal(connection, command, opts)
  opts = opts or {}
  local terminal = require("kvim.core.terminal")

  local split = true
  local listed = false

  local ok_ws_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
  if ok_ws_state then
    local current_tabnr = vim.fn.tabpagenr()
    local role = ws_state.get_tab_role(current_tabnr)
    if role == "term" then
      split = false
      listed = true
    end
  end

  local name = "KVIM " .. string.upper(connection.type or "connection")

  if connection.name then
    name = name .. " [" .. connection.name .. "]"
  end

  terminal.open_command(command, {
    position = connection.position or "bottom",
    name = name,
    listed = listed,
    split = split,
    startinsert = opts.startinsert ~= false,
  })

  local bufnr = vim.api.nvim_get_current_buf()
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_command", command)
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_cwd", vim.fn.getcwd())
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_type", connection.type or "shell")
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_position", connection.position or "bottom")

  if connection.name and connection.name ~= "" then
    pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_connection", connection.name)
  end
end

local function validate_executable(connection)
  if connection.type == "ssh" then
    if not executable_exists("ssh") then
      return false, "ssh executable not found"
    end

    return true
  end

  if connection.type == "serial" then
    local command = connection.command or "picocom"

    if not executable_exists(command) then
      return false, command .. " executable not found"
    end

    return true
  end

  return false, "unsupported connection type: " .. tostring(connection.type)
end

function M.open_connection(connection, opts)
  opts = opts or {}
  local ok_exec, exec_err = validate_executable(connection)

  if not ok_exec then
    vim.notify("KVIM Connections: " .. exec_err, vim.log.levels.ERROR)
    return
  end

  local command
  local err

  if connection.type == "ssh" then
    command, err = ssh.build_command(connection)
  elseif connection.type == "serial" then
    command, err = serial.build_command(connection)
  else
    err = "unsupported connection type: " .. tostring(connection.type)
  end

  if not command then
    vim.notify("KVIM Connections: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  state.set_active_connection(connection)
  open_connection_terminal(connection, command, opts)
end

function M.open_all_picker(opts)
  opts = opts or {}

  local connections = config.load(opts)

  picker.select(connections, function(connection)
    M.open_connection(connection)
  end)
end

function M.open_ssh_picker(opts)
  opts = opts or {}

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    M.open_connection(connection)
  end)
end

function M.open_serial_picker(opts)
  opts = opts or {}

  local connections = config.load(opts)
  local serial_connections = config.filter_by_type(connections, "serial")

  picker.select(serial_connections, function(connection)
    M.open_connection(connection)
  end)
end

function M.reload_config(opts)
  opts = opts or {}

  local connections = config.load(opts)

  vim.notify(
    "KVIM Connections: loaded " .. tostring(#connections) .. " connection(s)",
    vim.log.levels.INFO
  )
end

function M.generate_ssh_key()
  ssh_keys.generate_key()
end

function M.generate_ssh_key_picker(opts)
  opts = opts or {}

  local ssh_keys = require("kvim.modules.connections.ssh_keys")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    ssh_keys.generate_key_for_connection(connection)
  end)
end

function M.install_ssh_key_picker(opts)
  opts = opts or {}

  local ssh_keys = require("kvim.modules.connections.ssh_keys")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    ssh_keys.install_key(connection)
  end)
end

function M.test_ssh_connection_picker(opts)
  opts = opts or {}

  local ssh_keys = require("kvim.modules.connections.ssh_keys")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    ssh_keys.test_connection(connection)
  end)
end

function M.set_active_connection_picker(opts)
  opts = opts or {}

  local state = require("kvim.modules.connections.state")

  local connections = config.load(opts)

  if not connections or vim.tbl_isempty(connections) then
    vim.notify("KVIM Connections: no connections configured", vim.log.levels.WARN)
    return
  end

  picker.select(connections, function(connection)
    if not connection then
      vim.notify("KVIM Connections: active connection selection cancelled", vim.log.levels.WARN)
      return
    end

    state.set_active_connection(connection)
  end)
end

function M.set_active_ssh_connection_picker(opts)
  opts = opts or {}

  local state = require("kvim.modules.connections.state")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  if not ssh_connections or vim.tbl_isempty(ssh_connections) then
    vim.notify("KVIM Connections: no SSH connections configured", vim.log.levels.WARN)
    return
  end

  picker.select(ssh_connections, function(connection)
    if not connection then
      vim.notify("KVIM Connections: active SSH connection selection cancelled", vim.log.levels.WARN)
      return
    end

    state.set_active_connection(connection)
  end)
end

return M
