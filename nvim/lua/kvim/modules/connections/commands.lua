-- lua/kvim/modules/connections/commands.lua

local M = {}

function M.setup(opts)
  opts = opts or {}

  local actions = require("kvim.modules.connections.actions")

  vim.api.nvim_create_user_command("KvimConnections", function()
    actions.open_all_picker(opts)
  end, {
    desc = "Open KVIM connections picker",
  })

  vim.api.nvim_create_user_command("KvimSshConnections", function()
    actions.open_ssh_picker(opts)
  end, {
    desc = "Open KVIM SSH connections picker",
  })

  vim.api.nvim_create_user_command("KvimSerialConnections", function()
    actions.open_serial_picker(opts)
  end, {
    desc = "Open KVIM serial connections picker",
  })

  vim.api.nvim_create_user_command("KvimConnectionsReload", function()
    actions.reload_config(opts)
  end, {
    desc = "Reload KVIM connections config",
  })

  vim.api.nvim_create_user_command("KvimConnectionsGenerateKey", function()
    actions.generate_ssh_key_picker(opts)
  end, {
    desc = "Generate SSH key for selected KVIM connection",
  })

  vim.api.nvim_create_user_command("KvimConnectionsInstallKey", function()
    actions.install_ssh_key_picker(opts)
  end, {
    desc = "Install SSH public key for selected KVIM connection",
  })

  vim.api.nvim_create_user_command("KvimConnectionsTestSsh", function()
    actions.test_ssh_connection_picker(opts)
  end, {
    desc = "Test selected KVIM SSH connection",
  })

  local connections = require("kvim.connections")
  local transfer = require("kvim.modules.connections.transfer")

  local function get_first_connection()
    return connections[1]
  end

  vim.api.nvim_create_user_command("KvimSSHUploadCurrent", function()
    local conn = get_first_connection()

    if not conn then
      vim.notify("KVIM: no SSH connection configured", vim.log.levels.ERROR)
      return
    end

    transfer.upload_current_file(conn)
  end, {
    desc = "Upload current file to SSH connection",
  })

    vim.api.nvim_create_user_command("KvimSSHUploadPath", function(params)
      local conn = get_first_connection()

      if not conn then
        vim.notify("KVIM: no SSH connection configured", vim.log.levels.ERROR)
        return
      end

      local local_path = params.args

      if local_path == "" then
        local_path = vim.fn.input("Local path: ", "", "file")
      end

      if local_path == "" then
        vim.notify("KVIM: upload cancelled", vim.log.levels.WARN)
        return
      end

      transfer.upload_path(conn, local_path)
    end, {
      nargs = "?",
      complete = "file",
      desc = "Upload local file or directory to SSH connection",
    })

    vim.api.nvim_create_user_command("KvimSSHDownloadPath", function(params)
      local conn = get_first_connection()

      if not conn then
        vim.notify("KVIM: no SSH connection configured", vim.log.levels.ERROR)
        return
      end

      local remote_path = params.args

      if remote_path == "" then
        remote_path = vim.fn.input("Remote path: ")
      end

      if remote_path == "" then
        vim.notify("KVIM: download cancelled", vim.log.levels.WARN)
        return
      end

      transfer.download_path(conn, remote_path)
    end, {
      nargs = "?",
      desc = "Download remote file or directory from SSH connection",
    })
end



return M
