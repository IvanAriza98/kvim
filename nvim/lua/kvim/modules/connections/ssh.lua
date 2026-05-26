-- lua/kvim/modules/connections/ssh.lua

local M = {}

local function shellescape(value)
  return vim.fn.shellescape(tostring(value))
end

local function build_target(connection)
  if connection.user and connection.user ~= "" then
    return connection.user .. "@" .. connection.host
  end

  return connection.host
end

local function append_common_ssh_args(parts, connection)
  if connection.port then
    table.insert(parts, "-p")
    table.insert(parts, shellescape(connection.port))
  end

  if connection.identity_file then
    local identity_file = connection.identity_file
    if type(identity_file) == "string" and identity_file ~= "" then
      identity_file = vim.fn.expand(identity_file)
    end

    table.insert(parts, "-i")
    table.insert(parts, shellescape(identity_file))
  end

  if connection.options and type(connection.options) == "table" then
    for key, value in pairs(connection.options) do
      table.insert(parts, "-o")
      table.insert(parts, shellescape(key .. "=" .. tostring(value)))
    end
  end
end

function M.is_valid(connection)
  if type(connection) ~= "table" then
    return false, "connection must be a table"
  end

  if connection.type ~= "ssh" then
    return false, "connection type must be ssh"
  end

  if not connection.host or connection.host == "" then
    return false, "ssh connection requires host"
  end

  return true
end

function M.build_command(connection)
  local valid, err = M.is_valid(connection)

  if not valid then
    return nil, err
  end

  local parts = { "ssh" }

  append_common_ssh_args(parts, connection)

  table.insert(parts, shellescape(build_target(connection)))

  return table.concat(parts, " ")
end

function M.build_run_command(connection, remote_command)
  local valid, err = M.is_valid(connection)

  if not valid then
    return nil, err
  end

  if not remote_command or remote_command == "" then
    return nil, "remote command is required"
  end

  local parts = { "ssh" }

  append_common_ssh_args(parts, connection)

  table.insert(parts, shellescape(build_target(connection)))
  table.insert(parts, shellescape(remote_command))

  return table.concat(parts, " ")
end

function M.run_command(connection, remote_command)
  local cmd, err = M.build_run_command(connection, remote_command)

  if not cmd then
    vim.notify("KVIM Connections: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local terminal = require("kvim.core.terminal")

  terminal.open_command(cmd, {
    position = connection.position or "bottom",
    name = "KVIM SSH Run [" .. (connection.name or connection.host or "ssh") .. "]",
    listed = false,
  })
end

function M.display(connection)
  local user = connection.user or vim.env.USER or ""
  local port = connection.port or 22

  return string.format(
    "[SSH] %s  %s@%s:%s",
    connection.name or connection.host,
    user,
    connection.host,
    port
  )
end

return M
