-- lua/kvim/modules/connections/state.lua

local M = {}

local active_connection = nil

function M.set_active_connection(conn)
  if not conn then
    vim.notify("KVIM: cannot set nil connection as active", vim.log.levels.ERROR)
    return
  end

  active_connection = conn

  local name = conn.name or "unnamed"
  local host = conn.host or "unknown-host"
  local user = conn.user or "unknown-user"

  vim.notify(
    string.format("KVIM: active connection set to %s (%s@%s)", name, user, host),
    vim.log.levels.INFO
  )
end

function M.get_active_connection()
  return active_connection
end

function M.has_active_connection()
  return active_connection ~= nil
end

function M.clear_active_connection()
  active_connection = nil
  vim.notify("KVIM: active connection cleared", vim.log.levels.INFO)
end

function M.get_active_connection_label()
  if not active_connection then
    return "No active connection"
  end

  local conn = active_connection

  if conn.type == "ssh" then
    return string.format(
      "%s [%s] %s@%s:%s",
      conn.name or "unnamed",
      conn.type or "unknown",
      conn.user or "?",
      conn.host or "?",
      tostring(conn.port or 22)
    )
  end

  if conn.type == "serial" then
    return string.format(
      "%s [%s] %s @ %s",
      conn.name or "unnamed",
      conn.type or "unknown",
      conn.device or "?",
      tostring(conn.baudrate or "?")
    )
  end

  return string.format("%s [%s]", conn.name or "unnamed", conn.type or "unknown")
end

return M
