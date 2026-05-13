-- lua/kvim/modules/connections/transfer.lua

local M = {}

local function build_ssh_target(conn, remote_path)
  return string.format("%s@%s:%s", conn.user, conn.host, remote_path)
end

local function add_scp_common_args(cmd, conn)
  if conn.port then
    table.insert(cmd, "-P")
    table.insert(cmd, tostring(conn.port))
  end

  if conn.identity_file then
    table.insert(cmd, "-i")
    table.insert(cmd, vim.fn.expand(conn.identity_file))
  end
end

local function normalize_local_path(path)
  return vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/$", "")
end

local function normalize_remote_root(path)
  return path:gsub("/$", "")
end

local function get_transfer_config(conn)
  return conn.transfer or {}
end

local function build_scp_upload_command(conn, local_path, remote_path, recursive)
  local cmd = { "scp" }

  add_scp_common_args(cmd, conn)

  if recursive then
    table.insert(cmd, "-r")
  end

  table.insert(cmd, local_path)
  table.insert(cmd, build_ssh_target(conn, remote_path))

  return cmd
end

local function build_scp_download_command(conn, remote_path, local_path, recursive)
  local cmd = { "scp" }

  add_scp_common_args(cmd, conn)

  if recursive then
    table.insert(cmd, "-r")
  end

  table.insert(cmd, build_ssh_target(conn, remote_path))
  table.insert(cmd, local_path)

  return cmd
end

local function run_command(cmd, success_message, error_prefix)
  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        vim.notify(success_message, vim.log.levels.INFO)
      else
        vim.notify(error_prefix .. ":\n" .. (result.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.upload_path(conn, local_path)
  if not conn then
    vim.notify("KVIM: upload_path requires a connection", vim.log.levels.ERROR)
    return
  end

  if not local_path or local_path == "" then
    vim.notify("KVIM: local path is required", vim.log.levels.ERROR)
    return
  end

  local transfer = get_transfer_config(conn)
  local remote_root = transfer.remote_root or conn.remote_root

  if not remote_root then
    vim.notify("KVIM: transfer.remote_root is not configured", vim.log.levels.ERROR)
    return
  end

  local expanded_local_path = normalize_local_path(local_path)
  local stat = vim.loop.fs_stat(expanded_local_path)

  if not stat then
    vim.notify("KVIM: local path does not exist: " .. expanded_local_path, vim.log.levels.ERROR)
    return
  end

  local recursive = stat.type == "directory"
  local name = vim.fn.fnamemodify(expanded_local_path, ":t")
  local remote_path = normalize_remote_root(remote_root) .. "/" .. name

  local cmd = build_scp_upload_command(conn, expanded_local_path, remote_path, recursive)

  run_command(
    cmd,
    "KVIM: uploaded " .. expanded_local_path .. " -> " .. remote_path,
    "KVIM upload failed"
  )
end

function M.upload_current_file(conn)
  local local_path = vim.api.nvim_buf_get_name(0)

  if local_path == "" then
    vim.notify("KVIM: current buffer has no file path", vim.log.levels.WARN)
    return
  end

  M.upload_path(conn, local_path)
end

function M.download_path(conn, remote_path)
  if not conn then
    vim.notify("KVIM: download_path requires a connection", vim.log.levels.ERROR)
    return
  end

  if not remote_path or remote_path == "" then
    vim.notify("KVIM: remote path is required", vim.log.levels.ERROR)
    return
  end

  local transfer = get_transfer_config(conn)
  local remote_root = transfer.remote_root or conn.remote_root
  local local_root = transfer.local_root or vim.fn.getcwd()

  if not remote_root then
    vim.notify("KVIM: transfer.remote_root is not configured", vim.log.levels.ERROR)
    return
  end

  local resolved_remote_path = remote_path

  if not remote_path:match("^/") then
    resolved_remote_path = normalize_remote_root(remote_root) .. "/" .. remote_path
  end

  local expanded_local_root = normalize_local_path(local_root)
  local name = vim.fn.fnamemodify(remote_path, ":t")
  local local_path = expanded_local_root .. "/" .. name

  -- Con scp no sabemos de forma local si el remoto es fichero o directorio.
  -- Usamos -r siempre para descargas. Funciona para ficheros y directorios.
  local recursive = true

  local cmd = build_scp_download_command(conn, resolved_remote_path, local_path, recursive)

  run_command(
    cmd,
    "KVIM: downloaded " .. resolved_remote_path .. " -> " .. local_path,
    "KVIM download failed"
  )
end

return M
