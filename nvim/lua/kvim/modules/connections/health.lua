-- lua/kvim/modules/connections/health.lua

local M = {}

local function health_start(name)
  if vim.health and vim.health.start then
    vim.health.start(name)
  else
    vim.fn["health#report_start"](name)
  end
end

local function health_ok(message)
  if vim.health and vim.health.ok then
    vim.health.ok(message)
  else
    vim.fn["health#report_ok"](message)
  end
end

local function health_warn(message)
  if vim.health and vim.health.warn then
    vim.health.warn(message)
  else
    vim.fn["health#report_warn"](message)
  end
end

local function health_error(message)
  if vim.health and vim.health.error then
    vim.health.error(message)
  else
    vim.fn["health#report_error"](message)
  end
end

local function executable_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function check_executable(cmd, required)
  if executable_exists(cmd) then
    health_ok(cmd .. " executable found")
    return true
  end

  if required then
    health_error(cmd .. " executable not found")
  else
    health_warn(cmd .. " executable not found")
  end

  return false
end

local function check_file_exists(path, label)
  if not path or path == "" then
    health_warn(label .. " not configured")
    return false
  end

  local expanded = vim.fn.expand(path)

  if vim.fn.filereadable(expanded) == 1 then
    health_ok(label .. " exists: " .. expanded)
    return true
  end

  health_warn(label .. " not found: " .. expanded)
  return false
end

local function check_dir_exists(path, label)
  if not path or path == "" then
    health_warn(label .. " not configured")
    return false
  end

  local expanded = vim.fn.expand(path)

  if vim.fn.isdirectory(expanded) == 1 then
    health_ok(label .. " exists: " .. expanded)
    return true
  end

  health_warn(label .. " not found: " .. expanded)
  return false
end

local function check_connections_config(opts)
  local config = require("kvim.modules.connections.config")
  local connections = config.load(opts or {})

  if not connections or vim.tbl_isempty(connections) then
    health_warn("No KVIM connections configured")
    return {}
  end

  health_ok("Loaded " .. tostring(#connections) .. " connection(s)")

  local ssh_count = 0
  local serial_count = 0

  for _, conn in ipairs(connections) do
    if conn.type == "ssh" then
      ssh_count = ssh_count + 1
    elseif conn.type == "serial" then
      serial_count = serial_count + 1
    end
  end

  health_ok("SSH connections: " .. tostring(ssh_count))
  health_ok("Serial connections: " .. tostring(serial_count))

  return connections
end

local function check_connection_details(connections)
  for _, conn in ipairs(connections) do
    local name = conn.name or "unnamed"

    if not conn.type then
      health_warn("Connection '" .. name .. "' has no type")
    elseif conn.type ~= "ssh" and conn.type ~= "serial" then
      health_warn("Connection '" .. name .. "' has unsupported type: " .. tostring(conn.type))
    else
      health_ok("Connection '" .. name .. "' type: " .. conn.type)
    end

    if conn.type == "ssh" then
      if not conn.host or conn.host == "" then
        health_error("SSH connection '" .. name .. "' has no host")
      end

      if not conn.user or conn.user == "" then
        health_warn("SSH connection '" .. name .. "' has no user")
      end

      if conn.identity_file and conn.identity_file ~= "" then
        check_file_exists(conn.identity_file, "Identity file for '" .. name .. "'")
      end

      local transfer = conn.transfer or {}

      if transfer.local_root then
        check_dir_exists(transfer.local_root, "local_root for '" .. name .. "'")
      end

      if transfer.remote_root then
        health_ok("remote_root configured for '" .. name .. "': " .. transfer.remote_root)
      else
        health_warn("remote_root not configured for '" .. name .. "'")
      end
    end

    if conn.type == "serial" then
      if not conn.device or conn.device == "" then
        health_error("Serial connection '" .. name .. "' has no device")
      end

      if not conn.baudrate then
        health_warn("Serial connection '" .. name .. "' has no baudrate")
      end
    end
  end
end

local function check_active_connection()
  local state = require("kvim.modules.connections.state")
  local conn = state.get_active_connection()

  if not conn then
    health_warn("No active connection selected")
    return
  end

  health_ok("Active connection: " .. state.get_active_connection_label())
end

function M.check(opts)
  opts = opts or {}

  health_start("KVIM Connections")

  check_executable("ssh", true)
  check_executable("scp", true)
  check_executable("ssh-keygen", false)
  check_executable("ssh-copy-id", false)
  check_executable("rsync", false)

  local connections = check_connections_config(opts)

  check_connection_details(connections)
  check_active_connection()
end

return M
