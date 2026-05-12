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

  vim.api.nvim_create_user_command("KvimSSHUploadCurrent", function()
    local conn = connections[1]

    if not conn then
      vim.notify("KVIM: no SSH connection configured", vim.log.levels.ERROR)
      return
    end

    transfer.upload_current_file(conn)
  end, {})

  vim.api.nvim_create_user_command("KvimSSHDownloadFile", function(params)
    local conn = connections[1]

    if not conn then
      vim.notify("KVIM: no SSH connection configured", vim.log.levels.ERROR)
      return
    end

    local remote_file = params.args

    if remote_file == "" then
      remote_file = vim.fn.input("Remote file: ")
    end

    transfer.download_file(conn, remote_file)
  end, {
    nargs = "?",
    desc = "Download remote file from selected KVIM SSH connection",
  })
end



return M
