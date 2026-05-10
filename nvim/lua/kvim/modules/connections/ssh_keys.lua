-- lua/kvim/modules/connections/ssh_keys.lua

local M = {}

local function executable_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function shellescape(value)
  return vim.fn.shellescape(tostring(value))
end

local function expand_path(path)
  return vim.fn.expand(tostring(path))
end

local function slugify(value)
  value = tostring(value or "connection")
  value = value:lower()
  value = value:gsub("%s+", "_")
  value = value:gsub("[^%w_%-]", "")
  value = value:gsub("_+", "_")
  return value
end

function M.default_key_path()
  return vim.fn.expand("~/.ssh/kvim_connections_ed25519")
end

function M.key_path_for_connection(connection)
  if connection and connection.identity_file and connection.identity_file ~= "" then
    return expand_path(connection.identity_file)
  end

  local name = connection and connection.name or "connection"
  local slug = slugify(name)

  return vim.fn.expand("~/.ssh/kvim_" .. slug .. "_ed25519")
end

function M.key_exists(path)
  path = expand_path(path or M.default_key_path())
  return vim.fn.filereadable(path) == 1
end

function M.public_key_exists(path)
  path = expand_path(path or M.default_key_path()) .. ".pub"
  return vim.fn.filereadable(path) == 1
end

function M.generate_key(path, comment)
  path = expand_path(path or M.default_key_path())
  comment = comment or "kvim-connections"

  if not executable_exists("ssh-keygen") then
    vim.notify("KVIM Connections: ssh-keygen not found", vim.log.levels.ERROR)
    return
  end

  if M.key_exists(path) then
    vim.notify("KVIM Connections: SSH key already exists: " .. path, vim.log.levels.WARN)
    return
  end

  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

  local cmd = table.concat({
    "ssh-keygen",
    "-t", "ed25519",
    "-f", shellescape(path),
    "-C", shellescape(comment),
    "-N", shellescape(""),
  }, " ")

  local terminal = require("kvim.core.terminal")

  terminal.open_command(cmd, {
    position = "bottom",
    name = "KVIM SSH Keygen",
    listed = false,
  })
end

function M.generate_key_for_connection(connection)
  if not connection or connection.type ~= "ssh" then
    vim.notify("KVIM Connections: selected connection is not SSH", vim.log.levels.ERROR)
    return
  end

  local key_path = M.key_path_for_connection(connection)
  local comment = "kvim-" .. slugify(connection.name or connection.host)

  M.generate_key(key_path, comment)
end

function M.install_key(connection)
  if not executable_exists("ssh-copy-id") then
    vim.notify("KVIM Connections: ssh-copy-id not found", vim.log.levels.ERROR)
    return
  end

  if not connection or connection.type ~= "ssh" then
    vim.notify("KVIM Connections: selected connection is not SSH", vim.log.levels.ERROR)
    return
  end

  local key_path = M.key_path_for_connection(connection)
  local public_key = key_path .. ".pub"

  if vim.fn.filereadable(public_key) ~= 1 then
    vim.notify("KVIM Connections: public key not found: " .. public_key, vim.log.levels.ERROR)
    return
  end

  local target

  if connection.user and connection.user ~= "" then
    target = connection.user .. "@" .. connection.host
  else
    target = connection.host
  end

  local parts = {
    "ssh-copy-id",
    "-i",
    shellescape(public_key),
  }

  if connection.port then
    table.insert(parts, "-p")
    table.insert(parts, shellescape(connection.port))
  end

  table.insert(parts, shellescape(target))

  local terminal = require("kvim.core.terminal")

  terminal.open_command(table.concat(parts, " "), {
    position = "bottom",
    name = "KVIM SSH Copy ID",
    listed = false,
  })
end

function M.test_connection(connection)
  if not connection or connection.type ~= "ssh" then
    vim.notify("KVIM Connections: selected connection is not SSH", vim.log.levels.ERROR)
    return
  end

  local ssh = require("kvim.modules.connections.ssh")
  local cmd, err = ssh.build_command(connection)

  if not cmd then
    vim.notify("KVIM Connections: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local terminal = require("kvim.core.terminal")

  terminal.open_command(cmd .. " exit", {
    position = "bottom",
    name = "KVIM SSH Test",
    listed = false,
  })
end

return M
