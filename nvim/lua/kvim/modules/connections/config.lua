-- lua/kvim/modules/connections/config.lua

local M = {}

local function file_exists(path)
  return path and vim.fn.filereadable(path) == 1
end

function M.default_config_file()
  return vim.fn.stdpath("config") .. "/lua/kvim/connections.lua"
end

function M.get_config_file(opts)
  opts = opts or {}
  return opts.config_file or M.default_config_file()
end

function M.load(opts)
  opts = opts or {}

  local config_file = M.get_config_file(opts)

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
      "KVIM Connections: failed to load config: " .. tostring(connections),
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

  return connections
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
