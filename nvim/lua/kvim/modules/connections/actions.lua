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

local function open_connection_terminal(connection, command)
  local terminal = require("kvim.core.terminal")

  local name = "KVIM " .. string.upper(connection.type or "connection")

  if connection.name then
    name = name .. " [" .. connection.name .. "]"
  end

  terminal.open_command(command, {
    position = connection.position or "bottom",
    name = name,
    listed = false,
  })
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

function M.open_connection(connection)
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
  open_connection_terminal(connection, command)
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


return M


