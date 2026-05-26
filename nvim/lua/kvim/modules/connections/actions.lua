-- lua/kvim/modules/connections/actions.lua

local M = {}

local ssh = require("kvim.modules.connections.ssh")
local state = require("kvim.modules.connections.state")
local config = require("kvim.modules.connections.config")
local picker = require("kvim.modules.connections.picker")
local serial = require("kvim.modules.connections.serial")
local ssh_keys = require("kvim.modules.connections.ssh_keys")

local function get_config_file(opts)
  return config.get_config_file(opts or {})
end

local function load_connections_for_edit(opts)
  local config_file = get_config_file(opts)
  if vim.fn.filereadable(config_file) ~= 1 then
    return {}
  end

  local ok, connections = pcall(dofile, config_file)
  if not ok or type(connections) ~= "table" then
    vim.notify("KVIM Connections: failed to parse config file", vim.log.levels.ERROR)
    return nil, "failed to parse config file"
  end

  return connections
end

local function save_connections(connections, opts)
  local config_file = get_config_file(opts)
  local parent = vim.fn.fnamemodify(config_file, ":h")
  vim.fn.mkdir(parent, "p")

  local content = "return " .. vim.inspect(connections) .. "\n"
  local ok, err = pcall(vim.fn.writefile, vim.split(content, "\n", { plain = true }), config_file)
  if not ok then
    return nil, err
  end

  return true
end

local function ensure_ssh_connection_defaults(connection)
  if type(connection) ~= "table" or connection.type ~= "ssh" then
    return false
  end

  local changed = false

  if not connection.identity_file or connection.identity_file == "" then
    connection.identity_file = ssh_keys.key_path_for_connection(connection)
    changed = true
  end

  if type(connection.options) ~= "table" then
    connection.options = {}
    changed = true
  end

  if connection.options.IdentitiesOnly == nil then
    connection.options.IdentitiesOnly = "yes"
    changed = true
  end

  return changed
end

local function connection_label(connection)
  if not connection then
    return ""
  end

  local suffix = ""
  if connection.type == "ssh" then
    suffix = "@" .. tostring(connection.host or "unknown")
  elseif connection.type == "serial" then
    suffix = "@" .. tostring(connection.device or "unknown")
  end

  return string.format("[%s] %s%s", tostring(connection.type or "?"), tostring(connection.name or "unnamed"), suffix)
end

local function prompt_non_empty(prompt)
  local value = vim.fn.input(prompt)
  if type(value) ~= "string" or value == "" then
    return nil
  end

  return value
end

local function cleanup_managed_identity_files(identity_file)
  if type(identity_file) ~= "string" or identity_file == "" then
    return false, "no identity_file"
  end

  local base = vim.fn.fnamemodify(identity_file, ":t")
  if not base:match("^kvim_") then
    return false, "identity_file is not kvim_*"
  end

  local targets = {
    identity_file,
    identity_file .. ".pub",
  }

  local deleted = {}
  for _, path in ipairs(targets) do
    if vim.fn.filereadable(path) == 1 then
      local ok, result = pcall(vim.fn.delete, path)
      if ok and result == 0 then
        table.insert(deleted, path)
      end
    end
  end

  return #deleted > 0, deleted
end

local function executable_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function open_connection_terminal(connection, command, opts)
  opts = opts or {}
  local terminal = require("kvim.core.terminal")

  local split = true
  local listed = false

  local ok_ws_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
  if ok_ws_state then
    local current_tabnr = vim.fn.tabpagenr()
    local role = ws_state.get_tab_role(current_tabnr)
    if role == "term" then
      split = false
      listed = true
    end
  end

  local name = "KVIM " .. string.upper(connection.type or "connection")

  if connection.name then
    name = name .. " [" .. connection.name .. "]"
  end

  terminal.open_command(command, {
    position = connection.position or "bottom",
    name = name,
    listed = listed,
    split = split,
    startinsert = opts.startinsert ~= false,
  })

  local bufnr = vim.api.nvim_get_current_buf()
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_command", command)
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_cwd", vim.fn.getcwd())
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_type", connection.type or "shell")
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_position", connection.position or "bottom")

  if connection.name and connection.name ~= "" then
    pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_connection", connection.name)
  end
end

local function validate_executable(connection)
  if connection.type == "ssh" then
    if not executable_exists("ssh") then
      return false, "ssh executable not found"
    end

    return true
  end

  if connection.type == "serial" then
    local command = connection.command or "picocom"

    if not executable_exists(command) then
      return false, command .. " executable not found"
    end

    return true
  end

  return false, "unsupported connection type: " .. tostring(connection.type)
end

function M.open_connection(connection, opts)
  opts = opts or {}
  local ok_exec, exec_err = validate_executable(connection)

  if not ok_exec then
    vim.notify("KVIM Connections: " .. exec_err, vim.log.levels.ERROR)
    return
  end

  local command
  local err

  if connection.type == "ssh" then
    command, err = ssh.build_command(connection)
  elseif connection.type == "serial" then
    command, err = serial.build_command(connection)
  else
    err = "unsupported connection type: " .. tostring(connection.type)
  end

  if not command then
    vim.notify("KVIM Connections: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  state.set_active_connection(connection)
  open_connection_terminal(connection, command, opts)
end

function M.open_all_picker(opts)
  opts = opts or {}

  local connections = config.load(opts)

  picker.select(connections, function(connection)
    M.open_connection(connection)
  end)
end

function M.open_ssh_picker(opts)
  opts = opts or {}

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    M.open_connection(connection)
  end)
end

function M.open_serial_picker(opts)
  opts = opts or {}

  local connections = config.load(opts)
  local serial_connections = config.filter_by_type(connections, "serial")

  picker.select(serial_connections, function(connection)
    M.open_connection(connection)
  end)
end

function M.reload_config(opts)
  opts = opts or {}

  local connections = config.load(opts)

  vim.notify(
    "KVIM Connections: loaded " .. tostring(#connections) .. " connection(s)",
    vim.log.levels.INFO
  )
end

function M.list_connections(opts)
  opts = opts or {}

  local connections = config.load(opts)
  if not connections or vim.tbl_isempty(connections) then
    vim.notify("KVIM Connections: no connections configured", vim.log.levels.INFO)
    return {}
  end

  local lines = {}
  for _, connection in ipairs(connections) do
    local ctype = tostring(connection.type or "unknown")
    local name = tostring(connection.name or "unnamed")
    table.insert(lines, string.format("- [%s] %s", ctype, name))
  end

  vim.notify("KVIM Connections:\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
  return connections
end

function M.generate_ssh_key()
  ssh_keys.generate_key()
end

function M.generate_ssh_key_picker(opts)
  opts = opts or {}

  local ssh_keys = require("kvim.modules.connections.ssh_keys")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    ssh_keys.generate_key_for_connection(connection)
  end)
end

function M.install_ssh_key_picker(opts)
  opts = opts or {}

  local ssh_keys = require("kvim.modules.connections.ssh_keys")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    local changed = ensure_ssh_connection_defaults(connection)

    if changed then
      local ok_save, save_err = save_connections(connections, opts)
      if not ok_save then
        vim.notify("KVIM Connections: failed to save config: " .. tostring(save_err), vim.log.levels.ERROR)
      else
        vim.notify(
          "KVIM Connections: updated SSH defaults (identity_file, IdentitiesOnly) for " .. tostring(connection.name or connection.host),
          vim.log.levels.INFO
        )
      end
    end

    ssh_keys.install_key(connection)
  end)
end

function M.setup_ssh_key_picker(opts)
  opts = opts or {}

  local ssh_keys = require("kvim.modules.connections.ssh_keys")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    local changed = ensure_ssh_connection_defaults(connection)

    if changed then
      local ok_save, save_err = save_connections(connections, opts)
      if not ok_save then
        vim.notify("KVIM Connections: failed to save config: " .. tostring(save_err), vim.log.levels.ERROR)
        return
      end

      vim.notify(
        "KVIM Connections: updated SSH defaults (identity_file, IdentitiesOnly) for " .. tostring(connection.name or connection.host),
        vim.log.levels.INFO
      )
    end

    local ok_key, key_status_or_err = ssh_keys.ensure_local_key_for_connection(connection)
    if not ok_key then
      vim.notify("KVIM Connections: failed to ensure local key: " .. tostring(key_status_or_err), vim.log.levels.ERROR)
      return
    end

    if key_status_or_err == "generated" then
      vim.notify("KVIM Connections: SSH key generated for " .. tostring(connection.name or connection.host), vim.log.levels.INFO)
    end

    ssh_keys.install_key(connection)
  end)
end

function M.test_ssh_connection_picker(opts)
  opts = opts or {}

  local ssh_keys = require("kvim.modules.connections.ssh_keys")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  picker.select(ssh_connections, function(connection)
    ssh_keys.test_connection(connection)
  end)
end

function M.set_active_connection_picker(opts)
  opts = opts or {}

  local state = require("kvim.modules.connections.state")

  local connections = config.load(opts)

  if not connections or vim.tbl_isempty(connections) then
    vim.notify("KVIM Connections: no connections configured", vim.log.levels.WARN)
    return
  end

  picker.select(connections, function(connection)
    if not connection then
      vim.notify("KVIM Connections: active connection selection cancelled", vim.log.levels.WARN)
      return
    end

    state.set_active_connection(connection)
  end)
end

function M.set_active_ssh_connection_picker(opts)
  opts = opts or {}

  local state = require("kvim.modules.connections.state")

  local connections = config.load(opts)
  local ssh_connections = config.filter_by_type(connections, "ssh")

  if not ssh_connections or vim.tbl_isempty(ssh_connections) then
    vim.notify("KVIM Connections: no SSH connections configured", vim.log.levels.WARN)
    return
  end

  picker.select(ssh_connections, function(connection)
    if not connection then
      vim.notify("KVIM Connections: active SSH connection selection cancelled", vim.log.levels.WARN)
      return
    end

    state.set_active_connection(connection)
  end)
end

function M.add_connection(opts)
  opts = opts or {}

  local connections, err = load_connections_for_edit(opts)
  if not connections then
    return nil, err
  end

  local types = { "ssh", "serial" }
  vim.ui.select(types, { prompt = "Tipo de conexión" }, function(choice)
    if not choice then
      return
    end

    local name = prompt_non_empty("Name: ")
    if not name then
      vim.notify("KVIM Connections: name is required", vim.log.levels.ERROR)
      return
    end

    for _, existing in ipairs(connections) do
      if existing.name == name then
        vim.notify("KVIM Connections: connection name already exists", vim.log.levels.ERROR)
        return
      end
    end

    local new_connection = {
      type = choice,
      name = name,
    }

    if choice == "ssh" then
      local host = prompt_non_empty("Host/IP: ")
      if not host then
        vim.notify("KVIM Connections: host is required for SSH", vim.log.levels.ERROR)
        return
      end

      new_connection.host = host
      new_connection.user = vim.fn.input("User (optional): ")

      local port = vim.fn.input("Port (default 22): ")
      if port ~= "" then
        new_connection.port = tonumber(port) or port
      end

      local identity = vim.fn.input("Identity file (optional): ")
      if identity ~= "" then
        new_connection.identity_file = vim.fn.expand(identity)
      end

      local remote_root = vim.fn.input("Remote root (optional): ")
      if remote_root ~= "" then
        new_connection.remote_root = remote_root
      end
    else
      local device = prompt_non_empty("Device/COM (e.g. /dev/ttyUSB0): ")
      if not device then
        vim.notify("KVIM Connections: device is required for serial", vim.log.levels.ERROR)
        return
      end

      new_connection.device = device
      local baudrate = vim.fn.input("Baudrate (default 115200): ")
      if baudrate ~= "" then
        new_connection.baudrate = tonumber(baudrate) or baudrate
      else
        new_connection.baudrate = 115200
      end

      local command = vim.fn.input("Serial command (default picocom): ")
      new_connection.command = (command ~= "" and command) or "picocom"
    end

    table.insert(connections, new_connection)
    local ok_save, save_err = save_connections(connections, opts)
    if not ok_save then
      vim.notify("KVIM Connections: failed to save config: " .. tostring(save_err), vim.log.levels.ERROR)
      return
    end

    vim.notify("KVIM Connections: connection added: " .. connection_label(new_connection), vim.log.levels.INFO)
    M.reload_config(opts)
  end)

  return true
end

function M.delete_connection(opts, name)
  opts = opts or {}

  local connections, err = load_connections_for_edit(opts)
  if not connections then
    return nil, err
  end

  if #connections == 0 then
    vim.notify("KVIM Connections: no connections configured", vim.log.levels.WARN)
    return nil, "no connections"
  end

  local function delete_by_name(target_name)
    local index = nil
    local connection = nil
    for i, item in ipairs(connections) do
      if item.name == target_name then
        index = i
        connection = item
        break
      end
    end

    if not index then
      vim.notify("KVIM Connections: connection not found: " .. tostring(target_name), vim.log.levels.ERROR)
      return
    end

    local confirm = vim.fn.input("Delete " .. connection_label(connection) .. "? (y/N): ")
    if confirm:lower() ~= "y" then
      vim.notify("KVIM Connections: delete cancelled", vim.log.levels.WARN)
      return
    end

    table.remove(connections, index)
    local ok_save, save_err = save_connections(connections, opts)
    if not ok_save then
      vim.notify("KVIM Connections: failed to save config: " .. tostring(save_err), vim.log.levels.ERROR)
      return
    end

    local active = state.get_active_connection()
    if active and active.name == connection.name then
      state.clear_active_connection()
    end

    local cleaned, cleanup_result = cleanup_managed_identity_files(connection.identity_file)
    if cleaned then
      vim.notify(
        "KVIM Connections: deleted key files: " .. table.concat(cleanup_result, ", "),
        vim.log.levels.INFO
      )
    elseif cleanup_result == "identity_file is not kvim_*" then
      vim.notify("KVIM Connections: key cleanup skipped (non-kvim identity_file)", vim.log.levels.INFO)
    end

    vim.notify("KVIM Connections: deleted " .. connection_label(connection), vim.log.levels.INFO)
    M.reload_config(opts)
  end

  if type(name) == "string" and name ~= "" then
    delete_by_name(name)
    return true
  end

  local labels = {}
  local by_label = {}
  for _, connection in ipairs(connections) do
    local label = connection_label(connection)
    table.insert(labels, label)
    by_label[label] = connection.name
  end

  vim.ui.select(labels, { prompt = "Connection to delete" }, function(choice)
    if not choice then
      return
    end

    delete_by_name(by_label[choice])
  end)

  return true
end

return M
