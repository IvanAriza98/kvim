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

local function read_public_key(path)
  local lines = vim.fn.readfile(path)
  if type(lines) ~= "table" or #lines == 0 then
    return nil, "public key is empty"
  end

  local content = table.concat(lines, "\n")
  content = content:gsub("%s+$", "")
  if content == "" then
    return nil, "public key is empty"
  end

  return content
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

function M.ensure_local_key_for_connection(connection)
  if not connection or connection.type ~= "ssh" then
    return false, "selected connection is not SSH"
  end

  if not executable_exists("ssh-keygen") then
    return false, "ssh-keygen not found"
  end

  local key_path = M.key_path_for_connection(connection)
  local public_key = key_path .. ".pub"

  if M.key_exists(key_path) and M.public_key_exists(key_path) then
    return true, "existing", key_path
  end

  vim.fn.mkdir(vim.fn.fnamemodify(key_path, ":h"), "p")

  local comment = "kvim-" .. slugify(connection.name or connection.host)
  local output = vim.fn.system({
    "ssh-keygen",
    "-t", "ed25519",
    "-f", key_path,
    "-C", comment,
    "-N", "",
  })

  if vim.v.shell_error ~= 0 then
    return false, tostring(output)
  end

  if vim.fn.filereadable(public_key) ~= 1 then
    return false, "public key not generated"
  end

  return true, "generated", key_path
end

function M.install_key(connection)
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

  local terminal = require("kvim.core.terminal")

  if executable_exists("ssh-copy-id") then
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

    local verify_parts = { "ssh" }
    if connection.port then
      table.insert(verify_parts, "-p")
      table.insert(verify_parts, shellescape(connection.port))
    end
    if connection.identity_file and connection.identity_file ~= "" then
      table.insert(verify_parts, "-i")
      table.insert(verify_parts, shellescape(expand_path(connection.identity_file)))
    end
    if connection.options and type(connection.options) == "table" then
      for key, value in pairs(connection.options) do
        table.insert(verify_parts, "-o")
        table.insert(verify_parts, shellescape(key .. "=" .. tostring(value)))
      end
    end
    table.insert(verify_parts, "-o")
    table.insert(verify_parts, shellescape("BatchMode=yes"))
    table.insert(verify_parts, shellescape(target))
    table.insert(verify_parts, shellescape("exit"))

    local cmd = table.concat(parts, " ")
      .. " && echo 'KVIM Connections: verifying passwordless SSH auth...'"
      .. " && " .. table.concat(verify_parts, " ")
      .. " || echo 'KVIM Connections: SSH key installed but passwordless verification failed'"

    terminal.open_command(cmd, {
      position = "bottom",
      name = "KVIM SSH Copy ID",
      listed = false,
    })
    return
  end

  if not executable_exists("ssh") then
    vim.notify("KVIM Connections: neither ssh-copy-id nor ssh are available", vim.log.levels.ERROR)
    return
  end

  local remote_command = table.concat({
    "mkdir -p ~/.ssh",
    "chmod 700 ~/.ssh",
    "touch ~/.ssh/authorized_keys",
    "chmod 600 ~/.ssh/authorized_keys",
    "tmp=$(mktemp)",
    "cat > \"$tmp\"",
    "grep -qxF -f \"$tmp\" ~/.ssh/authorized_keys || cat \"$tmp\" >> ~/.ssh/authorized_keys",
    "rm -f \"$tmp\"",
  }, " && ")

  local ssh_parts = { "ssh" }
  if connection.identity_file and connection.identity_file ~= "" then
    table.insert(ssh_parts, "-i")
    table.insert(ssh_parts, shellescape(expand_path(connection.identity_file)))
  end
  if connection.port then
    table.insert(ssh_parts, "-p")
    table.insert(ssh_parts, shellescape(connection.port))
  end
  if connection.options and type(connection.options) == "table" then
    for key, value in pairs(connection.options) do
      table.insert(ssh_parts, "-o")
      table.insert(ssh_parts, shellescape(key .. "=" .. tostring(value)))
    end
  end
  table.insert(ssh_parts, shellescape(target))
  table.insert(ssh_parts, shellescape(remote_command))

  local verify_parts = { "ssh" }
  if connection.identity_file and connection.identity_file ~= "" then
    table.insert(verify_parts, "-i")
    table.insert(verify_parts, shellescape(expand_path(connection.identity_file)))
  end
  if connection.port then
    table.insert(verify_parts, "-p")
    table.insert(verify_parts, shellescape(connection.port))
  end
  if connection.options and type(connection.options) == "table" then
    for key, value in pairs(connection.options) do
      table.insert(verify_parts, "-o")
      table.insert(verify_parts, shellescape(key .. "=" .. tostring(value)))
    end
  end
  table.insert(verify_parts, "-o")
  table.insert(verify_parts, shellescape("BatchMode=yes"))
  table.insert(verify_parts, shellescape(target))
  table.insert(verify_parts, shellescape("exit"))

  local cat_command = ((vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) and "type") or "cat"

  local parts = {
    cat_command,
    shellescape(public_key),
    "|",
    table.concat(ssh_parts, " "),
    "&&",
    "echo 'KVIM Connections: verifying passwordless SSH auth...'",
    "&&",
    table.concat(verify_parts, " "),
    "||",
    "echo 'KVIM Connections: SSH key installed but passwordless verification failed'",
  }

  terminal.open_command(table.concat(parts, " "), {
    position = "bottom",
    name = "KVIM SSH Install Key",
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
