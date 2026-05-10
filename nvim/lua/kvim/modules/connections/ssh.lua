-- lua/kvim/modules/connections/ssh.lua

local M = {}

local function shellescape(value)
  return vim.fn.shellescape(tostring(value))
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

  if connection.port then
    table.insert(parts, "-p")
    table.insert(parts, shellescape(connection.port))
  end

  if connection.identity_file then
    table.insert(parts, "-i")
    table.insert(parts, shellescape(connection.identity_file))
  end

  if connection.options and type(connection.options) == "table" then
    for key, value in pairs(connection.options) do
      table.insert(parts, "-o")
      table.insert(parts, shellescape(key .. "=" .. tostring(value)))
    end
  end

  local target

  if connection.user and connection.user ~= "" then
    target = connection.user .. "@" .. connection.host
  else
    target = connection.host
  end

  table.insert(parts, shellescape(target))

  return table.concat(parts, " ")
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
