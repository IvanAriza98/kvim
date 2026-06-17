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
  if not config_file or config_file == "" then
    local ok_path, resolved = pcall(require("kvim.modules.connections.config_paths").ensure_user_config)
    if not ok_path then
      vim.notify("KVIM Connections: failed to resolve config file", vim.log.levels.ERROR)
      return nil, "failed to resolve config file"
    end
    config_file = resolved
  end

  local ok, connections = pcall(dofile, config_file)
  if not ok or type(connections) ~= "table" then
    vim.notify("KVIM Connections: failed to parse config file", vim.log.levels.ERROR)
    return nil, "failed to parse config file"
  end

  if type(config.normalize) == "function" then
    return config.normalize(connections)
  end

  return connections
end

local function save_connections(connections, opts)
  local config_file = get_config_file(opts)
  local parent = vim.fn.fnamemodify(config_file, ":h")
  vim.fn.mkdir(parent, "p")

  local content
  if type(config.serialize) == "function" then
    content = config.serialize(connections)
  else
    content = "return " .. vim.inspect(connections) .. "\n"
  end
  local ok, err = pcall(vim.fn.writefile, vim.split(content, "\n", { plain = true }), config_file)
  if not ok then
    return nil, err
  end

  return true
end

local function build_workspace_connection_recipe(connection)
  return {
    name = connection.name,
    type = "ssh",
    connection = connection.name,
    auto_restore = true,
    role = "term",
    position = connection.position or "bottom",
  }
end

local function workspace_has_connection_recipe(workspace, connection_name)
  for _, recipe in ipairs(workspace.terminals or {}) do
    if recipe.type == "ssh" and recipe.connection == connection_name then
      return true
    end
  end

  return false
end

local function attach_connection_to_current_workspace(connection)
  if type(connection) ~= "table" or connection.type ~= "ssh" then
    return nil, "only ssh connections can be attached to workspace"
  end

  local ok_ws_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
  if not ok_ws_state then
    return nil, "workspaces state not available"
  end

  local workspace = ws_state.get_current()
  if not workspace then
    return nil, "no active workspace"
  end

  workspace.terminals = workspace.terminals or {}
  if workspace_has_connection_recipe(workspace, connection.name) then
    vim.notify("KVIM Workspaces: connection already attached to workspace", vim.log.levels.INFO)
    return true
  end

  table.insert(workspace.terminals, build_workspace_connection_recipe(connection))

  local ok_ws_storage, ws_storage = pcall(require, "kvim.modules.workspaces.storage")
  if not ok_ws_storage then
    return nil, "workspaces storage not available"
  end

  local ok_save, save_err = ws_storage.save(workspace)
  if not ok_save then
    return nil, save_err
  end

  ws_state.set_current(workspace)
  vim.notify(
    "KVIM Workspaces: connection attached to workspace: " .. tostring(connection.name),
    vim.log.levels.INFO
  )
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

local function find_connection_by_name(connections, name)
  if type(name) ~= "string" or name == "" then
    return nil, "connection name is required"
  end

  for _, connection in ipairs(connections or {}) do
    if connection.name == name then
      return connection
    end
  end

  return nil, "connection not found: " .. tostring(name)
end

local function command_matches_connection(command, connection)
  if type(command) ~= "string" or command == "" or type(connection) ~= "table" then
    return false
  end

  local target = connection.host
  if connection.user and connection.user ~= "" then
    target = connection.user .. "@" .. connection.host
  end

  if type(target) ~= "string" or target == "" then
    return false
  end

  if not command:find(target, 1, true) then
    return false
  end

  if connection.port then
    local port = tostring(connection.port)
    if not command:find("-p " .. port, 1, true) and not command:find("-p '" .. port .. "'", 1, true) then
      return false
    end
  end

  return true
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

local function remove_connection_recipes_from_workspace(workspace, connection_name)
  if type(workspace) ~= "table" then
    return false, 0
  end

  local terminals = workspace.terminals or {}
  local filtered = {}
  local removed = 0

  for _, recipe in ipairs(terminals) do
    if recipe.type == "ssh" and recipe.connection == connection_name then
      removed = removed + 1
    else
      table.insert(filtered, recipe)
    end
  end

  if removed > 0 then
    workspace.terminals = filtered
    return true, removed
  end

  return false, 0
end

local function remove_connection_from_all_workspaces(connection_name)
  local ok_storage, ws_storage = pcall(require, "kvim.modules.workspaces.storage")
  if not ok_storage then
    return nil, "workspaces storage not available"
  end

  local workspace_names, list_err = ws_storage.list()
  if not workspace_names then
    return nil, list_err
  end

  local updated_workspaces = 0
  local removed_recipes = 0

  local ok_ws_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
  local active_workspace = ok_ws_state and ws_state.get_current() or nil

  for _, workspace_name in ipairs(workspace_names) do
    local workspace, load_err = ws_storage.load(workspace_name)
    if not workspace then
      vim.notify(
        "KVIM Workspaces: failed to load workspace while cleaning connection: " .. tostring(load_err),
        vim.log.levels.WARN
      )
    else
      local changed, removed = remove_connection_recipes_from_workspace(workspace, connection_name)
      if changed then
        local ok_save, save_err = ws_storage.save(workspace)
        if not ok_save then
          vim.notify(
            "KVIM Workspaces: failed to save workspace while cleaning connection: " .. tostring(save_err),
            vim.log.levels.WARN
          )
        else
          updated_workspaces = updated_workspaces + 1
          removed_recipes = removed_recipes + removed

          if active_workspace and active_workspace.name == workspace.name and ok_ws_state then
            ws_state.set_current(workspace)
          end
        end
      end
    end
  end

  return true, {
    updated_workspaces = updated_workspaces,
    removed_recipes = removed_recipes,
  }
end

local function executable_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function apply_connection_buffer_metadata(bufnr, connection, command)
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_command", command)
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_cwd", vim.fn.getcwd())
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_type", connection.type or "shell")
  pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_position", connection.position or "bottom")

  if connection.name and connection.name ~= "" then
    pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_workspace_recipe_connection", connection.name)
    pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_connection_managed", true)
    pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_connection_name", connection.name)
    pcall(vim.api.nvim_buf_set_var, bufnr, "kvim_connection_type", connection.type or "connection")
    state.set_connection_buffer(connection.name, bufnr)
  end
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
  apply_connection_buffer_metadata(bufnr, connection, command)
end

local function get_buffer_buftype(bufnr)
  local ok, buftype = pcall(vim.api.nvim_get_option_value, "buftype", { buf = bufnr })
  if not ok then
    return nil
  end

  return buftype
end

local function get_buffer_var(bufnr, name)
  local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, name)
  if not ok then
    return nil
  end

  return value
end

local function buffer_matches_connection(bufnr, name, connection)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if get_buffer_buftype(bufnr) ~= "terminal" then
    return false
  end

  local connection_name = get_buffer_var(bufnr, "kvim_connection_name")
  local connection_type = get_buffer_var(bufnr, "kvim_connection_type")
  local managed = get_buffer_var(bufnr, "kvim_connection_managed")

  if managed == true and connection_name == name and connection_type == "ssh" then
    return true
  end

  local recipe_connection = get_buffer_var(bufnr, "kvim_workspace_recipe_connection")
  local recipe_type = get_buffer_var(bufnr, "kvim_workspace_recipe_type")

  if recipe_connection == name and recipe_type == "ssh" then
    return true
  end

  local recipe_command = get_buffer_var(bufnr, "kvim_workspace_recipe_command")
  if command_matches_connection(recipe_command, connection) then
    return true
  end

  return false
end

local function find_connection_buffer_by_name(name, connection)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if buffer_matches_connection(bufnr, name, connection) then
      return bufnr
    end
  end

  return nil
end

local function focus_connection_buffer(bufnr)
  local winids = vim.fn.win_findbuf(bufnr)
  if type(winids) == "table" and #winids > 0 then
    vim.api.nvim_set_current_win(winids[1])
    return true
  end

  vim.api.nvim_set_current_buf(bufnr)
  return true
end

local function reopen_connection_in_current_window(connection, command, opts)
  opts = opts or {}
  local terminal = require("kvim.core.terminal")

  local listed = false
  local ok_ws_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
  if ok_ws_state then
    local current_tabnr = vim.fn.tabpagenr()
    local role = ws_state.get_tab_role(current_tabnr)
    if role == "term" then
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
    split = false,
    startinsert = opts.startinsert ~= false,
  })

  local new_bufnr = vim.api.nvim_get_current_buf()
  apply_connection_buffer_metadata(new_bufnr, connection, command)
  return new_bufnr
end

local function cleanup_replaced_terminal_buffer(old_bufnr, new_bufnr)
  if type(old_bufnr) ~= "number" or old_bufnr == new_bufnr then
    return
  end

  if not vim.api.nvim_buf_is_valid(old_bufnr) then
    return
  end

  pcall(function()
    vim.bo[old_bufnr].buflisted = false
    vim.bo[old_bufnr].bufhidden = "wipe"
  end)

  local winids = vim.fn.win_findbuf(old_bufnr)
  if type(winids) == "table" and #winids == 0 then
    pcall(vim.api.nvim_buf_delete, old_bufnr, { force = true })
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

function M.reconnect_connection(opts, name)
  opts = opts or {}

  if type(name) ~= "string" or name == "" then
    vim.notify("KVIM Connections: connection name is required", vim.log.levels.ERROR)
    return nil, "connection name is required"
  end

  local connections = config.load(opts)
  local connection, connection_err = find_connection_by_name(connections, name)
  if not connection then
    vim.notify("KVIM Connections: " .. tostring(connection_err), vim.log.levels.ERROR)
    return nil, connection_err
  end

  if connection.type ~= "ssh" then
    local err = "connection is not ssh: " .. tostring(name)
    vim.notify("KVIM Connections: " .. err, vim.log.levels.ERROR)
    return nil, err
  end

  local bufnr = state.get_connection_buffer(name)
  if not bufnr then
    bufnr = find_connection_buffer_by_name(name, connection)
    if bufnr then
      state.set_connection_buffer(name, bufnr)
    end
  end

  if not bufnr then
    local err = "terminal buffer not found: " .. tostring(name)
    vim.notify("KVIM Connections: " .. err, vim.log.levels.ERROR)
    return nil, err
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    state.clear_connection_buffer(name)
    local err = "terminal buffer is no longer valid: " .. tostring(name)
    vim.notify("KVIM Connections: " .. err, vim.log.levels.ERROR)
    return nil, err
  end

  local buftype = get_buffer_buftype(bufnr)
  if buftype ~= "terminal" then
    local err = "terminal buffer is no longer valid: " .. tostring(name)
    vim.notify("KVIM Connections: " .. err, vim.log.levels.ERROR)
    return nil, err
  end

  local command, command_err = ssh.build_command(connection)
  if not command then
    local err = "failed to reconnect SSH connection: " .. tostring(command_err)
    vim.notify("KVIM Connections: " .. err, vim.log.levels.ERROR)
    return nil, err
  end

  local ok_focus, focus_err = pcall(focus_connection_buffer, bufnr)
  if not ok_focus then
    local err = "failed to reconnect SSH connection: " .. tostring(focus_err)
    vim.notify("KVIM Connections: " .. err, vim.log.levels.ERROR)
    return nil, err
  end

  local old_bufnr = bufnr

  local ok_reopen, reopen_result = pcall(reopen_connection_in_current_window, connection, command, {
    startinsert = true,
  })
  if not ok_reopen then
    local err = "failed to reconnect SSH connection: " .. tostring(reopen_result)
    vim.notify("KVIM Connections: " .. err, vim.log.levels.ERROR)
    return nil, err
  end

  cleanup_replaced_terminal_buffer(old_bufnr, reopen_result)

  state.set_active_connection(connection)
  vim.notify("KVIM Connections: reconnected SSH connection: " .. tostring(name), vim.log.levels.INFO)
  return true
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

    if new_connection.type == "ssh" then
      local ok_ws_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
      local workspace = ok_ws_state and ws_state.get_current() or nil
      if workspace then
        local attach = vim.fn.input("Add this SSH connection to current workspace? (y/N): ")
        if type(attach) == "string" and attach:lower() == "y" then
          local _, attach_err = attach_connection_to_current_workspace(new_connection)
          if attach_err and attach_err ~= "no active workspace" then
            vim.notify("KVIM Workspaces: failed to attach connection: " .. tostring(attach_err), vim.log.levels.ERROR)
          end
        end
      end
    end

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

    if connection.type == "ssh" then
      local ok_cleanup_ws, cleanup_ws_result = remove_connection_from_all_workspaces(connection.name)
      if not ok_cleanup_ws then
        vim.notify(
          "KVIM Workspaces: failed to clean connection references: " .. tostring(cleanup_ws_result),
          vim.log.levels.WARN
        )
      elseif cleanup_ws_result.removed_recipes > 0 then
        vim.notify(
          "KVIM Workspaces: removed connection '" .. tostring(connection.name) .. "' from "
            .. tostring(cleanup_ws_result.updated_workspaces) .. " workspace(s), "
            .. tostring(cleanup_ws_result.removed_recipes) .. " recipe(s)",
          vim.log.levels.INFO
        )
      end
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
