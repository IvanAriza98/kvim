-- lua/kvim/modules/connections/transfer.lua
local M = {}

local function build_ssh_target(conn, remote_path)
  return string.format("%s@%s:%s", conn.user, conn.host, remote_path)
end

local function add_common_scp_args(cmd, conn)
  if conn.port then
    table.insert(cmd, "-P")
    table.insert(cmd, tostring(conn.port))
  end

  if conn.identity_file then
    table.insert(cmd, "-i")
    table.insert(cmd, vim.fn.expand(conn.identity_file))
  end
end

local function build_scp_upload_command(conn, local_path, remote_path)
  local cmd = { "scp" }

  add_common_scp_args(cmd, conn)

  table.insert(cmd, local_path)
  table.insert(cmd, build_ssh_target(conn, remote_path))

  return cmd
end

local function build_scp_download_command(conn, remote_path, local_path)
  local cmd = { "scp" }

  add_common_scp_args(cmd, conn)

  table.insert(cmd, build_ssh_target(conn, remote_path))
  table.insert(cmd, local_path)

  return cmd
end

local function get_transfer_config(conn)
  return conn.transfer or {}
end

local function normalize_dir(path)
  return vim.fn.fnamemodify(vim.fn.expand(path), ":p"):gsub("/$", "")
end

function M.upload_current_file(conn)
  if not conn then
    vim.notify("KVIM: upload_current_file requires a connection", vim.log.levels.ERROR)
    return
  end

  if not conn.user or not conn.host then
    vim.notify("KVIM: invalid SSH connection config", vim.log.levels.ERROR)
    return
  end

  local local_path = vim.api.nvim_buf_get_name(0)

  if local_path == "" then
    vim.notify("KVIM: current buffer has no file path", vim.log.levels.WARN)
    return
  end

  local transfer = get_transfer_config(conn)
  local remote_root = transfer.remote_root or conn.remote_root

  if not remote_root then
    vim.notify("KVIM: transfer.remote_root is not configured", vim.log.levels.ERROR)
    return
  end

  local filename = vim.fn.fnamemodify(local_path, ":t")
  local remote_path = remote_root:gsub("/$", "") .. "/" .. filename

  local cmd = build_scp_upload_command(conn, local_path, remote_path)

  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        vim.notify("KVIM: uploaded " .. filename, vim.log.levels.INFO)
      else
        vim.notify("KVIM upload failed:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.download_file(conn, remote_file)
  if not conn then
    vim.notify("KVIM: download_file requires a connection", vim.log.levels.ERROR)
    return
  end

  if not conn.user or not conn.host then
    vim.notify("KVIM: invalid SSH connection config", vim.log.levels.ERROR)
    return
  end

  if not remote_file or remote_file == "" then
    vim.notify("KVIM: remote file path is required", vim.log.levels.ERROR)
    return
  end

  local transfer = get_transfer_config(conn)

  if not transfer.remote_root then
    vim.notify("KVIM: transfer.remote_root is not configured", vim.log.levels.ERROR)
    return
  end

  if not transfer.local_root then
    vim.notify("KVIM: transfer.local_root is not configured", vim.log.levels.ERROR)
    return
  end

  local remote_root = transfer.remote_root:gsub("/$", "")
  local local_root = normalize_dir(transfer.local_root)

  local remote_path = remote_file

  if not remote_file:match("^/") then
    remote_path = remote_root .. "/" .. remote_file
  end

  local filename = vim.fn.fnamemodify(remote_file, ":t")
  local local_path = local_root .. "/" .. filename

  local cmd = build_scp_download_command(conn, remote_path, local_path)

  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        vim.notify("KVIM: downloaded " .. remote_path .. " -> " .. local_path, vim.log.levels.INFO)
      else
        vim.notify("KVIM download failed:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
