-- lua/kvim/modules/connections/picker.lua

local M = {}

local ssh = require("kvim.modules.connections.ssh")
local serial = require("kvim.modules.connections.serial")

local function display_connection(connection)
  if connection.type == "ssh" then
    return ssh.display(connection)
  end

  if connection.type == "serial" then
    return serial.display(connection)
  end

  return string.format(
    "[%s] %s",
    string.upper(connection.type or "unknown"),
    connection.name or "Unnamed connection"
  )
end

function M.select(connections, callback)
  if not connections or vim.tbl_isempty(connections) then
    vim.notify("KVIM Connections: no connections available", vim.log.levels.WARN)
    return
  end

  vim.ui.select(connections, {
    prompt = "KVIM Connections",
    format_item = display_connection,
  }, function(choice)
    if not choice then
      return
    end

    callback(choice)
  end)
end

return M
