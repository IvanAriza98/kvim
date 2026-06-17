-- lua/kvim/modules/connections/config.lua

local M = {}
local paths = require("kvim.modules.connections.config_paths")

local function file_exists(path)
  return path and vim.fn.filereadable(path) == 1
end

function M.default_config_file()
  return paths.user_config_path()
end

function M.get_config_file(opts)
  opts = opts or {}
  return opts.config_file or paths.user_config_path()
end

local function validate_connection(entry)
  if type(entry) ~= "table" then
    return nil, "connection must be a table"
  end

  if type(entry.name) ~= "string" or entry.name == "" then
    return nil, "connection.name is required"
  end

  if type(entry.host) ~= "string" or entry.host == "" then
    return nil, "connection.host is required"
  end

  if type(entry.user) ~= "string" or entry.user == "" then
    return nil, "connection.user is required"
  end

  if entry.port ~= nil and type(entry.port) ~= "number" then
    return nil, "connection.port must be numeric"
  end

  if entry.identity_file ~= nil and type(entry.identity_file) ~= "string" then
    return nil, "connection.identity_file must be a string"
  end

  return entry
end

function M.normalize(raw)
  if type(raw) ~= "table" then
    return {}
  end

  local source = raw.connections
  if source == nil then
    source = raw
  end

  if type(source) ~= "table" then
    return {}
  end

  local result = {}
  for _, entry in ipairs(source) do
    local validated, err = validate_connection(entry)
    if validated then
      table.insert(result, validated)
    else
      vim.notify("KVIM Connections: ignoring invalid connection: " .. tostring(err), vim.log.levels.WARN)
    end
  end

  return result
end

function M.serialize(connections)
  return "return " .. vim.inspect({ connections = connections or {} }) .. "\n"
end

function M.load(opts)
  opts = opts or {}

  local config_file = opts.config_file or paths.ensure_user_config()

  if not config_file then
    vim.notify("KVIM Connections: failed to resolve user config", vim.log.levels.ERROR)
    return {}
  end

  if not file_exists(config_file) then
    vim.notify(
      "KVIM Connections: config file not found: " .. config_file,
      vim.log.levels.WARN
    )

    return {}
  end

  local ok, connections = pcall(dofile, config_file)

  if not ok then
    vim.notify(
      "KVIM Connections: failed to load user config\nFile: " .. config_file .. "\nError: " .. tostring(connections),
      vim.log.levels.ERROR
    )

    return {}
  end

  if type(connections) ~= "table" then
    vim.notify(
      "KVIM Connections: config must return a table",
      vim.log.levels.ERROR
    )

    return {}
  end

  return M.normalize(connections)
end

function M.filter_by_type(connections, connection_type)
  local filtered = {}

  for _, connection in ipairs(connections or {}) do
    if connection.type == connection_type then
      table.insert(filtered, connection)
    end
  end

  return filtered
end

return M
