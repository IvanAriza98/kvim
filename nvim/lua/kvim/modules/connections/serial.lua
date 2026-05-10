-- lua/kvim/modules/connections/serial.lua

local M = {}

local function shellescape(value)
  return vim.fn.shellescape(tostring(value))
end

function M.is_valid(connection)
  if type(connection) ~= "table" then
    return false, "connection must be a table"
  end

  if connection.type ~= "serial" then
    return false, "connection type must be serial"
  end

  if not connection.device or connection.device == "" then
    return false, "serial connection requires device"
  end

  return true
end

function M.build_command(connection)
  local valid, err = M.is_valid(connection)

  if not valid then
    return nil, err
  end

  local command = connection.command or "picocom"
  local baudrate = connection.baudrate or 115200

  if command == "picocom" then
    return table.concat({
      "picocom",
      "-b",
      shellescape(baudrate),
      shellescape(connection.device),
    }, " ")
  end

  if command == "screen" then
    return table.concat({
      "screen",
      shellescape(connection.device),
      shellescape(baudrate),
    }, " ")
  end

  if command == "minicom" then
    return table.concat({
      "minicom",
      "-D",
      shellescape(connection.device),
      "-b",
      shellescape(baudrate),
    }, " ")
  end

  return nil, "unsupported serial command: " .. tostring(command)
end

function M.display(connection)
  return string.format(
    "[SERIAL] %s  %s @ %s",
    connection.name or connection.device,
    connection.device,
    connection.baudrate or 115200
  )
end

return M
