-- lua/kvim/modules/connections/health.lua

local M = {}

local health = require("kvim.core.health")

local function check_executable(cmd, required)
  return health.check_executable(cmd, { required = required })
end

local function check_file_exists(path, label)
  if not path or path == "" then
    health.warn(label .. " not configured")
    return false
  end

  local expanded = vim.fn.expand(path)

  if vim.fn.filereadable(expanded) == 1 then
    health.ok(label .. " exists: " .. expanded)
    return true
  end

  health.warn(label .. " not found: " .. expanded)
  return false
end

local function check_dir_exists(path, label)
  if not path or path == "" then
    health.warn(label .. " not configured")
    return false
  end

  local expanded = vim.fn.expand(path)

  if vim.fn.isdirectory(expanded) == 1 then
    health.ok(label .. " exists: " .. expanded)
    return true
  end

  health.warn(label .. " not found: " .. expanded)
  return false
end

local function check_connections_config(opts)
  local config = require("kvim.modules.connections.config")
  local connections = config.load(opts or {})

  if not connections or vim.tbl_isempty(connections) then
    health.warn("No KVIM connections configured")
    return {}
  end

  health.ok("Loaded " .. tostring(#connections) .. " connection(s)")

  local ssh_count = 0
  local serial_count = 0

  for _, conn in ipairs(connections) do
    if conn.type == "ssh" then
      ssh_count = ssh_count + 1
    elseif conn.type == "serial" then
      serial_count = serial_count + 1
    end
  end

  health.ok("SSH connections: " .. tostring(ssh_count))
  health.ok("Serial connections: " .. tostring(serial_count))

  return connections
end

local function check_connection_details(connections)
  for _, conn in ipairs(connections) do
    local name = conn.name or "unnamed"

    if not conn.type then
      health.warn("Connection '" .. name .. "' has no type")
    elseif conn.type ~= "ssh" and conn.type ~= "serial" then
      health.warn("Connection '" .. name .. "' has unsupported type: " .. tostring(conn.type))
    else
      health.ok("Connection '" .. name .. "' type: " .. conn.type)
    end

    if conn.type == "ssh" then
      if not conn.host or conn.host == "" then
        health.error("SSH connection '" .. name .. "' has no host")
      end

      if not conn.user or conn.user == "" then
        health.warn("SSH connection '" .. name .. "' has no user")
      end

      if conn.identity_file and conn.identity_file ~= "" then
        check_file_exists(conn.identity_file, "Identity file for '" .. name .. "'")
      end

      local transfer = conn.transfer or {}

      if transfer.local_root then
        check_dir_exists(transfer.local_root, "local_root for '" .. name .. "'")
      end

      if transfer.remote_root then
        health.ok("remote_root configured for '" .. name .. "': " .. transfer.remote_root)
      else
        health.warn("remote_root not configured for '" .. name .. "'")
      end
    end

    if conn.type == "serial" then
      if not conn.device or conn.device == "" then
        health.error("Serial connection '" .. name .. "' has no device")
      end

      if not conn.baudrate then
        health.warn("Serial connection '" .. name .. "' has no baudrate")
      end
    end
  end
end

local function check_active_connection()
  local state = require("kvim.modules.connections.state")
  local conn = state.get_active_connection()

  if not conn then
    health.warn("No active connection selected")
    return
  end

  health.ok("Active connection: " .. state.get_active_connection_label())
end

function M.check(opts)
  opts = opts or {}

  health.start("KVIM Connections")

  check_executable("ssh", true)
  check_executable("scp", true)
  check_executable("ssh-keygen", false)
  check_executable("ssh-copy-id", false)
  check_executable("picocom", false)
  check_executable("rsync", false)

  local connections = check_connections_config(opts)

  check_connection_details(connections)
  check_active_connection()
end

return M
